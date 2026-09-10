//
//  TradingModel.swift
//  CMSimulator
//
//  Buying goods abroad and reselling them on a marketplace.
//
//  This scenario exists to answer a question honestly: is importing and
//  reselling actually a business, or is it the thing people sell courses
//  about? The model is built from the real fee stack rather than from the
//  fantasy, because the fee stack is where the fantasy dies.
//
//  A unit that sells for 34 does not earn 34. The marketplace takes a
//  referral cut of every sale, charges a flat fee to pick and ship it,
//  bills storage for every day it sits, and bills *more* once it has sat
//  too long. Some of it comes back as returns, and a return costs the
//  refund and the shipping again. What is left over is the margin, and it
//  is thin - real benchmarks put a good net margin at 15-20%, and more
//  than half of active sellers now earn less year over year as fees and
//  advertising eat the difference.
//
//  Three things kill a run here, all of them true to life:
//    - the cash conversion cycle: money is paid to a factory months
//      before a customer ever pays you
//    - aged stock: storage escalates, and unsold goods eventually have to
//      be dumped below cost
//    - quality: bad goods come back, and the rating they leave behind
//      suppresses every future sale
//

import Foundation

// MARK: - Marketplace terms

/// The platform's cut. Modelled on a real marketplace's published fee
/// structure, with the calendar compressed to a single trading season -
/// the aged-stock cliffs arrive in weeks here rather than months, but
/// they arrive in the same shape and for the same reason.
struct MarketplaceSpec {
    /// Share of the sale price the platform takes. 15% is the common case.
    var referralFeeRate: Double
    /// Flat per-unit charge to pick, pack and ship.
    let fulfilmentFeePerUnit: Double
    /// Storage, per unit per day, while it sits unsold.
    let storagePerUnitPerDay: Double
    /// Days after which stock counts as aged and storage multiplies.
    let agedAfterDays: Double
    let agedStorageMultiplier: Double
    /// Days after which it counts as long-term and multiplies again. This
    /// is the cliff that turns slow stock into a liability.
    let longTermAfterDays: Double
    let longTermStorageMultiplier: Double
    /// Share of sold units that come back, before quality effects.
    var baseReturnRate: Double
    /// Days between a sale and the money actually landing.
    let payoutDelayDays: Double
    /// The price shoppers expect. Pricing above it costs volume.
    var referencePrice: Double
    /// How sharply volume responds to price. Above 1 means undercutting
    /// wins share faster than it loses margin.
    let priceElasticity: Double
    /// Fraction of landed cost recovered when dumping unsold stock at the
    /// end of the season.
    let liquidationRecovery: Double
    /// Ad spend needed per unit of organic demand to stay visible.
    let adCostPerIncrementalUnit: Double

    static let onlineMarketplace = MarketplaceSpec(
        referralFeeRate: 0.15,
        fulfilmentFeePerUnit: 4.50,
        storagePerUnitPerDay: 0.015,
        agedAfterDays: 60,
        agedStorageMultiplier: 3,
        longTermAfterDays: 100,
        longTermStorageMultiplier: 8,
        baseReturnRate: 0.07,
        payoutDelayDays: 14,
        referencePrice: 39,
        priceElasticity: 2.7,
        liquidationRecovery: 0.40,
        adCostPerIncrementalUnit: 3.10
    )
}

// MARK: - Inventory

/// One shipment's worth of goods, tracked separately because what matters
/// about stock is how old it is and what it cost.
struct InventoryLot: Identifiable {
    let id = UUID()
    var units: Double
    let landedCostPerUnit: Double
    let arrivedDay: Double
    /// Return rate this batch carries, set by the supplier's quality.
    let defectRate: Double

    func age(on day: Double) -> Double { max(0, day - arrivedDay) }
}

/// A sale that has happened but has not been paid out yet.
struct Payout: Identifiable {
    let id = UUID()
    let amount: Double
    let dueDay: Double
}

// MARK: - Run state

struct TradingModel {
    let spec: MarketplaceSpec

    fileprivate(set) var lots: [InventoryLot] = []
    fileprivate(set) var pendingPayouts: [Payout] = []

    /// The price the player lists at. The one lever that trades margin
    /// against volume directly.
    var listPrice: Double

    /// Player-set daily advertising spend. Buys visibility, and on a
    /// crowded marketplace visibility is most of the battle.
    var dailyAdSpend: Double = 0

    /// 0...1. Driven by how much comes back. A bad rating suppresses
    /// every future sale, which is why cheap goods are a trap rather than
    /// a saving.
    private(set) var rating: Double = 0.75

    /// True once the first product line is live and selling.
    private(set) var isTrading = false
    private(set) var firstSaleDay: Double?

    private(set) var unitsSold: Double = 0
    private(set) var unitsReturned: Double = 0
    private(set) var unitsLiquidated: Double = 0
    private(set) var grossSales: Double = 0
    private(set) var marketplaceFees: Double = 0
    private(set) var storagePaid: Double = 0
    private(set) var refundsPaid: Double = 0
    private(set) var history: [Double] = []

    private var dayAccumulator: Double = 0

    /// What is being sold. Returns, seasonality and what shoppers expect
    /// to pay all key off it.
    let niche: ProductNiche

    init(spec: MarketplaceSpec, niche: ProductNiche = .homeGoods) {
        self.niche = niche
        // Shoppers price a drill and a t-shirt differently.
        var adjusted = spec
        adjusted.referencePrice = (spec.referencePrice * niche.priceFactor).rounded()
        adjusted.baseReturnRate = spec.baseReturnRate * niche.returnFactor
        self.spec = adjusted
        self.listPrice = adjusted.referencePrice
    }

    // MARK: Derived

    var unitsOnHand: Double { lots.reduce(0) { $0 + $1.units } }
    var inventoryValueAtCost: Double { lots.reduce(0) { $0 + $1.units * $1.landedCostPerUnit } }
    var receivables: Double { pendingPayouts.reduce(0) { $0 + $1.amount } }

    /// Stock old enough to be costing a penalty rate.
    func agedUnits(on day: Double) -> Double {
        lots.filter { $0.age(on: day) >= spec.agedAfterDays }.reduce(0) { $0 + $1.units }
    }

    /// What the platform takes out of one sale before any cost of goods.
    var feesPerUnit: Double {
        listPrice * spec.referralFeeRate + spec.fulfilmentFeePerUnit
    }

    /// What a sale actually leaves you, before storage, ads and returns.
    var netPerUnitBeforeCost: Double { listPrice - feesPerUnit }

    /// Contribution per unit against the average cost of stock on hand.
    /// Negative means every sale makes things worse.
    var contributionPerUnit: Double {
        let avgCost = unitsOnHand > 0 ? inventoryValueAtCost / unitsOnHand : 0
        return netPerUnitBeforeCost - avgCost
    }

    /// Cheaper listings sell faster, dearer ones slower.
    var priceDemandFactor: Double {
        guard listPrice > 0 else { return 0 }
        return pow(spec.referencePrice / listPrice, spec.priceElasticity)
    }

    /// A poor rating does not just embarrass you, it throttles sales.
    var ratingDemandFactor: Double { 0.25 + 0.75 * min(max(rating, 0), 1) }

    // MARK: Ticking

    mutating func beginTrading(onDay day: Double) {
        guard !isTrading else { return }
        isTrading = true
        firstSaleDay = day
    }

    mutating func receive(units: Double, landedCostPerUnit: Double, defectRate: Double, onDay day: Double) {
        guard units > 0 else { return }
        lots.append(InventoryLot(units: units, landedCostPerUnit: landedCostPerUnit,
                                 arrivedDay: day, defectRate: defectRate))
    }

    /// The result of a day's trading, itemised so the player can see
    /// exactly where a thin margin went.
    struct DayResult {
        var sold: Double = 0
        var returned: Double = 0
        var grossSales: Double = 0
        var platformFees: Double = 0
        var refunds: Double = 0
        var storage: Double = 0
        var adSpend: Double = 0
        var costOfGoodsSold: Double = 0
        /// Cash actually landing today from earlier sales.
        var payoutsReceived: Double = 0

        /// What today really made, after everything.
        var contribution: Double {
            grossSales - platformFees - refunds - storage - adSpend - costOfGoodsSold
        }
    }

    mutating func advance(days: Double, demand: Double, currentDay: Double) -> DayResult {
        var result = DayResult()

        // Storage is billed on everything sitting there, at a rate that
        // escalates the longer it has sat. This is what makes buying too
        // much quietly expensive.
        for lot in lots {
            let age = lot.age(on: currentDay)
            var rate = spec.storagePerUnitPerDay
            if age >= spec.longTermAfterDays { rate *= spec.longTermStorageMultiplier }
            else if age >= spec.agedAfterDays { rate *= spec.agedStorageMultiplier }
            result.storage += lot.units * rate * days
        }
        storagePaid += result.storage

        result.adSpend = dailyAdSpend * days

        if isTrading, unitsOnHand > 0 {
            // Advertising buys incremental visibility on top of organic
            // demand; the first units are cheap and it gets dearer.
            let advertisedUnits = spec.adCostPerIncrementalUnit > 0
                ? result.adSpend / spec.adCostPerIncrementalUnit : 0
            let wanted = demand * priceDemandFactor * ratingDemandFactor * days + advertisedUnits
            let sold = min(wanted, unitsOnHand)

            if sold > 0 {
                result.sold = sold
                result.costOfGoodsSold = consume(units: sold)
                result.grossSales = sold * listPrice
                result.platformFees = sold * feesPerUnit

                // Returns come back at a rate set by the goods themselves.
                let returnRate = min(0.6, spec.baseReturnRate + averageDefectRate)
                let returned = sold * returnRate
                result.returned = returned
                // A return costs the refund and the shipping you already paid.
                result.refunds = returned * (listPrice + spec.fulfilmentFeePerUnit)

                unitsSold += sold
                unitsReturned += returned
                grossSales += result.grossSales
                marketplaceFees += result.platformFees
                refundsPaid += result.refunds

                // Money arrives on the platform's schedule, not yours.
                // Queued gross: the fees and refunds are charged as their
                // own costs, so the player can see the whole stack rather
                // than a single netted-off number.
                if result.grossSales > 0 {
                    pendingPayouts.append(Payout(amount: result.grossSales,
                                                 dueDay: currentDay + spec.payoutDelayDays))
                }
                driftRating(towards: 1 - returnRate * 3.6, days: days)
            }
        }

        let due = pendingPayouts.filter { $0.dueDay <= currentDay }
        result.payoutsReceived = due.reduce(0) { $0 + $1.amount }
        pendingPayouts.removeAll { $0.dueDay <= currentDay }

        recordHistory(days: days)
        return result
    }

    /// Sells oldest stock first, and reports what it cost you.
    private mutating func consume(units: Double) -> Double {
        var remaining = units
        var cost = 0.0
        lots.sort { $0.arrivedDay < $1.arrivedDay }
        for i in lots.indices {
            guard remaining > 0 else { break }
            let take = min(lots[i].units, remaining)
            lots[i].units -= take
            cost += take * lots[i].landedCostPerUnit
            remaining -= take
        }
        lots.removeAll { $0.units <= 0.0001 }
        return cost
    }

    var averageDefectRate: Double {
        let total = unitsOnHand
        guard total > 0 else { return 0 }
        return lots.reduce(0) { $0 + $1.units * $1.defectRate } / total
    }

    private mutating func driftRating(towards target: Double, days: Double) {
        let clamped = min(max(target, 0), 1)
        // Ratings fall faster than they recover, as they do in life.
        let speed = clamped < rating ? 0.06 : 0.02
        rating += (clamped - rating) * min(1, speed * days)
    }

    private mutating func recordHistory(days: Double) {
        dayAccumulator += days
        while dayAccumulator >= 1 {
            dayAccumulator -= 1
            history.append(unitsSold)
            if history.count > 200 { history.removeFirst() }
        }
    }

    /// Units shifted over the last fortnight - the number that tells you
    /// whether stock is actually moving.
    var recentDailyVelocity: Double {
        guard history.count >= 14 else { return 0 }
        return (history[history.count - 1] - history[history.count - 14]) / 14
    }

    /// Days of stock left at the current rate. The other half of the
    /// buying decision.
    var daysOfCover: Double? {
        let velocity = recentDailyVelocity
        guard velocity > 0.01 else { return nil }
        return unitsOnHand / velocity
    }

    // MARK: Season close

    /// Whatever is left has to go somewhere. It goes cheap.
    mutating func liquidate() -> (units: Double, recovered: Double, costWritten: Double) {
        let units = unitsOnHand
        let cost = inventoryValueAtCost
        let recovered = cost * spec.liquidationRecovery
        unitsLiquidated = units
        lots.removeAll()
        return (units, recovered, cost)
    }

    /// Any sales still awaiting payout at the close.
    mutating func settleOutstandingPayouts() -> Double {
        let total = receivables
        pendingPayouts.removeAll()
        return total
    }
}

// MARK: - Scenario parameters

/// Everything a brief needs to describe a resale market.
/// Where the goods come from. This is the decision the whole scenario
/// turns on, and it is a geography decision: cheap, far and exposed
/// against dear, near and safe. A tariff move is survivable on domestic
/// cost and fatal on Chinese cost when a whole season is committed.
enum SourceOrigin: String, CaseIterable, Identifiable {
    case chinaWholesale
    case chinaRetail
    case vietnam
    case india
    case domestic

    var id: String { rawValue }

    var name: String {
        switch self {
        case .chinaWholesale: return String(localized: "China — wholesale", comment: "Sourcing origin")
        case .chinaRetail: return String(localized: "China — small lots", comment: "Sourcing origin")
        case .vietnam: return String(localized: "Vietnam", comment: "Sourcing origin")
        case .india: return String(localized: "India", comment: "Sourcing origin")
        case .domestic: return String(localized: "Domestic", comment: "Sourcing origin")
        }
    }

    /// The channel you actually buy through, which is what a trader
    /// recognises before they recognise a country.
    var channel: String {
        switch self {
        case .chinaWholesale: return String(localized: "Alibaba, direct from the factory", comment: "Sourcing channel")
        case .chinaRetail: return String(localized: "AliExpress and Temu-style resellers", comment: "Sourcing channel")
        case .vietnam: return String(localized: "Trading company, factory-backed", comment: "Sourcing channel")
        case .india: return String(localized: "Export agent", comment: "Sourcing channel")
        case .domestic: return String(localized: "Local distributor", comment: "Sourcing channel")
        }
    }

    /// Unit cost against Chinese wholesale at 1.00.
    var costFactor: Double {
        switch self {
        case .chinaWholesale: return 1.00
        case .chinaRetail: return 1.30
        case .vietnam: return 1.10
        case .india: return 1.08
        case .domestic: return 1.95
        }
    }

    var leadTimeDays: Double {
        switch self {
        case .chinaWholesale: return 38
        case .chinaRetail: return 18
        case .vietnam: return 40
        case .india: return 45
        case .domestic: return 7
        }
    }

    /// Smallest order worth placing. Cheap goods come in large lots, which
    /// is how the cash gets locked up.
    var minimumOrder: Double {
        switch self {
        case .chinaWholesale: return 900
        case .chinaRetail: return 0
        case .vietnam: return 500
        case .india: return 500
        case .domestic: return 80
        }
    }

    /// Duty as a share of goods value, before any brokerage.
    var tariffRate: Double {
        switch self {
        case .chinaWholesale: return 0.20
        case .chinaRetail: return 0.16
        case .vietnam: return 0.10
        case .india: return 0.12
        case .domestic: return 0
        }
    }

    /// Extra defects per unit. Buying blind from a reseller costs you in
    /// returns and in rating, not in the purchase price.
    var defectRate: Double {
        switch self {
        case .chinaWholesale: return 0.020
        case .chinaRetail: return 0.075
        case .vietnam: return 0.022
        case .india: return 0.030
        case .domestic: return 0.008
        }
    }

    /// Whether the price moves with the exchange rate.
    var isFXExposed: Bool { self != .domestic }

    var summary: String {
        switch self {
        case .chinaWholesale: return String(localized: "Cheapest unit price there is, and the highest duty. Big minimum orders lock your cash up for weeks.", comment: "Sourcing summary")
        case .chinaRetail: return String(localized: "Buy in any quantity and have it fast. You pay for that in unit price and in what turns up defective.", comment: "Sourcing summary")
        case .vietnam: return String(localized: "A little dearer than China with far less duty exposure. The supplier pool is thinner.", comment: "Sourcing summary")
        case .india: return String(localized: "Competitive on price, slow, and the paperwork goes wrong more often.", comment: "Sourcing summary")
        case .domestic: return String(localized: "No duty, no currency risk, here in a week. You are paying half again for all of that.", comment: "Sourcing summary")
        }
    }
}

/// What you actually sell. Each niche is a different business: apparel
/// returns at triple the rate of tools, electronics carry certification
/// and a dead-stock cliff.
enum ProductNiche: String, CaseIterable, Identifiable {
    case electronics
    case homeGoods
    case apparel
    case tools
    case toys

    var id: String { rawValue }

    var name: String {
        switch self {
        case .electronics: return String(localized: "Consumer electronics", comment: "Product niche")
        case .homeGoods: return String(localized: "Home goods", comment: "Product niche")
        case .apparel: return String(localized: "Apparel", comment: "Product niche")
        case .tools: return String(localized: "Tools & hardware", comment: "Product niche")
        case .toys: return String(localized: "Toys & games", comment: "Product niche")
        }
    }

    /// Multiplier on the marketplace's base return rate.
    var returnFactor: Double {
        switch self {
        case .electronics: return 1.6
        case .homeGoods: return 0.9
        case .apparel: return 3.1
        case .tools: return 0.7
        case .toys: return 1.2
        }
    }

    /// How sharply demand collapses outside the season.
    var seasonalityFactor: Double {
        switch self {
        case .electronics: return 1.3
        case .homeGoods: return 0.8
        case .apparel: return 1.5
        case .tools: return 0.6
        case .toys: return 2.2
        }
    }

    /// What shoppers expect to pay, against the marketplace reference.
    var priceFactor: Double {
        switch self {
        case .electronics: return 1.7
        case .homeGoods: return 0.9
        case .apparel: return 0.8
        case .tools: return 1.2
        case .toys: return 0.7
        }
    }

    /// How fast unsold stock stops being worth anything.
    var obsolescence: String {
        switch self {
        case .electronics: return String(localized: "Last year's model is worth a fraction of this year's.", comment: "Niche obsolescence")
        case .homeGoods: return String(localized: "Holds its value. Slow, dull and forgiving.", comment: "Niche obsolescence")
        case .apparel: return String(localized: "Out of season is out of money, and sizing drives the returns.", comment: "Niche obsolescence")
        case .tools: return String(localized: "Barely dates at all. The safest thing to be left holding.", comment: "Niche obsolescence")
        case .toys: return String(localized: "One season, then it is clearance.", comment: "Niche obsolescence")
        }
    }
}

struct TradeSpec {
    let marketplace: MarketplaceSpec
    /// Day the selling season peaks. Drawn from the run's seed, and not
    /// shown accurately unless Demand planning is staffed.
    let seasonPeakDay: Double
    /// How broad the peak is, in days.
    let seasonWidth: Double
    /// Units a day the market will absorb at the peak, at full range.
    let peakDailyDemand: Double
    /// Units a day outside the season.
    let baselineDailyDemand: Double
    /// Factory price plus freight, before duty and the currency index.
    /// Duty is charged separately now that origin is a decision - folding
    /// it in here once meant every origin paid China's tariff.
    let landedCostPerUnit: Double
    /// Completing this stream is what puts you on sale.
    let tradingStreamID: String
    /// What this operation sells. Drawn from the seed, and it changes the
    /// business substantially - returns, seasonality and what shoppers
    /// will pay are all downstream of it.
    let niche: ProductNiche

    /// Factory price from a given origin, before duty and the currency
    /// index. The origin is the decision; this is its price tag.
    func landedCost(from origin: SourceOrigin) -> Double {
        // A pair of headphones costs more to buy and sells for more than a
        // pair of socks. The niche moves both ends, so it changes the
        // shape of the business without simply handing out margin.
        landedCostPerUnit * origin.costFactor * niche.priceFactor
    }

    /// Duty on a consignment, after whatever a customs broker saves you.
    /// "A great dealer" is exactly this: the difference between a duty
    /// bill you priced for and one that eats the season.
    func duty(on goodsValue: Double, from origin: SourceOrigin, hasBroker: Bool) -> Double {
        goodsValue * origin.tariffRate * (hasBroker ? 0.55 : 1.0)
    }

    /// Demand on a given day at a given range breadth. A bell around the
    /// peak on top of a baseline - the shape every seasonal trade has.
    func demand(on day: Double, breadth: Double) -> Double {
        let z = (day - seasonPeakDay) / seasonWidth
        let seasonal = peakDailyDemand * exp(-0.5 * z * z) * niche.seasonalityFactor
        // A sharply seasonal niche has less to fall back on out of season.
        let floor = baselineDailyDemand / niche.seasonalityFactor
        return (floor + seasonal) * min(1, max(0, breadth))
    }
}

/// What a season actually came to, itemised. The whole point of the
/// scenario is that this breakdown is rarely what people expect.
struct SeasonClose {
    let unitsSold: Double
    let unitsReturned: Double
    let unitsDumped: Double
    let grossSales: Double
    let marketplaceFees: Double
    let refunds: Double
    let storage: Double
    let liquidationRecovered: Double
    let liquidationCost: Double
    let finalRating: Double

    /// What the marketplace took, as a share of everything you sold.
    var feeShareOfSales: Double { grossSales > 0 ? marketplaceFees / grossSales : 0 }
    var returnRate: Double { unitsSold > 0 ? unitsReturned / unitsSold : 0 }
    /// Money lost by buying stock that never sold.
    var deadStockLoss: Double { max(0, liquidationCost - liquidationRecovered) }
}

extension TradingModel {
    /// Stock lost to theft, damage or a container that never arrived.
    mutating func loseStock(fraction: Double) -> Double {
        let share = min(max(fraction, 0), 1)
        var lost = 0.0
        for i in lots.indices {
            let take = lots[i].units * share
            lots[i].units -= take
            lost += take
        }
        lots.removeAll { $0.units <= 0.0001 }
        return lost
    }

    /// A buyer defaulting takes a payout that had already been counted.
    mutating func loseReceivable(fraction: Double) -> Double {
        let share = min(max(fraction, 0), 1)
        let lost = receivables * share
        guard lost > 0 else { return 0 }
        var remaining = lost
        pendingPayouts.sort { $0.dueDay > $1.dueDay }
        var kept: [Payout] = []
        for payout in pendingPayouts {
            if remaining >= payout.amount { remaining -= payout.amount }
            else if remaining > 0 {
                kept.append(Payout(amount: payout.amount - remaining, dueDay: payout.dueDay))
                remaining = 0
            } else { kept.append(payout) }
        }
        pendingPayouts = kept
        return lost
    }
}

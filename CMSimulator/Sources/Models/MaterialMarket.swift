//
//  MaterialMarket.swift
//  CMSimulator
//
//  Acquisitions, rebuilt. The old Procurement booster applied a one-off
//  random multiplier to every package's cost and was otherwise identical
//  to the other five boosters.
//
//  Here materials are physical and late. Work stops when a package runs
//  dry, and the crew standing in the mud is still on full pay - which is
//  what makes ordering ahead a real decision instead of a menu. Prices
//  move on a random walk with occasional shocks, so the player is taking
//  a position, not paying a fixed rate: buy spot and ride it, or pay a
//  premium to lock the index for a while and stop caring.
//

import Foundation

// MARK: - Price index

/// A commodity index that drifts, with occasional supply shocks. Starts
/// at 1.0; every material price in the game is multiplied by it.
struct MaterialMarket {
    private(set) var index: Double = 1.0
    /// Rolling history for the sparkline, one sample per simulated day.
    private(set) var history: [Double] = [1.0]
    /// While > 0, orders price at `lockedIndex` instead of the spot index.
    private(set) var lockDaysRemaining: Double = 0
    private(set) var lockedIndex: Double = 1.0
    /// Days until the current shock decays out. Purely cosmetic - it lets
    /// the UI explain a spike instead of the number just jumping.
    private(set) var shockDaysRemaining: Double = 0
    private(set) var lastShockWasSpike = false

    let volatility: Double
    private var daysAccumulated: Double = 0

    init(volatility: Double) {
        self.volatility = volatility
    }

    var isLocked: Bool { lockDaysRemaining > 0 }
    /// The index an order actually prices at right now.
    var effectiveIndex: Double { isLocked ? lockedIndex : index }

    var trend: Double {
        guard history.count > 5 else { return 0 }
        let recent = history.suffix(6)
        return (recent.last! - recent.first!) / recent.first!
    }

    mutating func advance(days: Double) {
        if lockDaysRemaining > 0 { lockDaysRemaining = max(0, lockDaysRemaining - days) }
        if shockDaysRemaining > 0 { shockDaysRemaining = max(0, shockDaysRemaining - days) }

        // Mean-reverting geometric walk: without the pull back toward 1.0
        // a long run drifts arbitrarily far and the numbers stop reading
        // as prices.
        let reversion = (1.0 - index) * 0.02 * days
        let noise = Double.random(in: -1...1) * volatility * days.squareRoot()
        index = max(0.55, min(2.4, index * (1 + noise) + reversion))

        daysAccumulated += days
        while daysAccumulated >= 1 {
            daysAccumulated -= 1
            history.append(index)
            if history.count > 120 { history.removeFirst() }
        }
    }

    /// A supply shock - fired by events, not by the walk.
    mutating func applyShock(magnitude: Double, isSpike: Bool) {
        index = max(0.55, min(2.4, index * (isSpike ? 1 + magnitude : 1 - magnitude)))
        shockDaysRemaining = 8
        lastShockWasSpike = isSpike
    }

    /// Locks today's index for `days`. The premium is charged by the
    /// caller - this only records the hedge.
    mutating func lockPrice(for days: Double) {
        lockedIndex = index
        lockDaysRemaining = days
    }

    /// What locking costs, as a fraction of the order value it protects.
    /// Rises with volatility: insurance is dearer when the risk is real.
    var lockPremiumRate: Double { 0.03 + volatility * 1.4 }
}

// MARK: - Vendors

/// A supplier's standing offer. Unlike the old one-shot bid, a vendor is
/// a relationship the player keeps using: every order to them prices and
/// delivers by these terms.
struct Vendor: Identifiable {
    let id = UUID()
    let name: String
    let pitch: String
    /// Multiplier on the base material price.
    let priceFactor: Double
    /// Multiplier on the package's base lead time.
    let leadTimeFactor: Double
    /// Chance per order that delivery slips badly.
    let unreliability: Double
    /// Defects introduced per unit of material, added to the crew's own.
    let defectPerUnit: Double

    var reliabilityLabel: String {
        switch unreliability {
        case ..<0.06: return String(localized: "Dependable", comment: "Vendor reliability label")
        case ..<0.16: return String(localized: "Usually on time", comment: "Vendor reliability label")
        default: return String(localized: "Slips often", comment: "Vendor reliability label")
        }
    }
}

/// The kind of firm you are buying from. A surveyor does not sell rebar
/// and a steel stockist does not sell luminaires, so the supplier panel
/// has to be drawn from the trade that actually sells the input.
enum SupplierTrade: String, CaseIterable, Identifiable {
    case surveying
    case structural
    case engineering
    case builders
    case mechanical
    case electrical
    /// Resale stock. The panel depends on where you are buying, not on a
    /// trade - a Shenzhen factory and a local distributor are different
    /// firms selling the same goods.
    case factoryChina
    case resellerChina
    case factoryVietnam
    case factoryIndia
    case distributorDomestic

    var id: String { rawValue }

    /// Localized as one comma-separated list each, same reasoning as the
    /// worker name pools: suppliers should sound like firms the player
    /// would actually ring up for this particular thing.
    var names: [String] {
        switch self {
        case .surveying:
            return NamePool.split(String(localized: "Datum Land Surveys,Trueline Survey Partners,Baseline Site Data,Cardinal Topographic,Meridian Survey Group",
                comment: "Comma-separated pool of surveying and site-investigation firms. Replace with company names that read naturally in your language - do not translate literally."))
        case .structural:
            return NamePool.split(String(localized: "Ironclad Steel & Rebar,Keystone Ready-Mix,Foundry Concrete Supply,Girder & Bar Co.,Bastion Formwork",
                comment: "Comma-separated pool of concrete, steel and formwork suppliers. Replace with company names that read naturally in your language - do not translate literally."))
        case .engineering:
            return NamePool.split(String(localized: "Plumbline Engineering,Axis Technical Consultants,Cornerstone Permitting,Calculus Structural,Meridian Engineering",
                comment: "Comma-separated pool of engineering consultancies and permit expediters. Replace with company names that read naturally in your language - do not translate literally."))
        case .builders:
            return NamePool.split(String(localized: "BuildRight Merchants,Northgate Aggregates,Trowel & Block Co.,Cornerstone Builders Merchants,Apex Masonry Supply",
                comment: "Comma-separated pool of builders merchants selling masonry and finishes. Replace with company names that read naturally in your language - do not translate literally."))
        case .mechanical:
            return NamePool.split(String(localized: "Copperline Plumbing Supply,Hydro Fixtures & Fittings,Ductwork Air Systems,Valve & Flange Supply,Thermal Air Distributors",
                comment: "Comma-separated pool of plumbing and HVAC suppliers. Replace with company names that read naturally in your language - do not translate literally."))
        case .electrical:
            return NamePool.split(String(localized: "Voltway Electrical Supply,Kestrel Cable & Panel,Lumen Lighting Supply,Circuit & Switchgear Co.,Amperage Distributors",
                comment: "Comma-separated pool of electrical and lighting suppliers. Replace with company names that read naturally in your language - do not translate literally."))
        case .factoryChina:
            return NamePool.split(String(localized: "Shenzhen Hongyu Trading,Guangzhou Weilong Industrial,Ningbo Star Manufacturing,Yiwu Everbright Trading,Dongguan Kaisheng Factory",
                comment: "Comma-separated pool of Chinese factory and trading company names. Keep these recognisably Chinese in every language - do not translate or localize them."))
        case .resellerChina:
            return NamePool.split(String(localized: "QuickShip Global Store,Sunrise Direct Store,MegaValue Outlet,FastLane Reseller,TopChoice Direct",
                comment: "Comma-separated pool of online marketplace reseller storefront names. Replace with storefront names that read naturally in your language - do not translate literally."))
        case .factoryVietnam:
            return NamePool.split(String(localized: "Hanoi Phuc Loi Trading,Saigon Minh Anh Export,Da Nang Truong Thinh,Binh Duong Tan Phat,Haiphong Dai Loc Export",
                comment: "Comma-separated pool of Vietnamese exporter names. Keep these recognisably Vietnamese in every language - do not translate or localize them."))
        case .factoryIndia:
            return NamePool.split(String(localized: "Surat Textile Exports,Mumbai Shree Traders,Ludhiana Metalworks Export,Chennai Global Sourcing,Jaipur Handicraft Exports",
                comment: "Comma-separated pool of Indian exporter names. Keep these recognisably Indian in every language - do not translate or localize them."))
        case .distributorDomestic:
            return NamePool.split(String(localized: "Regional Distribution Co.,Nearshore Trade Partners,Domestic Supply Group,Homeland Wholesale,Local Trade Distributors",
                comment: "Comma-separated pool of local, in-country distributor names. Replace with company names that read naturally in your language - do not translate literally."))
        }
    }
}

extension Vendor {

    /// Three standing offers: the classic cheap/balanced/premium spread,
    /// but the axes that matter are lead time and reliability, not just
    /// price. "Lowest bid" is a trap that idles your crews.
    /// The panel for one trade. Stable for the life of a run so the player
    /// deals with the same firms rather than re-rolling terms by reopening
    /// the sheet.
    static func standingPanel(for trade: SupplierTrade) -> [Vendor] {
        let picked = trade.names.shuffled().prefix(3)
        let specs: [(String, Double, Double, Double, Double)] = [
            (String(localized: "Lowest price, slow and patchy", comment: "Vendor pitch"), 0.84, 1.55, 0.24, 0.008),
            (String(localized: "Balanced terms", comment: "Vendor pitch"), 1.00, 1.00, 0.10, 0.003),
            (String(localized: "Premium, fast and dependable", comment: "Vendor pitch"), 1.26, 0.60, 0.03, 0.0005),
        ]
        return zip(picked, specs).map { name, spec in
            Vendor(name: name, pitch: spec.0,
                   priceFactor: spec.1 * Double.random(in: 0.97...1.03),
                   leadTimeFactor: spec.2 * Double.random(in: 0.95...1.05),
                   unreliability: spec.3,
                   defectPerUnit: spec.4)
        }
    }
}

// MARK: - Orders

struct MaterialOrder: Identifiable {
    let id = UUID()
    let packageID: String
    let vendorName: String
    let quantity: Double
    let pricePaid: Double
    /// Simulated day the order lands.
    var arrivalDay: Double
    let orderedDay: Double
    /// Carried through to delivery so vendor quality lands as defects on
    /// the work actually built from this batch.
    let vendorDefectPerUnit: Double
    /// Where a stock consignment was bought. Nil for construction
    /// materials, which have no origin decision attached.
    var origin: SourceOrigin? = nil
    var hasSlipped = false

    func daysOut(from currentDay: Double) -> Double { max(0, arrivalDay - currentDay) }
}

/// Drives the ordering sheet.
struct MaterialOrderRequest: Identifiable {
    let id: String
    let packageTitle: String
    let vendors: [Vendor]
    /// Units still needed to finish the package, net of stock and orders
    /// already in flight - the "order exactly enough" shortcut.
    let suggestedQuantity: Double
    let baseCostPerUnit: Double
    let baseLeadTimeDays: Double
    let marketIndex: Double
    let isLocked: Bool
    /// What this discipline buys, so the order sheet can say "Pipework,
    /// fixtures & ductwork" rather than a generic "Order".
    let inputName: String?
}

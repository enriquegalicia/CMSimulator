//
//  GrowthModel.swift
//  CMSimulator
//
//  Customers, revenue and what the company is worth.
//
//  The first version of the startup scenario did not have this, and that
//  was the whole problem with it: it was the construction engine with the
//  nouns changed. You finished a list of features, money arrived because
//  you had finished a percentage of them, and the company sold for a fixed
//  price decided before you pressed play. Nothing you did changed what it
//  was worth.
//
//  A startup's actual loop is: build something, launch it, acquire
//  customers, keep them, and let recurring revenue close the gap on burn.
//  Traction is what raises money, growth rate is what sets the multiple,
//  and the debt you hid while moving fast is what gets found in diligence.
//  All of that lives here.
//
//  This is scenario-optional. Construction has no customers and never
//  touches it.
//

import Foundation

/// What Discovery turns out to have found. You start not knowing what you
/// are building; the work of Discovery is to establish it. Only then do
/// you learn which of the people you hired were the right ones - which is
/// what makes hiring specialists early a bet rather than a purchase.
enum VentureKind: String, CaseIterable, Identifiable {
    case aiInfrastructure
    case fintech
    case marketplace
    case devTools
    case healthSoftware

    var id: String { rawValue }

    var name: String {
        switch self {
        case .aiInfrastructure: return String(localized: "AI infrastructure", comment: "Startup venture name")
        case .fintech: return String(localized: "Fintech & payments", comment: "Startup venture name")
        case .marketplace: return String(localized: "Consumer marketplace", comment: "Startup venture name")
        case .devTools: return String(localized: "Developer tools", comment: "Startup venture name")
        case .healthSoftware: return String(localized: "Health software", comment: "Startup venture name")
        }
    }

    /// What Discovery tells you, in the founder's own words.
    var finding: String {
        switch self {
        case .aiInfrastructure:
            return String(localized: "The problem is inference cost. You are building infrastructure, and the people who matter are the ones who can measure it.", comment: "Discovery finding")
        case .fintech:
            return String(localized: "The problem is moving money safely. Nothing ships until it is compliant, and that changes who you need.", comment: "Discovery finding")
        case .marketplace:
            return String(localized: "The problem is liquidity, not product. You are building a market, and it lives or dies on how cheaply you can bring people to it.", comment: "Discovery finding")
        case .devTools:
            return String(localized: "The problem is developer time. Adoption will be slow and retention will be excellent, if the thing is genuinely good.", comment: "Discovery finding")
        case .healthSoftware:
            return String(localized: "The problem is clinical trust. Certification sits on the critical path and no amount of engineering moves it.", comment: "Discovery finding")
        }
    }

    /// Roles this venture actually needs. Hire these and they compound;
    /// hire the others and you are paying specialists to be generalists.
    var valuedRoles: Set<WorkerRole> {
        switch self {
        case .aiInfrastructure: return [.engineer, .dataScientist]
        case .fintech: return [.compliance, .engineer]
        case .marketplace: return [.commercial, .operations]
        case .devTools: return [.engineer, .designer]
        case .healthSoftware: return [.compliance, .dataScientist]
        }
    }

    /// Output multiplier for someone the venture needs, and for someone it
    /// does not. A generalist sits between the two either way.
    func fit(for role: WorkerRole) -> Double {
        if role == .generalist { return 0.96 }
        return valuedRoles.contains(role) ? 1.28 : 0.78
    }

    /// What it costs to serve a customer, relative to the base model.
    var costToServeFactor: Double {
        switch self {
        case .aiInfrastructure: return 1.85
        case .fintech: return 1.15
        case .marketplace: return 1.30
        case .devTools: return 0.70
        case .healthSoftware: return 1.00
        }
    }

    /// What an acquirer pays for a peso of revenue here.
    var exitMultipleFactor: Double {
        switch self {
        case .aiInfrastructure: return 1.45
        case .fintech: return 1.15
        case .marketplace: return 0.70
        case .devTools: return 1.05
        case .healthSoftware: return 1.35
        }
    }

    /// How quickly customers leave if the product is weak.
    var churnFactor: Double {
        switch self {
        case .aiInfrastructure: return 1.20
        case .fintech: return 0.75
        case .marketplace: return 1.45
        case .devTools: return 0.65
        case .healthSoftware: return 0.60
        }
    }

    /// Where the money goes before it arrives - shown to the player as the
    /// warning that comes with the finding.
    var hazard: String {
        switch self {
        case .aiInfrastructure: return String(localized: "Compute burn, and a model release that turns you into a feature.", comment: "Venture hazard")
        case .fintech: return String(localized: "Regulatory delay, and fraud losses you did not price.", comment: "Venture hazard")
        case .marketplace: return String(localized: "Acquisition cost rising faster than anyone stays.", comment: "Venture hazard")
        case .devTools: return String(localized: "Everybody tries it, nobody upgrades.", comment: "Venture hazard")
        case .healthSoftware: return String(localized: "Certification slipping past the end of your runway.", comment: "Venture hazard")
        }
    }
}

/// Someone who might put money in, once you have gone and found them.
/// Angels are not a milestone that fires on a threshold - they are a
/// search that costs time you could have spent building.
struct AngelProspect: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let dilution: Double
    /// Days before this offer goes cold.
    var daysOpen: Double
    /// Whether their name pulls the next round in behind them.
    let isMarquee: Bool

    var pricePerPoint: Double { dilution > 0 ? amount / (dilution * 100) : 0 }
}


// MARK: - Parameters

/// The scenario-supplied constants of a market. Kept separate from run
/// state so a brief stays pure data.
struct GrowthSpec {
    /// Monthly revenue per customer at full product breadth.
    let monthlyRevenuePerCustomer: Double
    /// Monthly cost of serving one customer - infrastructure, support.
    /// The gap between this and revenue is the unit economics.
    let monthlyCostToServe: Double
    /// Cost to acquire the first customer. Rises as the market saturates.
    let baseAcquisitionCost: Double
    /// Customers at which acquisition costs roughly double.
    let saturationScale: Double
    /// Customers a day who find you on their own once you are live -
    /// search, word of mouth beyond your own base, being listed anywhere.
    /// Without this the loop never starts: referrals multiply the base you
    /// have, and any multiple of zero is zero.
    let baseDailyInbound: Double
    /// Share of the customer base that refers someone each day, at full
    /// satisfaction. The compounding term - this is what makes an early
    /// launch worth so much more than a late one.
    let dailyReferralRate: Double
    /// Share of customers lost per day with a clean product.
    let baseDailyChurn: Double
    /// Units of tech debt at which churn roughly doubles.
    let churnDebtTolerance: Double
    /// Revenue multiple a flat-growth company sells for.
    let baseExitMultiple: Double
    /// Extra multiple at maximum growth. Growth rate is what actually
    /// decides a software company's price.
    let growthMultipleBonus: Double
    /// What one unit of unresolved tech debt knocks off the sale price.
    let diligenceCostPerDebt: Double

    static let seedStageSaaS = GrowthSpec(
        monthlyRevenuePerCustomer: 600,
        monthlyCostToServe: 120,
        baseAcquisitionCost: 900,
        saturationScale: 1_800,
        baseDailyInbound: 5.0,
        dailyReferralRate: 0.011,
        baseDailyChurn: 0.0022,
        churnDebtTolerance: 30,
        baseExitMultiple: 3.0,
        growthMultipleBonus: 6.0,
        diligenceCostPerDebt: 380_000
    )
}

// MARK: - Run state

struct GrowthModel {
    let spec: GrowthSpec

    /// Nothing can be acquired before the product is in front of anyone.
    /// This is the difference between building a product and having a
    /// business, and it is the single most important gate in the run.
    private(set) var isLaunched = false
    private(set) var launchDay: Double?

    private(set) var customers: Double = 0
    /// Player-set daily spend on acquiring customers.
    var dailyGrowthSpend: Double = 0

    private(set) var totalAcquired: Double = 0
    private(set) var totalChurned: Double = 0
    private(set) var subscriptionRevenue: Double = 0
    /// Rolling window of customer counts, one per day, for the sparkline
    /// and for measuring growth rate.
    private(set) var history: [Double] = []

    private var dayAccumulator: Double = 0

    init(spec: GrowthSpec) {
        self.spec = spec
    }

    // MARK: Derived

    /// How much of the product exists, 0...1. Breadth raises both what a
    /// customer will pay and how fast word of mouth spreads - a thin
    /// product neither retains nor sells itself.
    var productBreadth: Double = 0

    /// What a customer is actually worth per day at the current breadth.
    /// A half-built product cannot charge full price.
    var revenuePerCustomerPerDay: Double {
        spec.monthlyRevenuePerCustomer * (0.45 + 0.55 * productBreadth) / 30
    }

    /// Set when Discovery resolves. Until then the company has generic
    /// economics, because it does not yet know what it is.
    var venture: VentureKind?

    var costToServePerCustomerPerDay: Double {
        spec.monthlyCostToServe / 30 * (venture?.costToServeFactor ?? 1)
    }

    /// Gross margin per customer per day. Negative means every new
    /// customer makes things worse, which is a real and instructive way
    /// for a run to be going wrong.
    var contributionPerCustomerPerDay: Double {
        revenuePerCustomerPerDay - costToServePerCustomerPerDay
    }

    var dailyRevenue: Double { customers * revenuePerCustomerPerDay }
    var dailyCostToServe: Double { customers * costToServePerCustomerPerDay }
    var annualRecurringRevenue: Double { dailyRevenue * 365 }

    /// Acquisition gets harder as the obvious customers get used up.
    var currentAcquisitionCost: Double {
        spec.baseAcquisitionCost * (1 + customers / spec.saturationScale)
    }

    /// 0...1. Unresolved tech debt is what makes customers leave, long
    /// before any acquirer sees it.
    func satisfaction(techDebt: Double) -> Double {
        max(0, 1 - techDebt / (spec.churnDebtTolerance * 2))
    }

    func dailyChurnRate(techDebt: Double) -> Double {
        spec.baseDailyChurn * (1 + techDebt / spec.churnDebtTolerance) * (venture?.churnFactor ?? 1)
    }

    /// Net customer growth over the last fortnight, annualised-ish. Drives
    /// the exit multiple, so it is worth showing the player.
    var growthRate: Double {
        guard history.count >= 14 else { return 0 }
        let now = history[history.count - 1]
        let then = history[history.count - 14]
        guard then > 1 else { return now > 1 ? 1 : 0 }
        return (now - then) / then
    }

    // MARK: Ticking

    mutating func launch(onDay day: Double) {
        guard !isLaunched else { return }
        isLaunched = true
        launchDay = day
    }

    /// Advances the customer base. Returns the revenue earned and the cost
    /// of serving them, so the engine can put both through the ledger.
    mutating func advance(days: Double, techDebt: Double, breadth: Double,
                          currentDay: Double) -> (revenue: Double, costToServe: Double, acquired: Double) {
        productBreadth = min(1, max(0, breadth))
        guard isLaunched else {
            recordHistory(days: days)
            return (0, 0, 0)
        }

        let happiness = satisfaction(techDebt: techDebt)

        // A trickle finds you regardless, which is what gets the loop
        // started; word of mouth then compounds off the base you already
        // have, which is why launching early beats launching polished.
        let inbound = spec.baseDailyInbound * happiness * (0.35 + 0.65 * productBreadth) * days
        let referred = customers * spec.dailyReferralRate * happiness * productBreadth * days
        // Paid acquisition is a straight conversion of money into users,
        // at a price that worsens as you saturate.
        let bought = currentAcquisitionCost > 0
            ? (dailyGrowthSpend * days) / currentAcquisitionCost
            : 0
        let acquired = inbound + referred + bought

        let churned = customers * dailyChurnRate(techDebt: techDebt) * days

        customers = max(0, customers + acquired - churned)
        totalAcquired += acquired
        totalChurned += churned

        let revenue = dailyRevenue * days
        let serving = dailyCostToServe * days
        subscriptionRevenue += revenue

        recordHistory(days: days)
        return (revenue, serving, acquired)
    }

    private mutating func recordHistory(days: Double) {
        dayAccumulator += days
        while dayAccumulator >= 1 {
            dayAccumulator -= 1
            history.append(customers)
            if history.count > 200 { history.removeFirst() }
        }
    }

    /// Customers lost outright to an incident - an outage or a breach
    /// costs you people, not just money.
    mutating func loseCustomers(fraction: Double) -> Double {
        let lost = customers * min(max(fraction, 0), 1)
        customers = max(0, customers - lost)
        totalChurned += lost
        return lost
    }

    // MARK: Exit

    /// What an acquirer offers. Revenue multiple, stretched by growth,
    /// minus whatever diligence turns up.
    func exitValuation(openTechDebt: Double) -> ExitOffer {
        let arr = annualRecurringRevenue
        let growthBonus = min(1, max(0, growthRate / 0.35)) * spec.growthMultipleBonus
        // What a peso of revenue is worth depends on what business it is.
        let multiple = (spec.baseExitMultiple + growthBonus) * (venture?.exitMultipleFactor ?? 1)
        let headline = arr * multiple
        let haircut = min(headline, openTechDebt * spec.diligenceCostPerDebt)
        return ExitOffer(
            annualRecurringRevenue: arr,
            multiple: multiple,
            headlineValuation: headline,
            diligenceHaircut: haircut,
            customers: customers,
            growthRate: growthRate
        )
    }
}

/// The offer on the table at the end of a startup run, itemised so the
/// player can see exactly which decision cost them how much.
struct ExitOffer {
    let annualRecurringRevenue: Double
    let multiple: Double
    let headlineValuation: Double
    let diligenceHaircut: Double
    let customers: Double
    let growthRate: Double

    var netValuation: Double { max(0, headlineValuation - diligenceHaircut) }
}

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

    var costToServePerCustomerPerDay: Double { spec.monthlyCostToServe / 30 }

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
        spec.baseDailyChurn * (1 + techDebt / spec.churnDebtTolerance)
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
        let multiple = spec.baseExitMultiple + growthBonus
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

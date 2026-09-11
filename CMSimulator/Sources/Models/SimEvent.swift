//
//  SimEvent.swift
//  CMSimulator
//
//  The incident deck. Extended from the original in two ways that matter:
//  each kind now belongs to a *mitigation class*, so Risk can buy cover
//  against something specific rather than nudging one gauge; and events
//  can now hit money, schedule, materials, morale, client trust or the
//  price index rather than only cost and progress.
//
//  Events also no longer require a gauge to be "in the red" to fire. In
//  the old build, owning five boosters pinned both gauges at the ceiling
//  and the entire disaster system switched off. Here incidents are always
//  possible; exposure just makes them likelier and worse.
//

import Foundation

/// What a mitigation protects against. Risk capability funds these
/// individually, so cover is a portfolio decision.
/// Five structural buckets of things that can go wrong, shared by every
/// scenario so Risk stays one system. The case names are construction
/// flavoured for historical reasons; the player-facing labels come from
/// Scenario.swift and depend on which scenario is running.
enum MitigationClass: String, CaseIterable, Identifiable {
    case weather
    case security
    case safety
    case technical
    case client

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .weather: return "cloud.heavyrain.fill"
        case .security: return "lock.shield.fill"
        case .safety: return "cross.case.fill"
        case .technical: return "ruler.fill"
        case .client: return "doc.text.fill"
        }
    }

    var purchaseCost: Double {
        switch self {
        case .weather: return 34_000
        case .security: return 25_000
        case .safety: return 42_000
        case .technical: return 37_000
        case .client: return 29_000
        }
    }

    var dailyUpkeep: Double {
        switch self {
        case .weather: return 310
        case .security: return 450
        case .safety: return 570
        case .technical: return 400
        case .client: return 280
        }
    }

    /// Multiplier on the probability of its events once held.
    var probabilityReduction: Double { 0.45 }
    /// Multiplier on the severity of its events once held.
    var severityReduction: Double { 0.6 }
}

/// Cover you can simply go out and buy. Insurance used to arrive only as
/// a side effect of staffing the Risk capability, which meant a player who
/// wanted protection had to buy a whole department to get it - and a
/// scenario that never staffed Risk could not insure anything at all.
///
/// A policy is now its own decision, available in every scenario from day
/// one. The Risk desk still earns its keep: it makes the same cover
/// cheaper and cuts the excess you carry.
enum InsurancePolicy: String, CaseIterable, Identifiable {
    case none
    case basic
    case standard
    case full

    var id: String { rawValue }

    var name: String {
        switch self {
        case .none: return String(localized: "Uninsured", comment: "Insurance policy tier")
        case .basic: return String(localized: "Third party only", comment: "Insurance policy tier")
        case .standard: return String(localized: "Standard cover", comment: "Insurance policy tier")
        case .full: return String(localized: "Full cover", comment: "Insurance policy tier")
        }
    }

    /// Share of any loss above the excess that the insurer carries.
    var coverage: Double {
        switch self {
        case .none: return 0
        case .basic: return 0.35
        case .standard: return 0.55
        case .full: return 0.75
        }
    }

    /// Daily premium as a share of contract value, before any discount.
    var premiumRate: Double {
        switch self {
        case .none: return 0
        case .basic: return 0.00016
        case .standard: return 0.00030
        case .full: return 0.00052
        }
    }

    /// The excess you carry yourself, before the risk desk argues it down.
    var deductible: Double {
        switch self {
        case .none: return 0
        case .basic: return 34_000
        case .standard: return 22_000
        case .full: return 14_000
        }
    }

    var blurb: String {
        switch self {
        case .none: return String(localized: "Every loss is yours. Cheapest right up until it is not.", comment: "Insurance policy description")
        case .basic: return String(localized: "Covers a third of the big ones, above a high excess. Thin, but it stops one bad day ending the run.", comment: "Insurance policy description")
        case .standard: return String(localized: "The usual policy. Covers over half of anything serious.", comment: "Insurance policy description")
        case .full: return String(localized: "Covers three quarters above a low excess. You will pay for it every single day, most of which nothing happens.", comment: "Insurance policy description")
        }
    }
}

/// One line of the risk register: how likely a class of incident is to be
/// the next thing that happens, what it would cost, and whether you hold
/// cover against it. Derived entirely from live engine state.
struct RiskRegisterRow: Identifiable {
    let mitigationClass: MitigationClass
    /// Chance this class lands on any given day.
    let dailyProbability: Double
    /// The dearest card in this class, at full severity, after cover.
    let worstCaseCost: Double
    let isCovered: Bool

    var id: String { mitigationClass.rawValue }
    /// Probability times cost - the only honest way to rank a register.
    var expectedDailyCost: Double { dailyProbability * worstCaseCost }

    /// Roughly how long until one of these is due.
    var daysBetween: Double { dailyProbability > 0 ? 1 / dailyProbability : .infinity }
}

enum SimEventKind: CaseIterable {
    case hurricane
    case fire
    case safetyIncident
    case materialTheft
    case designClash
    case permitRejection
    case structuralDefect
    case changeOrder
    case supplierFailure
    case priceSpike
    case laborWalkout
    // Startup deck.
    case cloudOutage
    case dataBreach
    case keyDeparture
    case burnoutWave
    case criticalBug
    case scalingFailure
    case investorPushback
    case pivotRequest
    case vendorRepricing
    case patentClaim
    case licenceContamination
    case founderDispute
    // Import deck.
    case customsHold
    case tariffHike
    case freightSpike
    case currencySwing
    case factoryQualityFailure
    case buyerDefault
    case marketplacePolicyChange
    case competitorUndercut
    case portCongestion
    case warehouseInjury

    var mitigationClass: MitigationClass {
        switch self {
        case .hurricane: return .weather
        case .fire, .safetyIncident, .laborWalkout: return .safety
        case .materialTheft, .supplierFailure, .priceSpike: return .security
        case .designClash, .structuralDefect: return .technical
        case .permitRejection, .changeOrder: return .client
        case .cloudOutage: return .weather
        case .dataBreach, .vendorRepricing: return .security
        case .keyDeparture, .burnoutWave: return .safety
        case .criticalBug, .scalingFailure: return .technical
        case .investorPushback, .pivotRequest, .founderDispute: return .client
        case .patentClaim, .licenceContamination: return .security
        case .freightSpike, .portCongestion: return .weather
        case .currencySwing, .buyerDefault: return .security
        case .factoryQualityFailure, .competitorUndercut: return .technical
        case .customsHold, .tariffHike, .marketplacePolicyChange: return .client
        case .warehouseInjury: return .safety
        }
    }

    /// Which scenarios this incident belongs to. A brief carries its own
    /// deck, so a building site never sees a data breach and a startup
    /// never sees a hurricane.
    static func deck(for scenario: ScenarioKind) -> [SimEventKind] {
        switch scenario {
        case .construction:
            return [.hurricane, .fire, .safetyIncident, .materialTheft, .designClash,
                    .permitRejection, .structuralDefect, .changeOrder, .supplierFailure,
                    .priceSpike, .laborWalkout]
        case .importing:
            return [.customsHold, .tariffHike, .freightSpike, .currencySwing,
                    .factoryQualityFailure, .buyerDefault, .marketplacePolicyChange,
                    .competitorUndercut, .portCongestion, .warehouseInjury]
        case .startup:
            return [.cloudOutage, .dataBreach, .keyDeparture, .burnoutWave, .criticalBug,
                    .scalingFailure, .investorPushback, .pivotRequest, .vendorRepricing,
                    .patentClaim, .licenceContamination, .founderDispute]
        }
    }

    var title: String {
        switch self {
        case .hurricane: return String(localized: "Storm hits the site", comment: "Incident title")
        case .fire: return String(localized: "Fire on site", comment: "Incident title")
        case .safetyIncident: return String(localized: "Safety incident", comment: "Incident title")
        case .materialTheft: return String(localized: "Materials stolen", comment: "Incident title")
        case .designClash: return String(localized: "Design clash discovered", comment: "Incident title")
        case .permitRejection: return String(localized: "Permit rejected", comment: "Incident title")
        case .structuralDefect: return String(localized: "Structural defect found", comment: "Incident title")
        case .changeOrder: return String(localized: "Client change order", comment: "Incident title")
        case .supplierFailure: return String(localized: "Supplier default", comment: "Incident title")
        case .priceSpike: return String(localized: "Material prices spike", comment: "Incident title")
        case .laborWalkout: return String(localized: "Crew walks off", comment: "Incident title")
        case .portCongestion: return String(localized: "The port is backed up", comment: "Incident title")
        case .warehouseInjury: return String(localized: "Injury in the warehouse", comment: "Incident title")
        case .competitorUndercut: return String(localized: "A competitor undercuts you", comment: "Incident title")
        case .marketplacePolicyChange: return String(localized: "The marketplace changes its fees", comment: "Incident title")
        case .buyerDefault: return String(localized: "A buyer does not pay", comment: "Incident title")
        case .factoryQualityFailure: return String(localized: "A bad batch ships", comment: "Incident title")
        case .currencySwing: return String(localized: "The currency moves against you", comment: "Incident title")
        case .freightSpike: return String(localized: "Freight rates spike", comment: "Incident title")
        case .tariffHike: return String(localized: "Tariffs go up", comment: "Incident title")
        case .customsHold: return String(localized: "Container held at customs", comment: "Incident title")
        case .cloudOutage: return String(localized: "Cloud provider outage", comment: "Incident title")
        case .dataBreach: return String(localized: "Security incident", comment: "Incident title")
        case .keyDeparture: return String(localized: "A key engineer resigns", comment: "Incident title")
        case .burnoutWave: return String(localized: "Burnout spreads", comment: "Incident title")
        case .criticalBug: return String(localized: "Critical bug in production", comment: "Incident title")
        case .scalingFailure: return String(localized: "The system buckles under load", comment: "Incident title")
        case .investorPushback: return String(localized: "Investors push back", comment: "Incident title")
        case .pivotRequest: return String(localized: "The board wants a pivot", comment: "Incident title")
        case .vendorRepricing: return String(localized: "A vendor reprices mid-contract", comment: "Incident title")
        case .patentClaim: return String(localized: "A patent claim lands", comment: "Incident title")
        case .licenceContamination: return String(localized: "A licence problem in the codebase", comment: "Incident title")
        case .founderDispute: return String(localized: "A dispute over who owns what", comment: "Incident title")
        }
    }

    var message: String {
        switch self {
        case .hurricane: return String(localized: "High winds damaged the works. Cleanup and repairs hit the budget.", comment: "Incident description")
        case .fire: return String(localized: "A site fire destroyed materials and equipment before it was contained.", comment: "Incident description")
        case .safetyIncident: return String(localized: "Work halted for a safety review after an on-site incident.", comment: "Incident description")
        case .materialTheft: return String(localized: "Materials went missing from the laydown yard overnight.", comment: "Incident description")
        case .designClash: return String(localized: "A coordination clash between disciplines needs rework.", comment: "Incident description")
        case .permitRejection: return String(localized: "The inspector rejected the submittal. Revise and resubmit.", comment: "Incident description")
        case .structuralDefect: return String(localized: "Quality control caught a defect that must be fixed before continuing.", comment: "Incident description")
        case .changeOrder: return String(localized: "The client requested a scope change mid-build.", comment: "Incident description")
        case .supplierFailure: return String(localized: "A supplier defaulted. Deliveries in transit are delayed.", comment: "Incident description")
        case .priceSpike: return String(localized: "A supply shock sent the materials index sharply higher.", comment: "Incident description")
        case .laborWalkout: return String(localized: "Morale broke down and part of the crew walked off the job.", comment: "Incident description")
        case .portCongestion: return String(localized: "Berthing delays. Everything on the water arrives later than promised.", comment: "Incident description")
        case .warehouseInjury: return String(localized: "Someone was hurt handling stock. Work stopped for the investigation.", comment: "Incident description")
        case .competitorUndercut: return String(localized: "Someone else listed the same goods cheaper. Your volume drops unless you follow them down.", comment: "Incident description")
        case .marketplacePolicyChange: return String(localized: "Fees were restructured. Every sale from here earns a little less.", comment: "Incident description")
        case .buyerDefault: return String(localized: "An account went under owing you money you had already counted.", comment: "Incident description")
        case .factoryQualityFailure: return String(localized: "A production run came out badly and is already on the water.", comment: "Incident description")
        case .currencySwing: return String(localized: "The exchange rate moved the wrong way between ordering and paying.", comment: "Incident description")
        case .freightSpike: return String(localized: "Container rates jumped. The next shipment costs materially more.", comment: "Incident description")
        case .tariffHike: return String(localized: "Duty on this category was raised. Everything still in transit costs more to land.", comment: "Incident description")
        case .customsHold: return String(localized: "Paperwork queries. The goods sit in a bonded warehouse, paid for and unsellable.", comment: "Incident description")
        case .cloudOutage: return String(localized: "The platform went down with it. Nothing shipped while everyone firefought.", comment: "Incident description")
        case .dataBreach: return String(localized: "An exposed credential was found. Everything stopped for the response.", comment: "Incident description")
        case .keyDeparture: return String(localized: "Someone who held a lot of context in their head handed in their notice.", comment: "Incident description")
        case .burnoutWave: return String(localized: "Months of pace caught up with the team at once.", comment: "Incident description")
        case .criticalBug: return String(localized: "Something shipped broken and had to be unpicked in a hurry.", comment: "Incident description")
        case .scalingFailure: return String(localized: "Load outgrew the architecture. Parts of it have to be rebuilt.", comment: "Incident description")
        case .investorPushback: return String(localized: "The last update did not land well. Confidence took a knock.", comment: "Incident description")
        case .pivotRequest: return String(localized: "The board wants the product pointed somewhere new.", comment: "Incident description")
        case .vendorRepricing: return String(localized: "A vendor raised prices at renewal and there was no time to switch.", comment: "Incident description")
        case .patentClaim: return String(localized: "A competitor says part of the product is theirs. Lawyers now, and a discount at diligence either way.", comment: "Incident description")
        case .licenceContamination: return String(localized: "A dependency turned out to be copyleft. Somebody has to rip it out and rewrite it.", comment: "Incident description")
        case .founderDispute: return String(localized: "An early contributor claims equity that was never papered. Investors noticed.", comment: "Incident description")
        }
    }

    var symbolName: String {
        switch self {
        case .hurricane: return "hurricane"
        case .fire: return "flame.fill"
        case .safetyIncident: return "cross.case.fill"
        case .materialTheft: return "shippingbox.and.arrow.backward.fill"
        case .designClash: return "exclamationmark.triangle.fill"
        case .permitRejection: return "xmark.seal.fill"
        case .structuralDefect: return "wrench.and.screwdriver.fill"
        case .changeOrder: return "arrow.triangle.2.circlepath"
        case .supplierFailure: return "truck.box.badge.clock.fill"
        case .priceSpike: return "chart.line.uptrend.xyaxis"
        case .laborWalkout: return "person.2.slash.fill"
        case .portCongestion: return "clock.badge.exclamationmark.fill"
        case .warehouseInjury: return "bandage.fill"
        case .competitorUndercut: return "arrow.down.right.circle.fill"
        case .marketplacePolicyChange: return "building.columns.fill"
        case .buyerDefault: return "person.crop.circle.badge.xmark"
        case .factoryQualityFailure: return "xmark.seal.fill"
        case .currencySwing: return "dollarsign.arrow.circlepath"
        case .freightSpike: return "ferry.fill"
        case .tariffHike: return "percent"
        case .customsHold: return "lock.doc.fill"
        case .cloudOutage: return "icloud.slash.fill"
        case .dataBreach: return "lock.trianglebadge.exclamationmark.fill"
        case .keyDeparture: return "person.fill.xmark"
        case .burnoutWave: return "battery.0percent"
        case .criticalBug: return "ladybug.fill"
        case .scalingFailure: return "chart.line.downtrend.xyaxis"
        case .investorPushback: return "hand.thumbsdown.fill"
        case .pivotRequest: return "arrow.triangle.branch"
        case .vendorRepricing: return "tag.slash.fill"
        case .patentClaim: return "building.columns.fill"
        case .licenceContamination: return "doc.badge.gearshape.fill"
        case .founderDispute: return "person.2.slash.fill"
        }
    }

    /// Direct cost as a fraction of contract value. Anchored to the
    /// contract rather than to spend-to-date: the old version scaled off
    /// a running total that included previous disasters, so incidents
    /// compounded into unrecoverable spirals late in a run.
    var costFractionRange: ClosedRange<Double> {
        switch self {
        case .hurricane: return 0.020...0.045
        case .fire: return 0.030...0.060
        case .safetyIncident: return 0.012...0.028
        case .materialTheft: return 0.008...0.020
        case .designClash: return 0.012...0.030
        case .permitRejection: return 0.006...0.016
        case .structuralDefect: return 0.018...0.038
        case .changeOrder: return 0.010...0.035
        case .supplierFailure: return 0.004...0.012
        case .priceSpike: return 0...0
        case .laborWalkout: return 0.006...0.014
        case .portCongestion: return 0.006...0.016
        case .warehouseInjury: return 0.010...0.024
        case .competitorUndercut: return 0...0
        case .marketplacePolicyChange: return 0.008...0.020
        case .buyerDefault: return 0...0
        case .factoryQualityFailure: return 0.016...0.038
        case .currencySwing: return 0.010...0.026
        case .freightSpike: return 0.014...0.032
        case .tariffHike: return 0.018...0.040
        case .customsHold: return 0.012...0.030
        case .cloudOutage: return 0.010...0.026
        case .dataBreach: return 0.022...0.050
        case .keyDeparture: return 0.008...0.022
        case .burnoutWave: return 0.004...0.012
        case .criticalBug: return 0.012...0.030
        case .scalingFailure: return 0.020...0.042
        case .investorPushback: return 0.004...0.012
        case .pivotRequest: return 0.008...0.028
        case .vendorRepricing: return 0...0
        case .patentClaim: return 0.018...0.048
        case .licenceContamination: return 0.006...0.018
        case .founderDispute: return 0.010...0.030
        }
    }

    /// Units of built work destroyed on the furthest-along package.
    var setbackRange: ClosedRange<Double>? {
        switch self {
        case .hurricane: return 2...6
        case .fire: return 3...8
        case .safetyIncident: return 1...3
        case .designClash: return 2...5
        case .permitRejection: return 1...2.5
        case .structuralDefect: return 3...7
        case .cloudOutage: return 1...4
        case .criticalBug: return 2...5
        case .scalingFailure: return 4...9
        case .dataBreach: return 1...3
        default: return nil
        }
    }

    /// Units of material stock destroyed or stolen.
    var materialLossRange: ClosedRange<Double>? {
        switch self {
        case .fire: return 6...16
        case .materialTheft: return 8...22
        case .customsHold: return 2...6
        case .hurricane: return 3...9
        default: return nil
        }
    }

    /// Days added to every order currently in transit.
    var deliveryDelayRange: ClosedRange<Double>? {
        switch self {
        case .supplierFailure: return 5...12
        case .customsHold: return 8...20
        case .portCongestion: return 6...16
        case .freightSpike: return 2...6
        case .hurricane: return 1...4
        default: return nil
        }
    }

    /// Morale lost across the whole roster.
    var moraleHitRange: ClosedRange<Double>? {
        switch self {
        case .safetyIncident: return 0.10...0.20
        case .fire: return 0.08...0.16
        case .laborWalkout: return 0.15...0.28
        case .burnoutWave: return 0.18...0.32
        case .keyDeparture: return 0.08...0.15
        case .cloudOutage: return 0.05...0.12
        case .warehouseInjury: return 0.10...0.20
        default: return nil
        }
    }

    /// Client trust lost.
    var trustHitRange: ClosedRange<Double>? {
        switch self {
        case .permitRejection: return 0.05...0.12
        case .structuralDefect: return 0.08...0.15
        case .safetyIncident: return 0.04...0.10
        case .designClash: return 0.03...0.08
        case .investorPushback: return 0.10...0.20
        case .patentClaim: return 0.06...0.14
        case .founderDispute: return 0.12...0.24
        case .dataBreach: return 0.08...0.18
        case .scalingFailure: return 0.06...0.14
        case .criticalBug: return 0.04...0.10
        default: return nil
        }
    }

    /// Latent defects injected straight into the works.
    var defectInjectionRange: ClosedRange<Double>? {
        switch self {
        case .structuralDefect: return 3...8
        case .designClash: return 2...6
        case .changeOrder: return 1...4
        case .factoryQualityFailure: return 6...16
        case .competitorUndercut: return 2...5
        case .criticalBug: return 3...8
        case .scalingFailure: return 4...10
        case .pivotRequest: return 2...6
        default: return nil
        }
    }

    /// Fires a materials price shock of this magnitude.
    var priceShockRange: ClosedRange<Double>? {
        switch self {
        case .priceSpike: return 0.12...0.30
        case .supplierFailure: return 0.04...0.10
        case .vendorRepricing: return 0.10...0.26
        case .tariffHike: return 0.08...0.20
        case .freightSpike: return 0.10...0.24
        case .currencySwing: return 0.06...0.18
        case .marketplacePolicyChange: return 0.04...0.10
        default: return nil
        }
    }

    /// Scope added by the client. Extra work, but also extra money -
    /// change orders are not purely a punishment.
    var scopeAddedRange: ClosedRange<Double>? {
        switch self {
        case .changeOrder: return 4...12
        case .pivotRequest: return 5...14
        default: return nil
        }
    }

    /// Picks an incident of the given class from a scenario's own deck.
    /// Falls back to the whole class if a deck somehow has no entry for
    /// it, so a malformed scenario degrades rather than trapping.
    static func random(in mitigationClass: MitigationClass, from deck: [SimEventKind]) -> SimEventKind {
        let candidates = deck.filter { $0.mitigationClass == mitigationClass }
        if let pick = candidates.randomElement() { return pick }
        return allCases.filter { $0.mitigationClass == mitigationClass }.randomElement()!
    }

    /// True when the incident costs you a person outright.
    var takesAWorker: Bool { self == .keyDeparture }

    /// Share of money already earned but not yet paid out that simply
    /// vanishes. A buyer going under is the sharpest lesson in the
    /// difference between a sale and cash.
    var receivableLossRange: ClosedRange<Double>? {
        switch self {
        case .buyerDefault: return 0.25...0.60
        default: return nil
        }
    }
}

/// One fired incident, with everything it actually did, so the banner can
/// report consequences instead of just flavour text.
struct SimEvent: Identifiable {
    let id = UUID()
    let kind: SimEventKind
    let message: String
    let grossCost: Double
    /// Amount insurance picked up.
    let insuranceCovered: Double
    /// Human-readable list of what else it did.
    let consequences: [String]

    var netCost: Double { max(0, grossCost - insuranceCovered) }
}

/// A warning surfaced by Planning before an incident lands.
struct RiskForecast: Identifiable {
    let id = UUID()
    let mitigationClass: MitigationClass
    let daysAway: Double
    let severity: Double

    var severityLabel: String {
        switch severity {
        case ..<0.34: return String(localized: "Low", comment: "Forecast severity")
        case ..<0.67: return String(localized: "Moderate", comment: "Forecast severity")
        default: return String(localized: "Severe", comment: "Forecast severity")
        }
    }
}

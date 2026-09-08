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
enum MitigationClass: String, CaseIterable, Identifiable {
    case weather
    case security
    case safety
    case technical
    case client

    var id: String { rawValue }

    var name: String {
        switch self {
        case .weather: return String(localized: "Weather protection", comment: "Mitigation name")
        case .security: return String(localized: "Site security", comment: "Mitigation name")
        case .safety: return String(localized: "Safety programme", comment: "Mitigation name")
        case .technical: return String(localized: "Technical review", comment: "Mitigation name")
        case .client: return String(localized: "Contract management", comment: "Mitigation name")
        }
    }

    var blurb: String {
        switch self {
        case .weather: return String(localized: "Storm shielding and drainage. Cuts weather losses.", comment: "Mitigation description")
        case .security: return String(localized: "Fencing, lighting, night watch. Stops material walking off site.", comment: "Mitigation description")
        case .safety: return String(localized: "Toolbox talks and enforcement. Fewer incidents, fewer stoppages.", comment: "Mitigation description")
        case .technical: return String(localized: "Independent design checking. Catches clashes before they are built.", comment: "Mitigation description")
        case .client: return String(localized: "Tight change control. Blunts scope creep and rejections.", comment: "Mitigation description")
        }
    }

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

    var mitigationClass: MitigationClass {
        switch self {
        case .hurricane: return .weather
        case .fire, .safetyIncident, .laborWalkout: return .safety
        case .materialTheft, .supplierFailure, .priceSpike: return .security
        case .designClash, .structuralDefect: return .technical
        case .permitRejection, .changeOrder: return .client
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
        default: return nil
        }
    }

    /// Units of material stock destroyed or stolen.
    var materialLossRange: ClosedRange<Double>? {
        switch self {
        case .fire: return 6...16
        case .materialTheft: return 8...22
        case .hurricane: return 3...9
        default: return nil
        }
    }

    /// Days added to every order currently in transit.
    var deliveryDelayRange: ClosedRange<Double>? {
        switch self {
        case .supplierFailure: return 5...12
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
        default: return nil
        }
    }

    /// Latent defects injected straight into the works.
    var defectInjectionRange: ClosedRange<Double>? {
        switch self {
        case .structuralDefect: return 3...8
        case .designClash: return 2...6
        case .changeOrder: return 1...4
        default: return nil
        }
    }

    /// Fires a materials price shock of this magnitude.
    var priceShockRange: ClosedRange<Double>? {
        switch self {
        case .priceSpike: return 0.12...0.30
        case .supplierFailure: return 0.04...0.10
        default: return nil
        }
    }

    /// Scope added by the client. Extra work, but also extra money -
    /// change orders are not purely a punishment.
    var scopeAddedRange: ClosedRange<Double>? {
        switch self {
        case .changeOrder: return 4...12
        default: return nil
        }
    }

    static func random(in mitigationClass: MitigationClass) -> SimEventKind {
        allCases.filter { $0.mitigationClass == mitigationClass }.randomElement()!
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

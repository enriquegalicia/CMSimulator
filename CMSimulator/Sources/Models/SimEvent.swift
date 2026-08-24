//
//  SimEvent.swift
//  CMSimulator
//
//  The original's ViewController declared an "Eventos" timer and two
//  handler stubs - eventoriesgo ("risk event") and eventocalidad
//  ("quality event") - but never actually scheduled the timer or filled
//  in either body. This finishes that planned-but-abandoned mechanic:
//  when a gauge sits in the red for a while, something actually happens.
//
//  Each kind has its own cost-penalty range and setback range so a
//  fire doesn't cost the same as a stolen pallet of rebar - a data
//  table instead of one fixed range for everything, same spirit as
//  BoosterEffect.table.
//

import Foundation

enum SimEventCategory {
    case risk, quality
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

    var category: SimEventCategory {
        switch self {
        case .hurricane, .fire, .safetyIncident, .materialTheft: return .risk
        case .designClash, .permitRejection, .structuralDefect, .changeOrder: return .quality
        }
    }

    var title: String {
        switch self {
        case .hurricane: return String(localized: "Hurricane hits the site", comment: "Disaster event title")
        case .fire: return String(localized: "Fire on site", comment: "Disaster event title")
        case .safetyIncident: return String(localized: "Safety incident", comment: "Disaster event title")
        case .materialTheft: return String(localized: "Materials stolen", comment: "Disaster event title")
        case .designClash: return String(localized: "Design clash discovered", comment: "Disaster event title")
        case .permitRejection: return String(localized: "Permit rejected", comment: "Disaster event title")
        case .structuralDefect: return String(localized: "Structural defect found", comment: "Disaster event title")
        case .changeOrder: return String(localized: "Client change order", comment: "Disaster event title")
        }
    }

    var message: String {
        switch self {
        case .hurricane: return String(localized: "High winds damaged the site. Cleanup and repairs added cost to the project.", comment: "Disaster event description")
        case .fire: return String(localized: "A site fire destroyed materials and equipment before it was contained.", comment: "Disaster event description")
        case .safetyIncident: return String(localized: "Work halted for a safety review after an on-site incident.", comment: "Disaster event description")
        case .materialTheft: return String(localized: "Materials went missing from the laydown yard overnight.", comment: "Disaster event description")
        case .designClash: return String(localized: "A coordination clash between disciplines was found and needs rework.", comment: "Disaster event description")
        case .permitRejection: return String(localized: "The inspector rejected the current submittal - revise and resubmit.", comment: "Disaster event description")
        case .structuralDefect: return String(localized: "Quality control caught a defect that has to be fixed before continuing.", comment: "Disaster event description")
        case .changeOrder: return String(localized: "The client requested a scope change mid-build.", comment: "Disaster event description")
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
        }
    }

    /// Extra cost as a fraction of current total project cost.
    var costFractionRange: ClosedRange<Double> {
        switch self {
        case .hurricane: return 0.08...0.18
        case .fire: return 0.10...0.20
        case .safetyIncident: return 0.05...0.10
        case .materialTheft: return 0.03...0.08
        case .designClash: return 0.05...0.12
        case .permitRejection: return 0.04...0.09
        case .structuralDefect: return 0.07...0.15
        case .changeOrder: return 0.03...0.20
        }
    }

    /// Units of progress knocked off the furthest-along unlocked package.
    /// Theft and change orders don't touch physical progress, just cost.
    var setbackRange: ClosedRange<Double>? {
        switch self {
        case .hurricane: return 1...3
        case .fire: return 2...4
        case .safetyIncident: return 0.5...2
        case .materialTheft: return nil
        case .designClash: return 1...3
        case .permitRejection: return 0.5...1.5
        case .structuralDefect: return 1.5...3.5
        case .changeOrder: return nil
        }
    }

    static func random(for category: SimEventCategory) -> SimEventKind {
        allCases.filter { $0.category == category }.randomElement()!
    }
}

struct SimEvent: Identifiable {
    let id = UUID()
    let kind: SimEventKind
    let message: String
    let extraCost: Double
    let setbackUnits: Double
}

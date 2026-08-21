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
        case .hurricane: return "Hurricane hits the site"
        case .fire: return "Fire on site"
        case .safetyIncident: return "Safety incident"
        case .materialTheft: return "Materials stolen"
        case .designClash: return "Design clash discovered"
        case .permitRejection: return "Permit rejected"
        case .structuralDefect: return "Structural defect found"
        case .changeOrder: return "Client change order"
        }
    }

    var message: String {
        switch self {
        case .hurricane: return "High winds damaged the site. Cleanup and repairs added cost to the project."
        case .fire: return "A site fire destroyed materials and equipment before it was contained."
        case .safetyIncident: return "Work halted for a safety review after an on-site incident."
        case .materialTheft: return "Materials went missing from the laydown yard overnight."
        case .designClash: return "A coordination clash between disciplines was found and needs rework."
        case .permitRejection: return "The inspector rejected the current submittal - revise and resubmit."
        case .structuralDefect: return "Quality control caught a defect that has to be fixed before continuing."
        case .changeOrder: return "The client requested a scope change mid-build."
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

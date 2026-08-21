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

import Foundation

enum SimEventKind {
    case hurricane      // risk-driven: a weather/site disaster
    case designClash     // quality-driven: a coordination clash discovered mid-build

    var title: String {
        switch self {
        case .hurricane: return "Hurricane hits the site"
        case .designClash: return "Design clash discovered"
        }
    }

    var symbolName: String {
        switch self {
        case .hurricane: return "hurricane"
        case .designClash: return "exclamationmark.triangle.fill"
        }
    }
}

struct SimEvent: Identifiable {
    let id = UUID()
    let kind: SimEventKind
    let message: String
    let extraCost: Double
    let setbackUnits: Double
}

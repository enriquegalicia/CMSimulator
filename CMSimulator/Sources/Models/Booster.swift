//
//  Booster.swift
//  CMSimulator
//
//  Swift port of Potenciadores - one of the 6 knowledge-area boosters
//  (Planning, Procurement, Risk, Communications, Training, Quality).
//  Buying units of a booster costs money now but nudges the project's
//  other metrics (see BoosterEffect) once purchased.
//

import Foundation

enum BoosterKind: String, CaseIterable, Identifiable {
    case planning = "Planning"
    case procurement = "Procurement"
    case risk = "Risk"
    case communications = "Communications"
    case training = "Training"
    case quality = "Quality"

    var id: String { rawValue }

    /// Localized display text - kept separate from `rawValue` since the raw
    /// value is also used as a stable identifier (BoosterEffect.table keys,
    /// image lookups) that must never change with the device's language.
    var displayName: String {
        switch self {
        case .planning: return String(localized: "Planning", comment: "Booster name")
        case .procurement: return String(localized: "Procurement", comment: "Booster name")
        case .risk: return String(localized: "Risk", comment: "Booster name")
        case .communications: return String(localized: "Communications", comment: "Booster name")
        case .training: return String(localized: "Training", comment: "Booster name")
        case .quality: return String(localized: "Quality", comment: "Booster name")
        }
    }
}

struct Booster: Identifiable {
    let id: BoosterKind
    let imageName: String
    let initialCost: Double
    let startThreshold: Double
    let affects: String

    var cost: Double
    var cumulativeCost: Double = 0
    var totalSpent: Double = 0
    var purchasedCount: Int = 0
    var isUnlocked: Bool = false

    var title: String { id.displayName }

    init(kind: BoosterKind, imageName: String, initialCost: Double, startThreshold: Double, affects: String) {
        self.id = kind
        self.imageName = imageName
        self.initialCost = initialCost
        self.startThreshold = startThreshold
        self.affects = affects
        self.cost = initialCost
    }
}

//
//  Capability.swift
//  CMSimulator
//
//  Phase 3: the six knowledge areas, rebuilt.
//
//  They used to be one lever with six pictures. In the old
//  BoosterEffect.table, Planning, Quality and Communications all resolved
//  to the same three verbs - nudge rate up, nudge quality up, discount a
//  neighbour - and Risk and Training differed only in which gauge they
//  touched. Nothing in the set changed how you played, only how fast the
//  same numbers moved.
//
//  Each one now answers a different question:
//
//    Planning        buys information       - what is coming, and when will we finish
//    Acquisitions    takes a position       - lead times and a price you may hedge
//    Quality         retires a debt         - defects found early are cheap
//    Risk            allocates a portfolio  - tail protection you may never use
//    Communications  controls the cash clock- client trust gates when you get paid
//    Training        trades present for future - costs output now, pays skill later
//
//  They are also staffed, not bought: each level charges upkeep every day
//  it is held. A capability you cannot afford to run is one you should
//  not have hired.
//

import Foundation

enum CapabilityKind: String, CaseIterable, Identifiable {
    case planning = "Planning"
    case procurement = "Procurement"
    case quality = "Quality"
    case risk = "Risk"
    case communications = "Communications"
    case training = "Training"

    var id: String { rawValue }

    /// Stable, never localized - used for image lookup and persistence.
    var imageName: String { "\(rawValue).png" }

    var displayName: String {
        switch self {
        case .planning: return String(localized: "Planning", comment: "Capability name")
        case .procurement: return String(localized: "Acquisitions", comment: "Capability name")
        case .quality: return String(localized: "Quality", comment: "Capability name")
        case .risk: return String(localized: "Risk", comment: "Capability name")
        case .communications: return String(localized: "Communications", comment: "Capability name")
        case .training: return String(localized: "Training", comment: "Capability name")
        }
    }

    /// The one-word verb. Shown on the card so the player can tell at a
    /// glance that these six do genuinely different things.
    var verb: String {
        switch self {
        case .planning: return String(localized: "Buys information", comment: "Capability verb")
        case .procurement: return String(localized: "Takes a position", comment: "Capability verb")
        case .quality: return String(localized: "Retires a debt", comment: "Capability verb")
        case .risk: return String(localized: "Allocates cover", comment: "Capability verb")
        case .communications: return String(localized: "Controls the cash clock", comment: "Capability verb")
        case .training: return String(localized: "Trades now for later", comment: "Capability verb")
        }
    }

    var summary: String {
        switch self {
        case .planning:
            return String(localized: "Forecasts the finish date and warns you about trouble before it lands. Higher levels let you fast-track a package early.", comment: "Capability summary")
        case .procurement:
            return String(localized: "Cuts delivery lead times and unlocks price hedging, so crews stop standing idle waiting on materials.", comment: "Capability summary")
        case .quality:
            return String(localized: "Inspects work in progress. Defects caught now cost a fraction of what they cost at handover.", comment: "Capability summary")
        case .risk:
            return String(localized: "Funds specific mitigations and insurance cover against the incidents that can end a run.", comment: "Capability summary")
        case .communications:
            return String(localized: "Builds client trust, which decides how fast you get paid and whether they grant an extension.", comment: "Capability summary")
        case .training:
            return String(localized: "Sends workers on courses. They earn nothing while away and come back permanently better.", comment: "Capability summary")
        }
    }

    /// Cost to take the capability from level n to n+1.
    var stepUpCost: Double {
        switch self {
        case .planning: return 22_000
        case .procurement: return 26_000
        case .quality: return 24_000
        case .risk: return 28_000
        case .communications: return 19_000
        case .training: return 21_000
        }
    }

    /// Daily upkeep per level. This is what stops capabilities being
    /// free auto-buys: they compete with payroll every single day.
    var dailyUpkeepPerLevel: Double {
        switch self {
        case .planning: return 310
        case .procurement: return 360
        case .quality: return 390
        case .risk: return 340
        case .communications: return 260
        case .training: return 215
        }
    }

    var maxLevel: Int { 3 }

    /// Overall progress at which this becomes available.
    var unlockThreshold: Double {
        switch self {
        case .planning: return 0
        case .procurement: return 0
        case .quality: return 6
        case .communications: return 10
        case .risk: return 16
        case .training: return 22
        }
    }
}

// MARK: - Run state

struct Capability: Identifiable {
    let kind: CapabilityKind
    var level: Int = 0
    var isUnlocked: Bool = false
    /// Everything spent stepping this capability up, for the P&L.
    var invested: Double = 0

    var id: CapabilityKind { kind }
    var title: String { kind.displayName }
    var imageName: String { kind.imageName }
    var isMaxed: Bool { level >= kind.maxLevel }
    var dailyUpkeep: Double { Double(level) * kind.dailyUpkeepPerLevel }
    var nextLevelCost: Double { kind.stepUpCost * (1 + Double(level) * 0.55) }
}

// MARK: - Derived effects
//
// Read as a group these are deliberately non-overlapping: no two
// capabilities move the same variable. That is the whole point of the
// rebuild, so it is worth keeping true as this grows.

enum CapabilityEffects {

    // Planning - information and options.

    /// Days of advance warning on brewing incidents. Level 0 sees nothing.
    static func forecastHorizonDays(level: Int) -> Double {
        [0, 7, 14, 21][min(level, 3)]
    }

    /// Half-width of the completion-date confidence band, as a fraction.
    /// Level 0 gets no forecast at all.
    static func forecastUncertainty(level: Int) -> Double {
        [1.0, 0.28, 0.16, 0.08][min(level, 3)]
    }

    /// How far below its start threshold a package may be fast-tracked.
    static func fastTrackAllowance(level: Int) -> Double {
        [0, 0, 8, 16][min(level, 3)]
    }

    /// Extra defects per unit for work done on a fast-tracked package -
    /// the price of starting before the predecessor is really ready.
    static let fastTrackDefectPenalty: Double = 0.022

    // Acquisitions - lead time and hedging.

    static func leadTimeMultiplier(level: Int) -> Double {
        [1.0, 0.82, 0.68, 0.55][min(level, 3)]
    }

    /// Discount on material unit prices from buying at scale.
    static func materialDiscount(level: Int) -> Double {
        [0, 0.04, 0.08, 0.13][min(level, 3)]
    }

    /// Price hedging needs a real procurement desk behind it.
    static func canHedge(level: Int) -> Bool { level >= 2 }

    // Quality - inspection throughput.

    /// Defect units inspected out per day. Nothing happens at level 0,
    /// which is exactly why the debt is invisible until handover.
    static func inspectionRatePerDay(level: Int) -> Double {
        [0, 0.45, 0.95, 1.7][min(level, 3)]
    }

    /// Cost to fix one defect found during the build.
    static let inspectionCostPerDefect: Double = 2_400
    /// Cost to fix one defect found at handover. The gap between these
    /// two numbers is the entire lesson.
    static let reworkCostPerDefect: Double = 11_000
    /// Days of delay per defect still open at handover.
    static let reworkDaysPerDefect: Double = 0.35

    // Risk - probability and severity.

    /// Multiplier on incident probability.
    static func incidentProbabilityMultiplier(level: Int) -> Double {
        [1.0, 0.78, 0.58, 0.42][min(level, 3)]
    }

    /// Insurance covers this share of incident cost above the deductible.
    static func insuranceCoverage(level: Int) -> Double {
        [0, 0.30, 0.50, 0.70][min(level, 3)]
    }

    static let insuranceDeductible: Double = 22_000

    // Communications - the cash clock.

    /// Days shaved off the client's payment delay.
    static func paymentSpeedUpDays(level: Int) -> Double {
        [0, 3, 6, 10][min(level, 3)]
    }

    /// Trust gained per day of holding this capability.
    static func trustGainPerDay(level: Int) -> Double {
        [0, 0.006, 0.012, 0.020][min(level, 3)]
    }

    /// Multiplier on client change-order frequency.
    static func changeOrderMultiplier(level: Int) -> Double {
        [1.0, 0.82, 0.66, 0.50][min(level, 3)]
    }

    /// Trust needed before the client will grant a deadline extension.
    static let extensionTrustThreshold: Double = 0.72
    static let extensionDaysGranted: Double = 14

    // Training - present for future.

    static func courseDays(level: Int) -> Double {
        [0, 8, 6, 4][min(level, 3)]
    }

    /// Permanent skill uplift from finishing a course.
    static func courseSkillGain(level: Int) -> Double {
        [0, 0.16, 0.24, 0.34][min(level, 3)]
    }

    /// Experience granted outright by a course - the shortcut past the
    /// 45 days a worker would otherwise need on the job.
    static func courseExperienceGain(level: Int) -> Double {
        [0, 0.14, 0.22, 0.32][min(level, 3)]
    }

    static let courseCostPerWorker: Double = 12_000
}

//
//  ProjectBrief.swift
//  CMSimulator
//
//  The contract the player signs, plus every scenario-specific number in
//  one place.
//
//  This is also the seam that makes the planned café / startup / import
//  scenarios cheap later: the engine reads its work streams, contract,
//  market behaviour and client from a brief rather than hardcoding
//  construction. Nothing here is referenced by the engine as a constant.
//  Phase 5 lifts this struct into a scenario file; until then construction
//  is simply the only brief that exists.
//

import Foundation

// MARK: - Client

/// Who is paying, and what they actually care about. The same site plays
/// three different ways depending on which of these signed the contract.
enum ClientPersona: String, CaseIterable, Identifiable {
    case developer      // cost-driven
    case institution    // quality-driven
    case retailer       // schedule-driven

    var id: String { rawValue }

    var name: String {
        switch self {
        case .developer: return String(localized: "Private developer", comment: "Client persona name")
        case .institution: return String(localized: "Public institution", comment: "Client persona name")
        case .retailer: return String(localized: "Retail chain", comment: "Client persona name")
        }
    }

    var brief: String {
        switch self {
        case .developer: return String(localized: "Margin is everything. Pays slowly, haggles, but tolerates a rough finish.", comment: "Client persona description")
        case .institution: return String(localized: "Inspects everything. Withholds hard on defects, but pays reliably and on time.", comment: "Client persona description")
        case .retailer: return String(localized: "The store opens on the date on the contract. Brutal late penalties, generous early bonus.", comment: "Client persona description")
        }
    }

    /// Multiplier on liquidated damages per day late.
    var latePenaltyFactor: Double {
        switch self {
        case .developer: return 0.8
        case .institution: return 1.0
        case .retailer: return 2.2
        }
    }

    /// Bonus per day finished early, as a fraction of the daily penalty.
    var earlyBonusFactor: Double {
        switch self {
        case .developer: return 0.15
        case .institution: return 0.2
        case .retailer: return 0.8
        }
    }

    /// Multiplier on how much retainage is withheld for unresolved defects.
    var defectWithholdingFactor: Double {
        switch self {
        case .developer: return 0.7
        case .institution: return 2.0
        case .retailer: return 1.0
        }
    }

    /// Base days between hitting a milestone and the money arriving,
    /// before Communications trust shortens it.
    var basePaymentDelayDays: Double {
        switch self {
        case .developer: return 10
        case .institution: return 5
        case .retailer: return 7
        }
    }

    /// Relative likelihood of the client injecting a change order.
    var changeOrderFactor: Double {
        switch self {
        case .developer: return 1.3
        case .institution: return 0.7
        case .retailer: return 1.1
        }
    }
}

// MARK: - Milestone

struct PaymentMilestone: Identifiable {
    let id: Int
    /// Overall project progress (0...100) that releases this payment.
    let progressThreshold: Double
    /// Share of contract value released, before retainage.
    let share: Double
}

// MARK: - Difficulty

enum Difficulty: String, CaseIterable, Identifiable {
    case steady, standard, tight

    var id: String { rawValue }

    var name: String {
        switch self {
        case .steady: return String(localized: "Steady", comment: "Difficulty name")
        case .standard: return String(localized: "Standard", comment: "Difficulty name")
        case .tight: return String(localized: "Tight", comment: "Difficulty name")
        }
    }

    var blurb: String {
        switch self {
        case .steady: return String(localized: "More working capital and a longer programme. Learn the systems.", comment: "Difficulty description")
        case .standard: return String(localized: "The intended balance. Deadline is reachable if you run a tight site.", comment: "Difficulty description")
        case .tight: return String(localized: "Thin capital, hard date, volatile prices. One bad week ends you.", comment: "Difficulty description")
        }
    }

    var startingCashFactor: Double {
        switch self {
        case .steady: return 1.5
        case .standard: return 1.0
        case .tight: return 0.7
        }
    }

    var creditLimitFactor: Double {
        switch self {
        case .steady: return 1.4
        case .standard: return 1.0
        case .tight: return 0.75
        }
    }

    var deadlineFactor: Double {
        switch self {
        case .steady: return 1.25
        case .standard: return 1.0
        case .tight: return 0.85
        }
    }

    var marketVolatilityFactor: Double {
        switch self {
        case .steady: return 0.6
        case .standard: return 1.0
        case .tight: return 1.6
        }
    }

    var eventFrequencyFactor: Double {
        switch self {
        case .steady: return 0.65
        case .standard: return 1.0
        case .tight: return 1.45
        }
    }

    /// Applied to the leaderboard score, so a Tight win outranks a Steady one.
    var scoreMultiplier: Double {
        switch self {
        case .steady: return 0.8
        case .standard: return 1.0
        case .tight: return 1.35
        }
    }
}

// MARK: - Work stream definition

/// The static definition of one work package. Separated from the mutable
/// `WorkPackage` run state so a brief can be described as pure data.
struct WorkStreamSpec {
    let id: String
    let title: String
    let imageName: String
    /// Total units of work to install.
    let units: Double
    /// Crew size beyond which the site gets crowded and output per head
    /// falls away. This is what stops "hire everyone" from being correct.
    let optimalCrew: Int
    /// Overall progress (0...100) at which this package can start.
    ///
    /// Must stay reachable using only the packages that unlock before it.
    /// Progress is weighted over *all* units (so it never runs backwards
    /// when something unlocks), which means each threshold has to sit
    /// below the cumulative unit share of everything preceding it, or the
    /// project soft-locks with nothing left that can legally start.
    let startThreshold: Double
    /// Cost of materials per unit of work, before the market index.
    let materialCostPerUnit: Double
    /// Units of material consumed per unit of work installed.
    let materialUnitsPerWorkUnit: Double
    /// Lead time in days for a standard order of this package's materials.
    let baseLeadTimeDays: Double
}

// MARK: - Brief

struct ProjectBrief {
    let scenarioName: String
    let clientPersona: ClientPersona
    let difficulty: Difficulty
    let seed: UInt64

    let contractValue: Double
    let startingCash: Double
    let creditLimit: Double
    let dailyInterestRate: Double
    let deadlineDays: Double
    /// Liquidated damages per day late, before the persona factor.
    let baseLatePenaltyPerDay: Double
    /// Fraction of each payment the client holds back until handover.
    let retainageRate: Double
    /// Mobilisation advance paid on signing, as a share of contract value.
    /// Real contracts front-load some money so the builder can get started;
    /// without it the opening is a pure coin-flip on whether the first
    /// milestone certifies before the initial capital runs out.
    let advanceRate: Double

    let milestones: [PaymentMilestone]
    let streams: [WorkStreamSpec]

    /// Labour market tightness. 1.0 is normal; higher means every
    /// candidate quotes a higher wage.
    let labourMarketFactor: Double
    /// Daily volatility of the materials price index.
    let marketVolatility: Double

    var latePenaltyPerDay: Double { baseLatePenaltyPerDay * clientPersona.latePenaltyFactor }
    var earlyBonusPerDay: Double { latePenaltyPerDay * clientPersona.earlyBonusFactor }
    var totalUnits: Double { streams.reduce(0) { $0 + $1.units } }

    // MARK: Construction scenario

    /// Sized so the crew numbers and the contract value are in the same
    /// world: ~3,500 units of work is roughly 2,700 worker-days, which at
    /// a peak crew in the fifties is a hundred-day programme. Thresholds
    /// are set against cumulative unit share (7% / 23% / 33% / 66% / 84%)
    /// so every package is reachable from the ones before it.
    static let constructionStreams: [WorkStreamSpec] = [
        WorkStreamSpec(id: "design", title: String(localized: "Design", comment: "Work package name"),
                       imageName: "Design.png", units: 250, optimalCrew: 8, startThreshold: 0,
                       materialCostPerUnit: 60, materialUnitsPerWorkUnit: 1, baseLeadTimeDays: 2),
        WorkStreamSpec(id: "structure", title: String(localized: "Structure", comment: "Work package name"),
                       imageName: "Structure.png", units: 540, optimalCrew: 16, startThreshold: 4,
                       materialCostPerUnit: 310, materialUnitsPerWorkUnit: 1, baseLeadTimeDays: 7),
        WorkStreamSpec(id: "engineering", title: String(localized: "Engineering", comment: "Work package name"),
                       imageName: "Engineering.png", units: 375, optimalCrew: 12, startThreshold: 11,
                       materialCostPerUnit: 90, materialUnitsPerWorkUnit: 1, baseLeadTimeDays: 3),
        WorkStreamSpec(id: "construction", title: String(localized: "Construction", comment: "Work package name"),
                       imageName: "Construction.png", units: 1160, optimalCrew: 34, startThreshold: 19,
                       materialCostPerUnit: 260, materialUnitsPerWorkUnit: 1, baseLeadTimeDays: 6),
        WorkStreamSpec(id: "ihs", title: String(localized: "IHS & IAA", comment: "Work package name - Hydro-sanitary & Air conditioning installations"),
                       imageName: "IHS.png", units: 625, optimalCrew: 19, startThreshold: 33,
                       materialCostPerUnit: 230, materialUnitsPerWorkUnit: 1, baseLeadTimeDays: 8),
        WorkStreamSpec(id: "ies", title: String(localized: "IES & IEL", comment: "Work package name - Electrical & Lighting installations"),
                       imageName: "IES.png", units: 550, optimalCrew: 17, startThreshold: 46,
                       materialCostPerUnit: 200, materialUnitsPerWorkUnit: 1, baseLeadTimeDays: 9),
    ]

    static let constructionMilestones: [PaymentMilestone] = [
        // Must sum to 1 - advanceRate, or the client pays out more than
        // the contract is worth.
        PaymentMilestone(id: 0, progressThreshold: 6, share: 0.14),
        PaymentMilestone(id: 1, progressThreshold: 26, share: 0.18),
        PaymentMilestone(id: 2, progressThreshold: 48, share: 0.18),
        PaymentMilestone(id: 3, progressThreshold: 72, share: 0.20),
        PaymentMilestone(id: 4, progressThreshold: 100, share: 0.18),
    ]

    /// Builds a run. Every varying number is drawn from `generator`, so a
    /// seed fully reproduces a project - which is what makes a shared
    /// daily challenge possible.
    static func construction(
        difficulty: Difficulty = .standard,
        persona: ClientPersona? = nil,
        seed: UInt64 = UInt64.random(in: 0..<UInt64.max)
    ) -> ProjectBrief {
        var rng = SeededGenerator(seed: seed)
        let chosenPersona = persona ?? ClientPersona.allCases.randomElement(using: &rng)!

        let contractValue: Double = 3_600_000
        let baseDeadline: Double = 110

        return ProjectBrief(
            scenarioName: String(localized: "Mixed-use build", comment: "Scenario name"),
            clientPersona: chosenPersona,
            difficulty: difficulty,
            seed: seed,
            contractValue: contractValue,
            startingCash: (300_000 * difficulty.startingCashFactor).rounded(),
            creditLimit: (450_000 * difficulty.creditLimitFactor).rounded(),
            dailyInterestRate: 0.00045,
            deadlineDays: (baseDeadline * difficulty.deadlineFactor).rounded(),
            baseLatePenaltyPerDay: 6_000,
            retainageRate: 0.07,
            advanceRate: 0.12,
            milestones: constructionMilestones,
            streams: constructionStreams,
            labourMarketFactor: Double.random(in: 0.88...1.22, using: &rng),
            marketVolatility: Double.random(in: 0.012...0.026, using: &rng) * difficulty.marketVolatilityFactor
        )
    }
}

// MARK: - Seeded RNG

/// SplitMix64. Deterministic and self-contained, so a seed reproduces a
/// run exactly - the basis for the shareable daily challenge.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

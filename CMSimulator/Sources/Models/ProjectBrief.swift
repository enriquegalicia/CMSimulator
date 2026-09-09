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

    /// The three cases are behaviours - cost-driven, quality-driven,
    /// schedule-driven - not industries. The raw values keep their
    /// original names so previously saved scores still decode.
    func name(in scenario: ScenarioKind) -> String {
        switch (self, scenario) {
        case (.developer, .construction):   return String(localized: "Private developer", comment: "Counterparty name")
        case (.developer, .startup):        return String(localized: "Angel syndicate", comment: "Counterparty name")
        case (.institution, .construction): return String(localized: "Public institution", comment: "Counterparty name")
        case (.institution, .startup):      return String(localized: "Institutional fund", comment: "Counterparty name")
        case (.retailer, .construction):    return String(localized: "Retail chain", comment: "Counterparty name")
        case (.retailer, .startup):         return String(localized: "Strategic partner", comment: "Counterparty name")
        }
    }

    func brief(in scenario: ScenarioKind) -> String {
        switch (self, scenario) {
        case (.developer, .construction):
            return String(localized: "Margin is everything. Pays slowly, haggles, but tolerates a rough finish.", comment: "Counterparty description")
        case (.developer, .startup):
            return String(localized: "Frugal and hands-off. Wires slowly and haggles, but forgives a rough product.", comment: "Counterparty description")
        case (.institution, .construction):
            return String(localized: "Inspects everything. Withholds hard on defects, but pays reliably and on time.", comment: "Counterparty description")
        case (.institution, .startup):
            return String(localized: "Serious diligence. Holds back hard on tech debt, but wires reliably and on time.", comment: "Counterparty description")
        case (.retailer, .construction):
            return String(localized: "The store opens on the date on the contract. Brutal late penalties, generous early bonus.", comment: "Counterparty description")
        case (.retailer, .startup):
            return String(localized: "The launch date is contractual. Brutal if you slip, generous if you land early.", comment: "Counterparty description")
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

/// What has to be true before money arrives.
enum PaymentTrigger {
    /// Overall work completed, 0...100. How a client certifies progress.
    case progress(Double)
    /// Paying customers reached. How investors decide you are worth
    /// funding - nobody wires a Series A because you closed 26% of a
    /// feature list.
    case customers(Double)
}

struct PaymentMilestone: Identifiable {
    let id: Int
    let trigger: PaymentTrigger
    /// Share of contract value released, before retainage. For financing
    /// rounds this is the size of the round instead.
    let share: Double
    /// Fraction of the company sold. Zero for earned payments; non-zero
    /// makes this a funding round, which adds cash without adding revenue
    /// and costs a slice of the exit.
    let dilution: Double
    /// Shown when the money lands.
    let name: String

    init(id: Int, trigger: PaymentTrigger, share: Double,
         dilution: Double = 0, name: String = "") {
        self.id = id
        self.trigger = trigger
        self.share = share
        self.dilution = dilution
        self.name = name
    }

    var isFinancing: Bool { dilution > 0 }
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
    let scenario: ScenarioKind
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

    /// The market this scenario sells into. Nil for scenarios that have no
    /// customers - a building has a client, not a user base.
    let growth: GrowthSpec?
    /// Whether work consumes a physical, lead-timed supply. False for
    /// software: engineers are the constraint, not a warehouse. Turning
    /// the system off rather than relabelling it is the honest answer, and
    /// proves a scenario can disable a system and not just rename it.
    let usesSupplyChain: Bool
    /// The stream whose completion puts the product in front of customers.
    /// Nil when the scenario has no launch concept.
    let launchStreamID: String?

    /// The incidents this scenario can throw at you.
    var incidentDeck: [SimEventKind] { SimEventKind.deck(for: scenario) }

    var counterpartyName: String { clientPersona.name(in: scenario) }

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
        PaymentMilestone(id: 0, trigger: .progress(6), share: 0.14),
        PaymentMilestone(id: 1, trigger: .progress(26), share: 0.18),
        PaymentMilestone(id: 2, trigger: .progress(48), share: 0.18),
        PaymentMilestone(id: 3, trigger: .progress(72), share: 0.20),
        PaymentMilestone(id: 4, trigger: .progress(100), share: 0.18),
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
            scenario: .construction,
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
            marketVolatility: Double.random(in: 0.012...0.026, using: &rng) * difficulty.marketVolatilityFactor,
            growth: nil,
            usesSupplyChain: true,
            launchStreamID: nil
        )
    }

    // MARK: Startup scenario

    /// Restructured around the launch, not around finishing a feature
    /// list. Discovery, platform and MVP are only 30% of the work - the
    /// product goes live a third of the way in, and the remaining
    /// two-thirds is spent growing a business that already exists.
    ///
    /// That ordering is the point. Shipping the MVP early starts word of
    /// mouth compounding sooner; polishing everything before launch is
    /// the classic way to run out of money with a beautiful product and
    /// no customers.
    ///
    /// Nothing here consumes a lead-timed supply. For software the
    /// constraint is people, so the supply chain is switched off entirely
    /// rather than dressed up as "provisioning capacity".
    static let startupStreams: [WorkStreamSpec] = [
        WorkStreamSpec(id: "discovery", title: String(localized: "Discovery", comment: "Startup work stream name"),
                       imageName: "Discovery.png", units: 180, optimalCrew: 6, startThreshold: 0,
                       materialCostPerUnit: 0, materialUnitsPerWorkUnit: 0, baseLeadTimeDays: 0),
        WorkStreamSpec(id: "platform", title: String(localized: "Core platform", comment: "Startup work stream name"),
                       imageName: "Platform.png", units: 300, optimalCrew: 10, startThreshold: 3,
                       materialCostPerUnit: 0, materialUnitsPerWorkUnit: 0, baseLeadTimeDays: 0),
        WorkStreamSpec(id: "mvp", title: String(localized: "MVP & launch", comment: "Startup work stream name"),
                       imageName: "Launch.png", units: 220, optimalCrew: 8, startThreshold: 9,
                       materialCostPerUnit: 0, materialUnitsPerWorkUnit: 0, baseLeadTimeDays: 0),
        WorkStreamSpec(id: "features", title: String(localized: "Feature depth", comment: "Startup work stream name"),
                       imageName: "Features.png", units: 1_100, optimalCrew: 30, startThreshold: 20,
                       materialCostPerUnit: 0, materialUnitsPerWorkUnit: 0, baseLeadTimeDays: 0),
        WorkStreamSpec(id: "payments", title: String(localized: "Payments & billing", comment: "Startup work stream name"),
                       imageName: "Payments.png", units: 700, optimalCrew: 20, startThreshold: 42,
                       materialCostPerUnit: 0, materialUnitsPerWorkUnit: 0, baseLeadTimeDays: 0),
        WorkStreamSpec(id: "scale", title: String(localized: "Scale & reliability", comment: "Startup work stream name"),
                       imageName: "API.png", units: 1_000, optimalCrew: 26, startThreshold: 62,
                       materialCostPerUnit: 0, materialUnitsPerWorkUnit: 0, baseLeadTimeDays: 0),
    ]

    /// Money in is a seed already banked plus two rounds gated on
    /// customers - because that is what investors actually price. Each
    /// round buys runway and sells a slice of the exit, so taking one is
    /// a real decision rather than a reward for progress.
    static let startupRounds: [PaymentMilestone] = [
        PaymentMilestone(id: 0, trigger: .customers(60), share: 0.34, dilution: 0.20,
                         name: String(localized: "Series A", comment: "Funding round name")),
        PaymentMilestone(id: 1, trigger: .customers(650), share: 0.62, dilution: 0.16,
                         name: String(localized: "Series B", comment: "Funding round name")),
    ]

    /// A seed-stage company: money in the bank, a product that does not
    /// exist yet, and a runway.
    ///
    /// `contractValue` here is the capital pool the rounds are sized
    /// against, not a payout. What the run is actually worth is decided at
    /// the exit by ARR, growth rate, tech debt and how much of the company
    /// you still own.
    static func startup(
        difficulty: Difficulty = .standard,
        persona: ClientPersona? = nil,
        seed: UInt64 = UInt64.random(in: 0..<UInt64.max)
    ) -> ProjectBrief {
        var rng = SeededGenerator(seed: seed)
        let chosenPersona = persona ?? ClientPersona.allCases.randomElement(using: &rng)!

        return ProjectBrief(
            scenario: .startup,
            scenarioName: String(localized: "Seed-stage product", comment: "Scenario name"),
            clientPersona: chosenPersona,
            difficulty: difficulty,
            seed: seed,
            contractValue: 7_400_000,
            startingCash: (1_500_000 * difficulty.startingCashFactor).rounded(),
            creditLimit: (240_000 * difficulty.creditLimitFactor).rounded(),
            // Venture debt is dearer than a construction credit line.
            dailyInterestRate: 0.00075,
            deadlineDays: (150 * difficulty.deadlineFactor).rounded(),
            // Past the runway you are on bridge financing, which is
            // expensive and gets worse the longer it goes on.
            baseLatePenaltyPerDay: 5_200,
            retainageRate: 0,
            advanceRate: 0,
            milestones: startupRounds,
            streams: startupStreams,
            // Engineers price harder than trades, and more variably.
            labourMarketFactor: Double.random(in: 0.95...1.35, using: &rng),
            marketVolatility: Double.random(in: 0.014...0.030, using: &rng) * difficulty.marketVolatilityFactor,
            growth: .seedStageSaaS,
            usesSupplyChain: false,
            launchStreamID: "mvp"
        )
    }

    /// One entry point for both scenarios, so callers - the engine, the
    /// picker, the tests - never have to switch on the kind themselves.
    static func make(
        scenario: ScenarioKind,
        difficulty: Difficulty = .standard,
        persona: ClientPersona? = nil,
        seed: UInt64 = UInt64.random(in: 0..<UInt64.max)
    ) -> ProjectBrief {
        switch scenario {
        case .construction: return .construction(difficulty: difficulty, persona: persona, seed: seed)
        case .startup:      return .startup(difficulty: difficulty, persona: persona, seed: seed)
        }
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

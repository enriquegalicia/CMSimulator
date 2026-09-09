//
//  Worker.swift
//  CMSimulator
//
//  Phase 2 of the rebuild: replaces the old "headcount Int + package-level
//  cost/rate multipliers" model with an actual roster of individual people.
//
//  The old model had two fatal properties. First, hiring multiplied the
//  *package's* rate, so hiring a meticulous worker slowed down everyone
//  already on the crew. Second - and this is what made the whole game
//  flat - headcount cancelled out of total cost exactly: the tick loop
//  earned `rate * crew * step` and charged `cost * crew * step`, so
//  finishing a package always cost `units * cost / rate` no matter how
//  many people worked it. Fifty workers finished fifty times faster for
//  the same money.
//
//  Here a worker is a person who costs a wage every single day whether or
//  not they produce anything, who starts slow, who gets better at the job
//  they stay on, and who can walk out. That is where the cause and effect
//  of hiring and firing actually comes from.
//

import Foundation

// MARK: - Tuning

enum WorkerTuning {
    /// Days for a new hire to reach full speed.
    static let onboardingDays: Double = 6
    /// Output multiplier on day one of a new hire, ramping to 1.0.
    static let greenOutputFloor: Double = 0.25
    /// Days on the same package to reach full mastery.
    static let masteryDays: Double = 45
    /// A fully-experienced worker produces this multiple of a day-one
    /// worker of the same skill. The single most important number in the
    /// game: it is what makes firing a veteran expensive and what gives
    /// Training something to compound.
    static let veteranMultiplier: Double = 2.6
    /// Each worker still onboarding drags the rest of their crew by this
    /// much (mentoring cost). Brooks's law, dialled up to be legible.
    static let mentoringDragPerGreenHire: Double = 0.15
    static let minimumCrewDragMultiplier: Double = 0.4
    /// Signing cost as a multiple of daily wage - recruiting, induction,
    /// PPE, the works. Paid from cash the instant you hire.
    static let signingCostInWageDays: Double = 3
    /// Severance as a multiple of daily wage. Deliberately higher than the
    /// signing cost: churn should never be a cheap way out of a mistake.
    static let severanceInWageDays: Double = 10
    /// Morale below this and the worker starts rolling to quit.
    static let unhappyMoraleThreshold: Double = 0.35
    /// Daily probability of quitting at zero morale, scaling to 0 at the
    /// unhappy threshold.
    static let maxDailyQuitChance: Double = 0.06
    /// Morale recovered per day at normal hours.
    static let moraleRecoveryPerDay: Double = 0.035
    /// Morale burned per day of full overtime.
    static let moraleBurnPerOvertimeDay: Double = 0.11
}

// MARK: - Archetypes

/// A worker's disposition. Unlike the old Candidate archetypes - which
/// biased four multipliers inside a band so narrow the choice washed out -
/// these change genuinely different things: raw speed, defect generation,
/// wage, morale resilience and how fast they learn.
enum WorkerArchetype: String, CaseIterable {
    case veteran
    case gunner
    case apprentice
    case allRounder
    case safetyLead
    case specialist

    var traitName: String {
        switch self {
        case .veteran: return String(localized: "Old hand", comment: "Worker archetype name")
        case .gunner: return String(localized: "Fast, cuts corners", comment: "Worker archetype name")
        case .apprentice: return String(localized: "Apprentice", comment: "Worker archetype name")
        case .allRounder: return String(localized: "Steady all-rounder", comment: "Worker archetype name")
        case .safetyLead: return String(localized: "Safety-first", comment: "Worker archetype name")
        case .specialist: return String(localized: "Specialist", comment: "Worker archetype name")
        }
    }

    var blurb: String {
        switch self {
        case .veteran: return String(localized: "Starts near full speed and rarely leaves. Expensive.", comment: "Worker archetype description")
        case .gunner: return String(localized: "Quick output, but leaves defects behind and burns out.", comment: "Worker archetype description")
        case .apprentice: return String(localized: "Cheap and slow now. Learns faster than anyone.", comment: "Worker archetype description")
        case .allRounder: return String(localized: "No weaknesses, no edge. Reliable middle.", comment: "Worker archetype description")
        case .safetyLead: return String(localized: "Lowers incident risk for the whole crew.", comment: "Worker archetype description")
        case .specialist: return String(localized: "High output and clean work. Demands a high wage.", comment: "Worker archetype description")
        }
    }

    /// Raw units per day before ramp, experience and morale.
    var skillRange: ClosedRange<Double> {
        switch self {
        case .veteran: return 1.05...1.25
        case .gunner: return 1.25...1.50
        case .apprentice: return 0.55...0.75
        case .allRounder: return 0.90...1.05
        case .safetyLead: return 0.80...0.95
        case .specialist: return 1.20...1.40
        }
    }

    /// Daily wage band.
    var wageRange: ClosedRange<Double> {
        switch self {
        case .veteran: return 720...860
        case .gunner: return 520...620
        case .apprentice: return 240...320
        case .allRounder: return 470...560
        case .safetyLead: return 540...640
        case .specialist: return 820...980
        }
    }

    /// Defects generated per unit of work produced. Feeds Quality's
    /// defect-debt system - a gunner builds fast and leaves a bill.
    var defectRate: Double {
        switch self {
        case .veteran: return 0.008
        case .gunner: return 0.038
        case .apprentice: return 0.027
        case .allRounder: return 0.015
        case .safetyLead: return 0.011
        case .specialist: return 0.006
        }
    }

    /// Multiplier on how fast this worker accumulates experience.
    var learningRate: Double {
        switch self {
        case .veteran: return 0.7
        case .gunner: return 0.9
        case .apprentice: return 1.9
        case .allRounder: return 1.15
        case .safetyLead: return 1.0
        case .specialist: return 0.85
        }
    }

    /// Multiplier on morale loss. Below 1 means resilient.
    var burnoutSensitivity: Double {
        switch self {
        case .veteran: return 0.7
        case .gunner: return 1.6
        case .apprentice: return 1.25
        case .allRounder: return 1.0
        case .safetyLead: return 0.85
        case .specialist: return 1.15
        }
    }

    /// How much this worker's presence reduces incident probability for
    /// their crew. Only the safety lead moves this meaningfully.
    var safetyContribution: Double {
        switch self {
        case .safetyLead: return 0.18
        case .veteran: return 0.07
        case .specialist: return 0.03
        case .allRounder: return 0.02
        case .apprentice: return 0
        case .gunner: return -0.05
        }
    }

    /// Head start on experience at hire - a veteran already knows the job.
    var startingExperience: Double {
        switch self {
        case .veteran: return 0.55
        case .specialist: return 0.35
        case .allRounder: return 0.15
        case .safetyLead: return 0.20
        case .gunner: return 0.10
        case .apprentice: return 0
        }
    }
}

// MARK: - Worker

struct Worker: Identifiable {
    let id = UUID()
    let name: String
    let archetype: WorkerArchetype
    /// Which work package this worker is assigned to.
    var packageID: WorkPackage.ID

    var skill: Double
    var dailyWage: Double
    /// 0...1, drives the veteran multiplier. Earned by staying on the job.
    var experience: Double
    /// 0...1. Burns with overtime, recovers with normal hours.
    var morale: Double = 0.8
    /// 0...1, ramps over `onboardingDays`. New hires are a drag before
    /// they are an asset.
    var rampProgress: Double = 0
    /// Days remaining in a training course. A worker in training produces
    /// nothing but is still paid - that is Training's real cost.
    var trainingDaysRemaining: Double = 0
    /// Set once a worker has completed a course, so the UI can show it.
    var coursesCompleted: Int = 0
    /// Banked at enrolment and applied when the course finishes, so the
    /// payoff is fixed by the Training level you paid for rather than by
    /// whatever the level happens to be on the day they get back.
    var pendingSkillGain: Double = 0
    var pendingExperienceGain: Double = 0

    init(name: String, archetype: WorkerArchetype, packageID: WorkPackage.ID, marketWageFactor: Double = 1.0) {
        self.name = name
        self.archetype = archetype
        self.packageID = packageID
        self.skill = .random(in: archetype.skillRange)
        self.dailyWage = (Double.random(in: archetype.wageRange) * marketWageFactor).rounded()
        self.experience = archetype.startingExperience
    }

    var isOnboarding: Bool { rampProgress < 1 }
    var isInTraining: Bool { trainingDaysRemaining > 0 }

    var signingCost: Double { dailyWage * WorkerTuning.signingCostInWageDays }
    var severanceCost: Double { dailyWage * WorkerTuning.severanceInWageDays }

    /// Ramp multiplier: 0.25 on day one climbing to 1.0 over the
    /// onboarding period.
    var rampMultiplier: Double {
        WorkerTuning.greenOutputFloor + (1 - WorkerTuning.greenOutputFloor) * rampProgress
    }

    /// Experience multiplier: 1.0 green, up to `veteranMultiplier` mastered.
    var experienceMultiplier: Double {
        1 + (WorkerTuning.veteranMultiplier - 1) * experience
    }

    /// Morale multiplier, 0.6 at rock bottom to 1.1 fully motivated.
    var moraleMultiplier: Double {
        0.6 + 0.5 * min(max(morale, 0), 1)
    }

    /// Units per day this worker contributes, before crew-level effects
    /// (mentoring drag, congestion, overtime).
    var effectiveOutput: Double {
        guard !isInTraining else { return 0 }
        return skill * rampMultiplier * experienceMultiplier * moraleMultiplier
    }

    /// Defects generated per unit produced. Rushing and low morale make
    /// everyone sloppier, not just the gunner.
    func defectRate(overtime: Double) -> Double {
        let moralePenalty = 1 + (1 - min(max(morale, 0), 1)) * 0.8
        let overtimePenalty = 1 + overtime * 0.9
        let greenPenalty = isOnboarding ? 1.5 : 1.0
        return archetype.defectRate * moralePenalty * overtimePenalty * greenPenalty
    }

    /// Advances ramp, experience and morale by `days`.
    mutating func advance(days: Double, overtime: Double, isWorking: Bool) {
        if trainingDaysRemaining > 0 {
            trainingDaysRemaining = max(0, trainingDaysRemaining - days)
            // Training is restful, and people like being invested in.
            morale = min(1, morale + WorkerTuning.moraleRecoveryPerDay * 1.5 * days)
            if trainingDaysRemaining == 0 {
                skill += pendingSkillGain
                experience = min(1, experience + pendingExperienceGain)
                pendingSkillGain = 0
                pendingExperienceGain = 0
                coursesCompleted += 1
            }
            return
        }
        if rampProgress < 1 {
            rampProgress = min(1, rampProgress + days / WorkerTuning.onboardingDays)
        }
        if isWorking {
            experience = min(1, experience + (days / WorkerTuning.masteryDays) * archetype.learningRate)
        }
        let burn = WorkerTuning.moraleBurnPerOvertimeDay * overtime * archetype.burnoutSensitivity * days
        let recovery = WorkerTuning.moraleRecoveryPerDay * (1 - overtime) * days
        morale = min(1, max(0, morale + recovery - burn))
    }

    /// Probability this worker quits over `days`, given company morale
    /// pressure. Returns 0 for anyone above the unhappy threshold, so a
    /// well-run site never loses people at random.
    func quitProbability(over days: Double) -> Double {
        guard !isInTraining else { return 0 }
        let t = WorkerTuning.unhappyMoraleThreshold
        guard morale < t else { return 0 }
        let severity = (t - morale) / t
        let dailyChance = WorkerTuning.maxDailyQuitChance * severity
        return 1 - pow(1 - dailyChance, days)
    }
}

// MARK: - Localized name pools

/// Name lists are localized as single comma-separated strings rather than
/// one key per name, so a translator swaps in a whole culturally-natural
/// set in one edit instead of transliterating dozens of entries.
enum NamePool {
    /// Tolerates stray spaces and empty entries, so a mistranslated list
    /// can never produce a blank name or an empty pool.
    static func split(_ list: String) -> [String] {
        let parts = list.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? ["Álex"] : parts
    }
}

// MARK: - Candidate pool

/// One applicant on offer. Wraps a fully-formed Worker so what you see in
/// the picker is exactly what you get - no hidden reroll on accept.
struct Candidate: Identifiable {
    var id: UUID { worker.id }
    let worker: Worker

    var name: String { worker.name }
    var archetype: WorkerArchetype { worker.archetype }
}

/// Drives the candidate-picker sheet.
struct HiringRequest: Identifiable {
    let id: WorkPackage.ID
    let packageTitle: String
    let candidates: [Candidate]
    /// Tightness of the labour market when this pool was drawn, so the
    /// sheet can tell the player why everyone is suddenly expensive.
    let marketWageFactor: Double
}

extension Candidate {
    /// Name pools are localized as one comma-separated list each, so a
    /// translator swaps in names that read naturally in their language
    /// rather than transliterating twenty separate keys. Each list is
    /// mostly local with a few names from elsewhere, which is what a real
    /// crew on this kind of job looks like - so an English player meets a
    /// mostly English crew and a Spanish player a mostly Spanish one.
    private static var firstNames: [String] {
        NamePool.split(String(localized: "James,Emily,Owen,Grace,Daniel,Hannah,Marcus,Chloe,Thomas,Olivia,Nathan,Ruby,Callum,Freya,Ethan,Alice,Diego,Priya,Nadia,Sean",
                          comment: "Comma-separated pool of worker first names. Replace with given names that read naturally in your language - do not translate these literally."))
    }

    private static var lastNames: [String] {
        NamePool.split(String(localized: "Webb,Bennett,Clarke,Doyle,Whitfield,Hargreaves,Ellis,Mercer,Ashton,Cole,Radcliffe,Naylor,Prescott,Sutton,Okafor,Patel,Kowalski,Novak,Ferreira,Reyes",
                          comment: "Comma-separated pool of worker surnames. Replace with surnames that read naturally in your language - do not translate these literally."))
    }

    static func randomName() -> String {
        "\(firstNames.randomElement()!) \(lastNames.randomElement()!)"
    }

    /// Three distinct archetypes, so every hire is a real choice rather
    /// than three near-clones. `marketWageFactor` comes from the labour
    /// market: in a tight market the same people cost more.
    static func pool(for packageID: WorkPackage.ID, marketWageFactor: Double, poolQuality: Double) -> [Candidate] {
        // Reputation gates the top of the pool: fire people often enough
        // and the good ones stop applying.
        var available = WorkerArchetype.allCases
        if poolQuality < 0.5 {
            available.removeAll { $0 == .specialist || $0 == .veteran }
        } else if poolQuality < 0.75 {
            available.removeAll { $0 == .specialist }
        }
        let picked = available.shuffled().prefix(3)
        return picked.map { archetype in
            Candidate(worker: Worker(
                name: randomName(),
                archetype: archetype,
                packageID: packageID,
                marketWageFactor: marketWageFactor
            ))
        }
    }
}

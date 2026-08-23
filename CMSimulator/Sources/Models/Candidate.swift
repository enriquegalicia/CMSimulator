//
//  Candidate.swift
//  CMSimulator
//
//  Turns hiring from a blind +1 button into a real decision: three named
//  candidates with a legible tradeoff, drawn from a small set of archetypes.
//  Factors are multipliers applied the same way the old hireWorker's single
//  random nudge was (cost 0.99...1.05, rate 0.95...1.01, gauges 0.90...0.99)
//  - each archetype just biases where in that range a hire lands, and on
//  which axis, instead of picking blind every time.
//

import Foundation

struct Candidate: Identifiable {
    let id = UUID()
    let name: String
    let trait: String
    let costFactor: Double
    let rateFactor: Double
    let riskFactor: Double
    let qualityFactor: Double
}

/// Drives the candidate-picker sheet: which package the hire is for, and
/// the three candidates on offer for it.
struct HiringRequest: Identifiable {
    let id: WorkPackage.ID
    let packageTitle: String
    let candidates: [Candidate]
}

private struct CandidateArchetype {
    let trait: String
    let costRange: ClosedRange<Double>
    let rateRange: ClosedRange<Double>
    let riskRange: ClosedRange<Double>
    let qualityRange: ClosedRange<Double>
}

extension Candidate {
    private static let names = [
        "Jordan Reyes", "Priya Shah", "Marcus Webb", "Elena Novak", "Sam Okafor",
        "Diego Marín", "Ava Chen", "Lucas Ferreira", "Nadia Haddad", "Ravi Patel",
        "Grace Kim", "Owen Malone",
    ]

    private static let archetypes = [
        CandidateArchetype(
            trait: "Fast, but cuts corners",
            costRange: 1.02...1.05, rateRange: 1.00...1.01,
            riskRange: 0.90...0.94, qualityRange: 0.90...0.94
        ),
        CandidateArchetype(
            trait: "Meticulous",
            costRange: 1.01...1.05, rateRange: 0.95...0.97,
            riskRange: 0.95...0.99, qualityRange: 0.97...0.99
        ),
        CandidateArchetype(
            trait: "Budget hire",
            costRange: 0.99...1.01, rateRange: 0.95...0.98,
            riskRange: 0.92...0.96, qualityRange: 0.92...0.96
        ),
        CandidateArchetype(
            trait: "Steady all-rounder",
            costRange: 1.00...1.03, rateRange: 0.97...1.00,
            riskRange: 0.94...0.97, qualityRange: 0.94...0.97
        ),
        CandidateArchetype(
            trait: "Safety-first",
            costRange: 1.01...1.04, rateRange: 0.95...0.98,
            riskRange: 0.97...0.99, qualityRange: 0.92...0.96
        ),
    ]

    /// Three distinct archetypes paired with three distinct names, so every
    /// hiring decision offers a real choice rather than three near-clones.
    static func randomPool() -> [Candidate] {
        let pickedArchetypes = archetypes.shuffled().prefix(3)
        let pickedNames = names.shuffled().prefix(3)
        return zip(pickedArchetypes, pickedNames).map { archetype, name in
            Candidate(
                name: name,
                trait: archetype.trait,
                costFactor: .random(in: archetype.costRange),
                rateFactor: .random(in: archetype.rateRange),
                riskFactor: .random(in: archetype.riskRange),
                qualityFactor: .random(in: archetype.qualityRange)
            )
        }
    }
}

//
//  BoosterEffect.swift
//  CMSimulator
//
//  Data-driven replacement for the original's twelve near-identical
//  f01...f11 Objective-C helper methods. Each booster's "affects" text
//  (already written by the original author, shown right on its card)
//  is the design intent; this table implements exactly that intent in
//  one generic, reusable evaluator instead of one hand-tuned method
//  per booster.
//
//  Buying a unit nudges things the "good" way; selling nudges them back.
//  All nudges are randomized within a small band and clamped, mirroring
//  the original's own bounded, randomized cross-effects.
//

import Foundation

enum EffectTarget {
    case workPackageRate
    case workPackageCost
    case workPackageStart
    case riskGauge
    case qualityGauge
    case boosterCost(BoosterKind)
}

struct BoosterEffect {
    let target: EffectTarget
    /// Multiplier band applied on a *buy*. A sell applies the reciprocal band.
    let buyRange: ClosedRange<Double>

    static let table: [BoosterKind: [BoosterEffect]] = [
        .planning: [
            BoosterEffect(target: .workPackageStart, buyRange: 0.94...0.99),   // unlocks work sooner
            BoosterEffect(target: .workPackageRate, buyRange: 1.00...1.03),
            BoosterEffect(target: .qualityGauge, buyRange: 1.00...1.02),
            BoosterEffect(target: .boosterCost(.communications), buyRange: 0.98...1.00),
        ],
        .procurement: [
            BoosterEffect(target: .workPackageCost, buyRange: 0.97...0.995),
            BoosterEffect(target: .boosterCost(.planning), buyRange: 0.98...1.00),
            BoosterEffect(target: .boosterCost(.risk), buyRange: 0.98...1.00),
        ],
        .risk: [
            BoosterEffect(target: .workPackageCost, buyRange: 1.00...1.03),    // riskier, costs more...
            BoosterEffect(target: .workPackageRate, buyRange: 0.98...1.00),
            BoosterEffect(target: .riskGauge, buyRange: 1.00...1.02),          // ...but improves the risk score
            BoosterEffect(target: .boosterCost(.planning), buyRange: 0.98...1.00),
            BoosterEffect(target: .boosterCost(.communications), buyRange: 0.98...1.00),
        ],
        .communications: [
            BoosterEffect(target: .workPackageRate, buyRange: 1.00...1.03),
            BoosterEffect(target: .boosterCost(.procurement), buyRange: 0.98...1.00),
            BoosterEffect(target: .boosterCost(.training), buyRange: 0.98...1.00),
        ],
        .training: [
            BoosterEffect(target: .workPackageCost, buyRange: 0.97...0.995),
            BoosterEffect(target: .qualityGauge, buyRange: 1.00...1.02),
            BoosterEffect(target: .riskGauge, buyRange: 1.00...1.02),
        ],
        .quality: [
            BoosterEffect(target: .workPackageRate, buyRange: 1.00...1.03),
            BoosterEffect(target: .qualityGauge, buyRange: 1.00...1.02),
            BoosterEffect(target: .boosterCost(.training), buyRange: 0.98...1.00),
            BoosterEffect(target: .boosterCost(.procurement), buyRange: 0.98...1.00),
        ],
    ]
}

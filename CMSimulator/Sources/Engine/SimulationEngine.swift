//
//  SimulationEngine.swift
//  CMSimulator
//
//  The whole game loop, ported from ViewController.m's play/pause/
//  fastforward timers and progress/progress2 methods. One engine owns
//  every work package and booster and is observed directly by the views.
//

import Foundation
import Combine

enum SimSpeed {
    case paused, normal, fast

    var tickInterval: TimeInterval { 0.1 }
    /// Fraction of a "day" simulated per tick - matches the original's
    /// fdias += .01 (normal) / += .1 (fast forward).
    var dayStep: Double {
        switch self {
        case .paused: return 0
        case .normal: return 0.01
        case .fast: return 0.1
        }
    }
}

@MainActor
final class SimulationEngine: ObservableObject {

    @Published private(set) var workPackages: [WorkPackage]
    @Published private(set) var boosters: [Booster]
    @Published private(set) var riskGauge: Double = 1.0
    @Published private(set) var qualityGauge: Double = 1.0
    @Published private(set) var totalCost: Double = 0
    @Published private(set) var totalDays: Int = 0
    @Published private(set) var totalHours: Int = 0
    @Published private(set) var totalProgress: Double = 0
    @Published private(set) var speed: SimSpeed = .paused
    @Published private(set) var isComplete: Bool = false

    private var fractionalDays: Double = 0
    private var timerCancellable: AnyCancellable?

    init() {
        workPackages = [
            WorkPackage(id: "design", title: "Design", imageName: "Design.jpeg", initialCost: 700, units: 48, initialRate: 1, startThreshold: 0),
            WorkPackage(id: "structure", title: "Structure", imageName: "Structure.jpeg", initialCost: 900, units: 48, initialRate: 1, startThreshold: 20),
            WorkPackage(id: "engineering", title: "Engineering", imageName: "Engineering.jpeg", initialCost: 1200, units: 62, initialRate: 1, startThreshold: 30),
            WorkPackage(id: "construction", title: "Construction", imageName: "Construction.jpeg", initialCost: 2500, units: 264, initialRate: 1, startThreshold: 50),
            WorkPackage(id: "ihs", title: "IHS & IAA", imageName: "IHS.jpeg", initialCost: 1800, units: 214, initialRate: 1, startThreshold: 55),
            WorkPackage(id: "ies", title: "IES & IEL", imageName: "IES.jpeg", initialCost: 1600, units: 364, initialRate: 1, startThreshold: 60),
        ]
        workPackages[0].isUnlocked = true

        boosters = [
            Booster(kind: .planning, imageName: "Planning.jpeg", initialCost: 600, startThreshold: 0, affects: "Labor rates, starts, quality and communications"),
            Booster(kind: .procurement, imageName: "Procurement.png", initialCost: 800, startThreshold: 15, affects: "Resource cost, support costs, planning and risk"),
            Booster(kind: .risk, imageName: "Risk.jpeg", initialCost: 1000, startThreshold: 35, affects: "Resource cost, labor rates, planning and communications"),
            Booster(kind: .communications, imageName: "Communications.jpeg", initialCost: 600, startThreshold: 45, affects: "Labor rates, procurement and training"),
            Booster(kind: .training, imageName: "Training.jpeg", initialCost: 1500, startThreshold: 50, affects: "Cumulative labor rates, costs, quality and risk"),
            Booster(kind: .quality, imageName: "Quality.jpeg", initialCost: 800, startThreshold: 25, affects: "Resource cost, labor rates, training and procurement"),
        ]
        boosters[0].isUnlocked = true
    }

    // MARK: - Transport controls

    func play() { setSpeed(.normal) }
    func fastForward() { setSpeed(.fast) }
    func pause() { setSpeed(.paused) }

    private func setSpeed(_ newSpeed: SimSpeed) {
        speed = newSpeed
        timerCancellable?.cancel()
        guard newSpeed != .paused, !isComplete else { return }
        timerCancellable = Timer.publish(every: newSpeed.tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let step = speed.dayStep
        guard step > 0 else { return }

        fractionalDays += step
        totalDays = Int(fractionalDays)
        totalHours = Int((fractionalDays - Double(totalDays)) * 8)

        for i in workPackages.indices {
            guard workPackages[i].isUnlocked else { continue }
            let earnedThisTick = workPackages[i].rate * step
            workPackages[i].unitsCompleted += earnedThisTick
            workPackages[i].cumulativeCost += workPackages[i].cost * step
        }

        recomputeTotals()
        updateUnlocks()

        if totalProgress >= 100, !isComplete {
            isComplete = true
            setSpeed(.paused)
        }
    }

    private func recomputeTotals() {
        totalCost = workPackages.reduce(0) { $0 + $1.cumulativeCost } + boosters.reduce(0) { $0 + $1.totalSpent }

        let totalUnits = workPackages.reduce(0) { $0 + $1.units }
        guard totalUnits > 0 else { totalProgress = 0; return }
        let weighted = workPackages.reduce(0.0) { $0 + ($1.units / totalUnits) * $1.progress }
        totalProgress = weighted * 100
    }

    private func updateUnlocks() {
        for i in workPackages.indices where !workPackages[i].isUnlocked {
            if totalProgress >= workPackages[i].startThreshold {
                workPackages[i].isUnlocked = true
            }
        }
        for i in boosters.indices where !boosters[i].isUnlocked {
            if totalProgress >= boosters[i].startThreshold {
                boosters[i].isUnlocked = true
            }
        }
    }

    // MARK: - Buying / selling boosters (ported from Recurso/Potenciadores suma/resta + RPLUSA/RMINUSA)

    func buyBooster(_ kind: BoosterKind) {
        guard let idx = boosters.firstIndex(where: { $0.id == kind }), boosters[idx].isUnlocked else { return }
        let spend = boosters[idx].cost
        boosters[idx].purchasedCount += 1
        boosters[idx].totalSpent += spend
        boosters[idx].cumulativeCost += spend
        boosters[idx].cost *= Double.random(in: 0.98...1.05)
        applyEffects(for: kind, buying: true)
        recomputeTotals()
    }

    func sellBooster(_ kind: BoosterKind) {
        guard let idx = boosters.firstIndex(where: { $0.id == kind }), boosters[idx].purchasedCount > 0 else { return }
        boosters[idx].purchasedCount -= 1
        let refund = boosters[idx].cost
        boosters[idx].totalSpent = max(0, boosters[idx].totalSpent - refund)
        boosters[idx].cost *= Double.random(in: 0.95...1.02)
        applyEffects(for: kind, buying: false)
        recomputeTotals()
    }

    private func applyEffects(for kind: BoosterKind, buying: Bool) {
        guard let effects = BoosterEffect.table[kind] else { return }
        for effect in effects {
            let factor = buying
                ? Double.random(in: effect.buyRange)
                : 1.0 / Double.random(in: effect.buyRange)

            switch effect.target {
            case .workPackageRate:
                for i in workPackages.indices {
                    workPackages[i].rate *= factor
                    workPackages[i].clampRate()
                }
            case .workPackageCost:
                for i in workPackages.indices {
                    workPackages[i].cost *= factor
                    workPackages[i].clampCost()
                }
            case .workPackageStart:
                for i in workPackages.indices {
                    workPackages[i].startThreshold = min(max(workPackages[i].startThreshold * factor, 0), 100)
                }
            case .riskGauge:
                riskGauge = min(max(riskGauge * factor, 0.5), 1.5)
            case .qualityGauge:
                qualityGauge = min(max(qualityGauge * factor, 0.5), 1.5)
            case .boosterCost(let target):
                if let i = boosters.firstIndex(where: { $0.id == target }) {
                    boosters[i].cost = min(max(boosters[i].cost * factor, boosters[i].initialCost / 2), boosters[i].initialCost * 3)
                }
            }
        }
    }

    // MARK: - Result

    var finalCost: Double { totalCost }
    var finalDays: Double { fractionalDays }
}

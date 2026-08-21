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
    case paused, normal, fast, superFast

    var tickInterval: TimeInterval { 0.1 }
    /// Fraction of a "day" simulated per tick - matches the original's
    /// fdias += .01 (normal) / += .1 (fast forward); superFast doubles
    /// fast-forward again for a genuinely-faster third gear.
    var dayStep: Double {
        switch self {
        case .paused: return 0
        case .normal: return 0.01
        case .fast: return 0.1
        case .superFast: return 0.2
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
    /// Set when a disaster/clash event fires; the view shows a banner and
    /// clears it. Finishes the original's abandoned Eventos/eventoriesgo/
    /// eventocalidad mechanic - see SimEvent.swift.
    @Published private(set) var activeEvent: SimEvent?

    private var fractionalDays: Double = 0
    private var lastEventDay: Double = -Double.greatestFiniteMagnitude
    private var disasterCost: Double = 0
    private var timerCancellable: AnyCancellable?

    /// Gauges below this (of the 0.5...1.5 range) count as "in the red" -
    /// matches GaugeView's own red cutoff.
    private let redZoneThreshold = 0.9
    /// Roughly this fraction of the time a gauge spends in the red zone
    /// produces an event within a simulated day - independent of how fast
    /// the player is running the clock.
    private let dailyEventChance = 0.4
    /// Minimum simulated days between events so they can't stack up.
    private let eventCooldownDays = 3.0

    init() {
        // Units and thresholds are retuned from the original's (which
        // summed to ~1000 units with thresholds up to 60% and no headcount
        // scaling - a solo hire took literal tens of minutes to finish one
        // discipline). Smaller totals plus headcount now actually scaling
        // speed together get a full run into a few minutes at Play, well
        // under a minute at Fast/Super-Fast - and later disciplines unlock
        // early enough to actually be seen and played with, not just
        // stared at behind a slow weighted average.
        workPackages = [
            WorkPackage(id: "design", title: "Design", imageName: "Design.jpeg", initialCost: 700, units: 6, initialRate: 1, startThreshold: 0),
            WorkPackage(id: "structure", title: "Structure", imageName: "Structure.jpeg", initialCost: 900, units: 6, initialRate: 1, startThreshold: 10),
            WorkPackage(id: "engineering", title: "Engineering", imageName: "Engineering.jpeg", initialCost: 1200, units: 8, initialRate: 1, startThreshold: 15),
            WorkPackage(id: "construction", title: "Construction", imageName: "Construction.jpeg", initialCost: 2500, units: 33, initialRate: 1, startThreshold: 25),
            WorkPackage(id: "ihs", title: "IHS & IAA", imageName: "IHS.jpeg", initialCost: 1800, units: 27, initialRate: 1, startThreshold: 30),
            WorkPackage(id: "ies", title: "IES & IEL", imageName: "IES.jpeg", initialCost: 1600, units: 46, initialRate: 1, startThreshold: 35),
        ]

        boosters = [
            Booster(kind: .planning, imageName: "Planning.jpeg", initialCost: 600, startThreshold: 0, affects: "Labor rates, starts, quality and communications"),
            Booster(kind: .procurement, imageName: "Procurement.png", initialCost: 800, startThreshold: 8, affects: "Resource cost, support costs, planning and risk"),
            Booster(kind: .quality, imageName: "Quality.jpeg", initialCost: 800, startThreshold: 12, affects: "Resource cost, labor rates, training and procurement"),
            Booster(kind: .risk, imageName: "Risk.jpeg", initialCost: 1000, startThreshold: 18, affects: "Resource cost, labor rates, planning and communications"),
            Booster(kind: .communications, imageName: "Communications.jpeg", initialCost: 600, startThreshold: 22, affects: "Labor rates, procurement and training"),
            Booster(kind: .training, imageName: "Training.jpeg", initialCost: 1500, startThreshold: 25, affects: "Cumulative labor rates, costs, quality and risk"),
        ]

        // Everything else is set - now it's safe to mutate self.
        workPackages[0].isUnlocked = true
        boosters[0].isUnlocked = true
    }

    // MARK: - Transport controls

    func play() { setSpeed(.normal) }
    func fastForward() { setSpeed(.fast) }
    func superFastForward() { setSpeed(.superFast) }
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
            // Mirrors the original: a discipline only advances - and only
            // costs money - once someone is actually hired onto it. Unlike
            // the original, headcount scales *how fast* too, not just
            // on/off, so hiring more people has a visible effect and isn't
            // identical to hiring just one.
            guard workPackages[i].isUnlocked, workPackages[i].headcount > 0 else { continue }
            guard workPackages[i].unitsCompleted < workPackages[i].units else { continue }
            let crew = Double(workPackages[i].headcount)
            let earnedThisTick = workPackages[i].rate * crew * step
            workPackages[i].unitsCompleted = min(workPackages[i].unitsCompleted + earnedThisTick, workPackages[i].units)
            workPackages[i].cumulativeCost += workPackages[i].cost * crew * step
        }

        recomputeTotals()
        updateUnlocks()
        checkForEvent(step: step)

        if totalProgress >= 100, !isComplete {
            isComplete = true
            setSpeed(.paused)
        }
    }

    private func checkForEvent(step: Double) {
        guard activeEvent == nil, fractionalDays - lastEventDay >= eventCooldownDays else { return }

        let riskInRedZone = riskGauge < redZoneThreshold
        let qualityInRedZone = qualityGauge < redZoneThreshold
        guard riskInRedZone || qualityInRedZone else { return }

        // Same probability-per-simulated-day regardless of playback speed:
        // superFast covers more days per tick, so it gets a proportionally
        // bigger per-tick roll, not a flat one - the expected time to an
        // event (in simulated days) stays the same whether you're at Play
        // or Super-Fast.
        let pTrigger = 1 - pow(1 - dailyEventChance, step)
        guard Double.random(in: 0...1) < pTrigger else { return }

        // If both gauges are in the red, whichever is worse decides which
        // *category* fires; the specific kind within that category is
        // random, so a bad risk streak might be a hurricane one time and
        // a site fire the next, each with its own cost/setback severity.
        let category: SimEventCategory = (riskGauge <= qualityGauge) ? .risk : .quality
        trigger(.random(for: category))
    }

    private func trigger(_ kind: SimEventKind) {
        lastEventDay = fractionalDays
        let extraCost = max(150, totalCost * Double.random(in: kind.costFractionRange))
        disasterCost += extraCost

        switch kind.category {
        case .risk:
            riskGauge = min(max(riskGauge * Double.random(in: 0.85...0.95), 0.5), 1.5)
        case .quality:
            qualityGauge = min(max(qualityGauge * Double.random(in: 0.85...0.95), 0.5), 1.5)
        }

        var message = kind.message
        var setback: Double = 0
        // Not every event costs physical progress - theft and change
        // orders are cost-only hits.
        if let setbackRange = kind.setbackRange,
           let idx = workPackages.indices
               .filter({ workPackages[$0].isUnlocked && workPackages[$0].unitsCompleted > 0 })
               .max(by: { workPackages[$0].unitsCompleted < workPackages[$1].unitsCompleted }) {
            setback = Double.random(in: setbackRange)
            workPackages[idx].unitsCompleted = max(0, workPackages[idx].unitsCompleted - setback)
            message += " \(workPackages[idx].title) lost some progress."
        }

        activeEvent = SimEvent(kind: kind, message: message, extraCost: extraCost, setbackUnits: setback)
        recomputeTotals()
    }

    func dismissEvent() {
        activeEvent = nil
    }

    private func recomputeTotals() {
        totalCost = workPackages.reduce(0) { $0 + $1.cumulativeCost } + boosters.reduce(0) { $0 + $1.totalSpent } + disasterCost

        // Weighted only across *unlocked* packages, not all six. Weighting
        // against every package's units regardless of lock state made
        // this a hard ceiling: Design alone (6 of 126 total units) could
        // never exceed ~4.8% progress even at 100% done, but Structure
        // needed 10% to unlock - mathematically unreachable, a permanent
        // soft-lock. Locked packages simply aren't "in scope" yet, so they
        // shouldn't count against the denominator until they unlock.
        let unlocked = workPackages.filter { $0.isUnlocked }
        let totalUnits = unlocked.reduce(0) { $0 + $1.units }
        guard totalUnits > 0 else { totalProgress = 0; return }
        let weighted = unlocked.reduce(0.0) { $0 + ($1.units / totalUnits) * $1.progress }
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

    // MARK: - Hiring / firing workers on a discipline (ported from Recurso's suma/resta + RPLUS/RMINUS)

    func hireWorker(for packageID: WorkPackage.ID) {
        guard let idx = workPackages.firstIndex(where: { $0.id == packageID }), workPackages[idx].isUnlocked else { return }
        workPackages[idx].headcount += 1
        let spent = workPackages[idx].cost
        workPackages[idx].totalSpent += spent
        // Hiring quickly nudges cost up and rate down a touch - and costs
        // a little risk/quality, same trade-off as buying a booster.
        workPackages[idx].cost *= Double.random(in: 0.99...1.05)
        workPackages[idx].rate *= Double.random(in: 0.95...1.01)
        workPackages[idx].clampCost()
        workPackages[idx].clampRate()
        riskGauge = min(max(riskGauge * Double.random(in: 0.90...0.99), 0.5), 1.5)
        qualityGauge = min(max(qualityGauge * Double.random(in: 0.90...0.99), 0.5), 1.5)
        recomputeTotals()
    }

    func fireWorker(for packageID: WorkPackage.ID) {
        guard let idx = workPackages.firstIndex(where: { $0.id == packageID }), workPackages[idx].headcount > 0 else { return }
        workPackages[idx].headcount -= 1
        workPackages[idx].cost *= Double.random(in: 0.95...1.02)
        workPackages[idx].rate *= Double.random(in: 0.98...1.05)
        workPackages[idx].clampCost()
        workPackages[idx].clampRate()
        riskGauge = min(max(riskGauge * Double.random(in: 1.01...1.05), 0.5), 1.5)
        qualityGauge = min(max(qualityGauge * Double.random(in: 1.01...1.05), 0.5), 1.5)
        recomputeTotals()
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

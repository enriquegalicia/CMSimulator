//
//  CMSimulatorTests.swift
//  CMSimulatorTests
//
//  These tests exist to lock in the properties the rebuild was for. The
//  headline one is `testAddingCrewNoLongerCancelsOutOfCost`: in the old
//  engine, headcount cancelled out of total cost exactly, so fifty
//  workers finished fifty times faster for the same money and hiring was
//  a free speed button. If that identity ever comes back, that test
//  fails.
//

import XCTest
@testable import CriticalPathSim

// MARK: - Crew productivity model

final class CrewMathTests: XCTestCase {

    func testCongestionIsNeutralUpToOptimalCrew() {
        for crew in 1...6 {
            XCTAssertEqual(WorkPackage.congestionFactor(crewSize: crew, optimalCrew: 6), 1,
                           accuracy: 1e-9, "crew at or under optimal should not be penalised")
        }
    }

    func testCongestionPenalisesOvercrowding() {
        let atOptimal = WorkPackage.congestionFactor(crewSize: 6, optimalCrew: 6)
        let double = WorkPackage.congestionFactor(crewSize: 12, optimalCrew: 6)
        let quadruple = WorkPackage.congestionFactor(crewSize: 24, optimalCrew: 6)

        XCTAssertLessThan(double, atOptimal)
        XCTAssertLessThan(quadruple, double)

        // Total output must still rise with crew - crowding is diminishing
        // returns, not a cliff - otherwise adding people would be strictly
        // wrong rather than a judgement call.
        XCTAssertGreaterThan(12 * double, 6 * atOptimal)
        XCTAssertGreaterThan(24 * quadruple, 12 * double)

        // But output *per head* must fall, which is what stops "hire
        // everyone immediately" from being the dominant line it used to be.
        XCTAssertLessThan(quadruple, 0.5)
    }

    func testMentoringDragScalesWithGreenHiresAndHasAFloor() {
        XCTAssertEqual(WorkPackage.mentoringDrag(greenCount: 0), 1, accuracy: 1e-9)
        XCTAssertLessThan(WorkPackage.mentoringDrag(greenCount: 2), WorkPackage.mentoringDrag(greenCount: 1))
        XCTAssertGreaterThanOrEqual(WorkPackage.mentoringDrag(greenCount: 99),
                                    WorkerTuning.minimumCrewDragMultiplier)
    }

    func testNewHireStartsSlowAndRampsUp() {
        var worker = Worker(name: "Test", archetype: .allRounder, packageID: "design")
        let dayOne = worker.effectiveOutput
        XCTAssertTrue(worker.isOnboarding)

        worker.advance(days: WorkerTuning.onboardingDays, overtime: 0, isWorking: true)
        XCTAssertFalse(worker.isOnboarding)
        XCTAssertGreaterThan(worker.effectiveOutput, dayOne * 2,
                             "a fully ramped worker should massively outproduce their first day")
    }

    func testExperienceMakesAVeteranWorthRoughlyThreeRookies() {
        var rookie = Worker(name: "Rookie", archetype: .allRounder, packageID: "design")
        rookie.rampProgress = 1
        rookie.experience = 0

        var veteran = rookie
        veteran.experience = 1

        let ratio = veteran.effectiveOutput / rookie.effectiveOutput
        XCTAssertEqual(ratio, WorkerTuning.veteranMultiplier, accuracy: 0.01)
        XCTAssertGreaterThan(ratio, 2, "the veteran premium is what makes firing expensive")
    }

    func testOvertimeBurnsMoraleAndNormalHoursRecoverIt() {
        var pushed = Worker(name: "A", archetype: .allRounder, packageID: "design")
        var rested = pushed
        pushed.advance(days: 10, overtime: 1, isWorking: true)
        rested.advance(days: 10, overtime: 0, isWorking: true)

        XCTAssertLessThan(pushed.morale, rested.morale)
    }

    func testOnlyUnhappyWorkersEverConsiderQuitting() {
        var happy = Worker(name: "A", archetype: .allRounder, packageID: "design")
        happy.morale = 0.9
        XCTAssertEqual(happy.quitProbability(over: 1), 0, accuracy: 1e-9)

        var miserable = happy
        miserable.morale = 0.02
        XCTAssertGreaterThan(miserable.quitProbability(over: 1), 0)
    }
}

// MARK: - Ledger

final class LedgerTests: XCTestCase {

    func testSpendingFallsBackToCreditThenRefuses() {
        var ledger = Ledger(startingCash: 100, creditLimit: 50, dailyInterestRate: 0)

        XCTAssertTrue(ledger.spend(120, into: \.materials))
        XCTAssertEqual(ledger.cash, 0, accuracy: 1e-9)
        XCTAssertEqual(ledger.debt, 20, accuracy: 1e-9)

        XCTAssertFalse(ledger.spend(100, into: \.materials), "beyond cash plus credit must be refused")
        XCTAssertEqual(ledger.debt, 20, accuracy: 1e-9, "a refused spend must change nothing")
        XCTAssertEqual(ledger.costs.materials, 120, accuracy: 1e-9)
    }

    func testForceSpendReportsShortfallButStillRecordsTheObligation() {
        var ledger = Ledger(startingCash: 10, creditLimit: 0, dailyInterestRate: 0)
        let shortfall = ledger.forceSpend(30, into: \.wages)

        XCTAssertEqual(shortfall, 20, accuracy: 1e-9)
        XCTAssertEqual(ledger.costs.wages, 30, accuracy: 1e-9, "unpaid payroll is still a cost")
        XCTAssertEqual(ledger.spendingPower, 0, accuracy: 1e-9)
    }

    func testIncomingMoneyClearsDebtBeforeBuildingCash() {
        var ledger = Ledger(startingCash: 0, creditLimit: 500, dailyInterestRate: 0)
        ledger.forceSpend(300, into: \.wages)
        XCTAssertEqual(ledger.debt, 300, accuracy: 1e-9)

        ledger.receive(200, retainage: 20)
        XCTAssertEqual(ledger.debt, 100, accuracy: 1e-9)
        XCTAssertEqual(ledger.cash, 0, accuracy: 1e-9)
        XCTAssertEqual(ledger.retainageHeld, 20, accuracy: 1e-9)
    }

    func testProfitCountsHeldRetainageAsEarned() {
        var ledger = Ledger(startingCash: 1000, creditLimit: 0, dailyInterestRate: 0)
        ledger.forceSpend(400, into: \.materials)
        ledger.receive(900, retainage: 100)
        XCTAssertEqual(ledger.profit, 600, accuracy: 1e-9)
    }
}

// MARK: - The core fix

@MainActor
final class EconomyRegressionTests: XCTestCase {

    private func makeEngine() -> SimulationEngine {
        SimulationEngine(brief: .construction(difficulty: .steady, persona: .institution, seed: 42))
    }

    /// Keeps a package supplied so a test measures the thing it names
    /// rather than material starvation.
    private func feed(_ engine: SimulationEngine, _ packageID: String) {
        engine.debugSetMaterialStock(100_000, for: packageID)
    }

    /// Hires `count` identical workers onto a package, bypassing the
    /// picker so the archetype mix cannot skew the comparison.
    private func stack(_ engine: SimulationEngine, _ count: Int, on packageID: String) {
        for _ in 0..<count {
            engine.requestHire(for: packageID)
            guard let request = engine.hiringRequest else { return XCTFail("no hiring request") }
            // Take whichever candidate exists; the run is seeded, so both
            // arms of the comparison draw the same sequence.
            guard let candidate = request.candidates.first else { return XCTFail("empty pool") }
            engine.confirmHire(candidate)
        }
    }

    /// The regression that this whole rebuild exists for.
    ///
    /// Old engine: earning `rate * crew * step` while charging
    /// `cost * crew * step` meant a package always cost exactly
    /// `units * cost / rate`, whatever the crew size. Crew cancelled.
    /// Now wages are per person per day and crowding is real, so piling
    /// people on must cost strictly more labour per unit built.
    func testAddingCrewNoLongerCancelsOutOfCost() {
        func labourCostPerUnit(crewSize: Int) -> Double {
            let engine = SimulationEngine(brief: .construction(difficulty: .steady, persona: .institution, seed: 7))
            feed(engine, "design")
            stack(engine, crewSize, on: "design")
            // Let everyone finish onboarding so the comparison is about
            // crowding, not ramp-up.
            for _ in 0..<400 {
                feed(engine, "design")
                engine.advance(byDays: 0.05)
            }
            let built = engine.workPackages.first { $0.id == "design" }!.unitsCompleted
            XCTAssertGreaterThan(built, 0, "crew \(crewSize) should have built something")
            return engine.ledger.costs.wages / built
        }

        let lean = labourCostPerUnit(crewSize: 4)
        let crowded = labourCostPerUnit(crewSize: 28)

        XCTAssertGreaterThan(crowded, lean * 1.15,
                             "piling on crew must cost meaningfully more per unit; if these are equal, the crew-cancels-out bug is back")
    }

    func testHiringActuallyCostsCash() {
        let engine = makeEngine()
        let before = engine.ledger.cash
        stack(engine, 1, on: "design")

        XCTAssertLessThan(engine.ledger.cash, before, "the signing cost must leave the ledger")
        XCTAssertGreaterThan(engine.ledger.costs.signing, 0)
        XCTAssertEqual(engine.workers.count, 1)
    }

    func testIdleCrewStillDrawWagesWhenMaterialsRunOut() {
        let engine = makeEngine()
        stack(engine, 3, on: "design")
        // Strand them: no materials, nothing to build.
        engine.debugSetMaterialStock(0, for: "design")

        let wagesBefore = engine.ledger.costs.wages
        for _ in 0..<40 { engine.advance(byDays: 0.25) }

        XCTAssertEqual(engine.workPackages.first { $0.id == "design" }!.unitsCompleted, 0, accuracy: 1e-9)
        XCTAssertGreaterThan(engine.ledger.costs.wages, wagesBefore,
                             "a stranded crew is still on the payroll - that is the whole lesson about lead times")
        XCTAssertGreaterThan(engine.totalIdleCrewDays, 0)
    }

    /// Old engine: `fireWorker` multiplied both gauges by 1.01...1.05,
    /// so both moved toward the good end. Firing was a repair mechanic
    /// and hire/fire churn was the optimal line.
    func testFiringIsExpensiveOnEveryAxis() {
        let engine = makeEngine()
        feed(engine, "design")
        stack(engine, 3, on: "design")
        for _ in 0..<20 { engine.advance(byDays: 0.5) }

        let severanceBefore = engine.ledger.costs.severance
        let reputationBefore = engine.reputation
        let moraleBefore = engine.averageMorale
        let victim = engine.workers[0].id

        engine.fire(workerID: victim)

        XCTAssertGreaterThan(engine.ledger.costs.severance, severanceBefore, "severance must be paid")
        XCTAssertLessThan(engine.reputation, reputationBefore, "firing must damage reputation")
        XCTAssertLessThan(engine.averageMorale, moraleBefore, "morale must drop across the remaining crew")
        XCTAssertEqual(engine.workers.count, 2)
    }

    /// Old engine: a buy applied random(0.94...1.08) and a sell applied
    /// 1/random(0.94...1.08) as an independent second draw, with a full
    /// refund - a positive-expected-value round trip you could grind.
    func testCapabilityStandDownRefundsNothing() {
        let engine = makeEngine()
        let cashBefore = engine.ledger.cash

        engine.upgrade(.planning)
        let afterBuy = engine.ledger.cash
        XCTAssertLessThan(afterBuy, cashBefore)
        XCTAssertEqual(engine.level(of: .planning), 1)

        engine.standDown(.planning)
        XCTAssertEqual(engine.level(of: .planning), 0)
        XCTAssertEqual(engine.ledger.cash, afterBuy, accuracy: 1e-9,
                       "standing a capability down must not refund - otherwise buy/sell is an arbitrage loop")
    }

    func testCapabilitiesChargeUpkeepEveryDay() {
        let engine = makeEngine()
        engine.upgrade(.planning)
        XCTAssertEqual(engine.level(of: .planning), 1)
        let spentOnStaffing = engine.ledger.costs.capabilities

        for _ in 0..<20 { engine.advance(byDays: 0.5) }

        XCTAssertGreaterThan(engine.ledger.costs.capabilities, spentOnStaffing,
                             "a staffed capability must keep costing money, so it competes with payroll")
    }

    /// Old engine: progress was weighted across *unlocked* packages only,
    /// so unlocking one enlarged the denominator and the headline
    /// percentage fell while the player was doing well.
    ///
    /// Note this cannot assert blanket monotonicity: incidents destroy
    /// built work by design, so progress legitimately falls when a storm
    /// lands. What must never happen is a fall caused by an unlock.
    func testProgressNeverGoesBackwardsWhenAPackageUnlocks() {
        let engine = makeEngine()
        feed(engine, "design")
        stack(engine, 8, on: "design")

        var unlockedBefore = engine.workPackages.filter(\.isUnlocked).count
        var sawAnUnlock = false

        for _ in 0..<900 {
            feed(engine, "design")
            let before = engine.totalProgress
            engine.advance(byDays: 0.2)
            let unlockedAfter = engine.workPackages.filter(\.isUnlocked).count

            if unlockedAfter > unlockedBefore {
                sawAnUnlock = true
                XCTAssertGreaterThanOrEqual(engine.totalProgress, before - 1e-9,
                                            "progress fell at the moment a package unlocked - the old denominator bug")
            }
            unlockedBefore = unlockedAfter

            // On any tick where nothing blew up, progress must not fall.
            if engine.activeEvent == nil {
                XCTAssertGreaterThanOrEqual(engine.totalProgress, before - 1e-9,
                                            "progress fell with no incident to explain it")
            }
            engine.dismissEvent()
        }
        XCTAssertTrue(sawAnUnlock, "the test should actually reach an unlock to be meaningful")
    }

    func testRunningOutOfMoneyEndsTheRun() {
        let engine = SimulationEngine(brief: .construction(difficulty: .tight, persona: .developer, seed: 3))
        // Hire far more people than the contract can carry.
        stack(engine, 12, on: "design")
        engine.debugDrainCash()

        for _ in 0..<200 where engine.outcome == nil {
            engine.advance(byDays: 0.5)
        }
        XCTAssertEqual(engine.outcome, .insolvent, "unpayable payroll must end the run")
    }
}

// MARK: - Quality and scoring

final class QualityAndScoringTests: XCTestCase {

    func testCatchingDefectsEarlyIsFarCheaperThanAtHandover() {
        XCTAssertGreaterThan(CapabilityEffects.reworkCostPerDefect,
                             CapabilityEffects.inspectionCostPerDefect * 3,
                             "the gap between these two numbers is the entire Quality lesson")
    }

    func testSixLeversDoNotAllShareTheSameVerb() {
        let verbs = Set(CapabilityKind.allCases.map(\.verb))
        XCTAssertEqual(verbs.count, CapabilityKind.allCases.count,
                       "each capability must answer a different question - they used to be one lever with six pictures")
    }

    func testEveryIncidentBelongsToABuyableMitigationClass() {
        for kind in SimEventKind.allCases {
            XCTAssertTrue(MitigationClass.allCases.contains(kind.mitigationClass),
                          "\(kind) has no mitigation the player can buy against it")
        }
    }

    func testClientNeverPaysOutMoreThanTheContractIsWorth() {
        let brief = ProjectBrief.construction()
        let total = brief.advanceRate + brief.milestones.reduce(0) { $0 + $1.share }
        XCTAssertEqual(total, 1.0, accuracy: 0.001,
                       "the advance plus every milestone must sum to exactly the contract value")
    }

    /// Every package must be reachable from the ones that unlock before it,
    /// or the project soft-locks with nothing legal left to start.
    func testNoPackageThresholdIsUnreachable() {
        let streams = ProjectBrief.constructionStreams
        let totalUnits = streams.reduce(0) { $0 + $1.units }
        var cumulative = 0.0
        for stream in streams {
            let reachable = cumulative / totalUnits * 100
            XCTAssertLessThanOrEqual(stream.startThreshold, reachable + 0.001,
                                     "\(stream.id) unlocks at \(stream.startThreshold)% but only \(reachable)% is reachable before it")
            cumulative += stream.units
        }
    }

    func testInsolventRunsScoreZero() {
        let result = RunResult(outcome: .insolvent, profit: 50_000, revenue: 100_000,
                               costs: CostBreakdown(), days: 40, deadlineDays: 100, progress: 30,
                               openDefects: 0, resolvedDefects: 0, idleCrewDays: 0, finalCrewSize: 0,
                               clientTrust: 0.5, reputation: 0.5, difficulty: .standard,
                               persona: .developer, seed: 1)
        XCTAssertEqual(result.score, 0, accuracy: 1e-9)
    }

    func testHarderDifficultyOutranksAnIdenticalEasyRun() {
        func score(_ difficulty: Difficulty) -> Double {
            RunResult(outcome: .delivered, profit: 100_000, revenue: 500_000,
                      costs: CostBreakdown(), days: 90, deadlineDays: 100, progress: 100,
                      openDefects: 0, resolvedDefects: 0, idleCrewDays: 0, finalCrewSize: 5,
                      clientTrust: 0.8, reputation: 0.8, difficulty: difficulty,
                      persona: .developer, seed: 1).score
        }
        XCTAssertGreaterThan(score(.tight), score(.standard))
        XCTAssertGreaterThan(score(.standard), score(.steady))
    }
}

// MARK: - Determinism

final class SeededGeneratorTests: XCTestCase {

    func testSameSeedProducesTheSameSequence() {
        var a = SeededGenerator(seed: 12345)
        var b = SeededGenerator(seed: 12345)
        for _ in 0..<50 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testDifferentSeedsDiverge() {
        var a = SeededGenerator(seed: 1)
        var b = SeededGenerator(seed: 2)
        let left = (0..<20).map { _ in a.next() }
        let right = (0..<20).map { _ in b.next() }
        XCTAssertNotEqual(left, right)
    }

    /// A shared daily challenge only works if a seed fully reproduces the
    /// project the player is handed.
    func testSameSeedProducesTheSameBrief() {
        let first = ProjectBrief.construction(difficulty: .standard, seed: 9_999)
        let second = ProjectBrief.construction(difficulty: .standard, seed: 9_999)

        XCTAssertEqual(first.clientPersona, second.clientPersona)
        XCTAssertEqual(first.labourMarketFactor, second.labourMarketFactor, accuracy: 1e-12)
        XCTAssertEqual(first.marketVolatility, second.marketVolatility, accuracy: 1e-12)
    }
}

// MARK: - Market

final class MaterialMarketTests: XCTestCase {

    func testIndexStaysWithinSaneBounds() {
        var market = MaterialMarket(volatility: 0.08)
        for _ in 0..<5_000 { market.advance(days: 0.5) }
        XCTAssertGreaterThanOrEqual(market.index, 0.55)
        XCTAssertLessThanOrEqual(market.index, 2.4)
    }

    func testLockingFreezesThePriceOrdersAreQuotedAt() {
        var market = MaterialMarket(volatility: 0.05)
        for _ in 0..<20 { market.advance(days: 1) }
        market.lockPrice(for: 30)
        let locked = market.effectiveIndex

        for _ in 0..<20 { market.advance(days: 1) }
        XCTAssertTrue(market.isLocked)
        XCTAssertEqual(market.effectiveIndex, locked, accuracy: 1e-12)

        for _ in 0..<20 { market.advance(days: 1) }
        XCTAssertFalse(market.isLocked, "the lock must expire")
        XCTAssertEqual(market.effectiveIndex, market.index, accuracy: 1e-12)
    }
}

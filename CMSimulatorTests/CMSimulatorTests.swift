//
//  CMSimulatorTests.swift
//  CMSimulatorTests
//
//  Covers the regression-prone logic called out in the engine's own code
//  comments: the soft-lock progress-weighting fix, gauge clamping bounds,
//  and the event-trigger probability's speed-independence, plus
//  WorkPackage's cost/rate clamps.
//

import XCTest
@testable import CriticalPathSim

final class WorkPackageClampTests: XCTestCase {
    func testCostClampsToInitialBounds() {
        var package = WorkPackage(id: "x", title: "X", imageName: "x.png", initialCost: 100, units: 10, initialRate: 1, startThreshold: 0)

        package.cost = 1000
        package.clampCost()
        XCTAssertEqual(package.cost, 300, accuracy: 0.0001, "cost should clamp to initial * 3")

        package.cost = 1
        package.clampCost()
        XCTAssertEqual(package.cost, 50, accuracy: 0.0001, "cost should clamp to initial / 2")
    }

    func testRateClampsToInitialBounds() {
        var package = WorkPackage(id: "x", title: "X", imageName: "x.png", initialCost: 100, units: 10, initialRate: 2, startThreshold: 0)

        package.rate = 100
        package.clampRate()
        XCTAssertEqual(package.rate, 3.6, accuracy: 0.0001, "rate should clamp to initial * 1.8")

        package.rate = 0.01
        package.clampRate()
        XCTAssertEqual(package.rate, 0.6, accuracy: 0.0001, "rate should clamp to initial * 0.3")
    }
}

final class EventTriggerProbabilityTests: XCTestCase {
    func testProbabilityStaysWithinUnitBounds() {
        let p = SimulationEngine.eventTriggerProbability(dailyChance: 0.4, step: 0.2)
        XCTAssertGreaterThanOrEqual(p, 0)
        XCTAssertLessThanOrEqual(p, 1)
    }

    func testZeroStepNeverTriggers() {
        XCTAssertEqual(SimulationEngine.eventTriggerProbability(dailyChance: 0.4, step: 0), 0, accuracy: 0.0000001)
    }

    /// Splitting one full-day step into two half-day steps and compounding
    /// the "no event" survival probabilities must match taking the step in
    /// one shot - this identity is exactly what makes the expected time to
    /// an event, in simulated days, independent of playback speed.
    func testSpeedIndependenceCompoundingIdentity() {
        let dailyChance = 0.4
        let wholeStepP = SimulationEngine.eventTriggerProbability(dailyChance: dailyChance, step: 1.0)
        let halfStepP = SimulationEngine.eventTriggerProbability(dailyChance: dailyChance, step: 0.5)

        let survivalWhole = 1 - wholeStepP
        let survivalTwoHalves = (1 - halfStepP) * (1 - halfStepP)

        XCTAssertEqual(survivalWhole, survivalTwoHalves, accuracy: 0.0000001)
    }
}

@MainActor
final class SimulationEngineTests: XCTestCase {
    private func hireOne(_ engine: SimulationEngine, for packageID: WorkPackage.ID) {
        engine.requestHire(for: packageID)
        guard let candidate = engine.hiringRequest?.candidates.first else {
            XCTFail("requestHire should always offer at least one candidate")
            return
        }
        engine.confirmHire(candidate)
    }

    func testGaugesStayWithinClampedBoundsAcrossManyHireFireCycles() {
        let engine = SimulationEngine()
        for _ in 0..<40 {
            hireOne(engine, for: "design")
            engine.fireWorker(for: "design")

            XCTAssertGreaterThanOrEqual(engine.riskGauge, 0.5)
            XCTAssertLessThanOrEqual(engine.riskGauge, 1.5)
            XCTAssertGreaterThanOrEqual(engine.qualityGauge, 0.5)
            XCTAssertLessThanOrEqual(engine.qualityGauge, 1.5)
        }
    }

    /// Regression test for the soft-lock this project shipped with:
    /// progress used to be weighted against every package's units
    /// regardless of lock state, so Design alone could never earn enough
    /// weighted progress to cross Structure's 10% unlock threshold - this
    /// test would hang until timeout on that bug and pass once fixed.
    func testStructureEventuallyUnlocksDespiteDesignAloneWeighting() async throws {
        let engine = SimulationEngine()
        hireOne(engine, for: "design")
        engine.superFastForward()

        let deadline = Date().addingTimeInterval(5)
        while engine.workPackages.first(where: { $0.id == "structure" })?.isUnlocked != true, Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        engine.pause()

        XCTAssertEqual(engine.workPackages.first(where: { $0.id == "structure" })?.isUnlocked, true)
    }
}

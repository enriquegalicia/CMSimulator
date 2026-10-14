//
//  StoreScreenshots.swift
//  CMSimulator
//
//  Stages the App Store screenshots. Launched with `-StoreShot <id>`, a
//  build compiled with the STORE_SCREENSHOTS condition plays a run with
//  ordinary, sensible moves through the same public calls the buttons
//  make - hire up to the ideal crew, reorder before stock runs out, staff
//  two levers - and stops on the screen the shot needs. Nothing is faked:
//  the numbers on screen are a real run.
//
//  Only `Scripts/capture_screenshots.sh` sets STORE_SCREENSHOTS (on the
//  xcodebuild command line). Every other build, Debug or Release, never
//  reads the argument, so `requested` is always nil.
//

import Foundation

enum StoreScreenshots {
    struct Shot {
        let id: String
        let scenario: ScenarioKind
        /// Days of play before the shot. Ignored when `playToEnd`.
        var days: Double = 0
        var playToEnd = false
        var board: GameView.Board = .site
        var opens: Sheet? = nil
    }

    enum Sheet { case picker, help, hiring, suppliers, risk, crew }

    /// One fixed seed per shot, so a retake shows the same run.
    static let seed: UInt64 = 7

    static let catalogue: [Shot] = [
        Shot(id: "board", scenario: .construction, days: 34),
        Shot(id: "debrief", scenario: .construction, playToEnd: true),
        Shot(id: "picker", scenario: .construction, opens: .picker),
        Shot(id: "trading", scenario: .importing, days: 70, board: .trading),
        Shot(id: "growth", scenario: .startup, days: 90, board: .growth),
        Shot(id: "levers", scenario: .construction, days: 24, board: .levers),
        Shot(id: "hiring", scenario: .construction, days: 12, opens: .hiring),
        Shot(id: "suppliers", scenario: .importing, days: 20, opens: .suppliers),
        Shot(id: "risk", scenario: .construction, days: 40, opens: .risk),
        Shot(id: "log", scenario: .construction, days: 46, board: .log),
        Shot(id: "help", scenario: .startup, opens: .help),
    ]

    static let requested: Shot? = {
        #if STORE_SCREENSHOTS
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-StoreShot"), i + 1 < args.count else { return nil }
        return catalogue.first { $0.id == args[i + 1] }
        #else
        return nil
        #endif
    }()

    /// Plays the run the way a careful player would.
    @MainActor
    static func play(_ shot: Shot, on engine: SimulationEngine) {
        engine.upgrade(.planning)
        engine.upgrade(.quality)
        if let trading = engine.trading {
            engine.setListPrice((trading.spec.referencePrice * 1.05 * 2).rounded() / 2)
            engine.setAdSpend(1_500)
        }
        var elapsed = 0.0
        while shot.playToEnd ? engine.outcome == nil : elapsed < shot.days {
            guard elapsed < 600, engine.outcome == nil else { break }
            if engine.activeEvent != nil { engine.dismissEvent() }
            tend(engine)
            engine.advance(byDays: 0.25)
            elapsed += 0.25
        }
        if engine.activeEvent != nil { engine.dismissEvent() }

        switch shot.opens {
        case .hiring:
            if let stream = engine.workPackages.first(where: { $0.isUnlocked && !$0.isComplete }) {
                engine.requestHire(for: stream.id)
            }
        case .suppliers:
            if engine.trading != nil {
                engine.requestStockOrder()
            } else if let stream = engine.workPackages.first(where: { $0.isUnlocked && $0.consumesMaterials && !$0.isComplete }) {
                engine.requestMaterialOrder(for: stream.id)
            }
        default:
            break
        }
    }

    @MainActor
    private static func tend(_ engine: SimulationEngine) {
        for stream in engine.workPackages where stream.isUnlocked && !stream.isComplete {
            if engine.crew(for: stream.id).count < stream.optimalCrew,
               engine.ledger.spendingPower > 0 {
                engine.requestHire(for: stream.id)
                if let pick = engine.hiringRequest?.candidates.first {
                    engine.confirmHire(pick)
                } else {
                    engine.cancelHiring()
                }
            }
            let perUnit = stream.spec.materialUnitsPerWorkUnit
            let onTheWay = engine.orders.contains { $0.packageID == stream.id }
            if stream.consumesMaterials, !onTheWay,
               engine.outstandingMaterialNeed(for: stream.id) > 0,
               stream.materialStock < perUnit * stream.units * 0.15 {
                engine.requestMaterialOrder(for: stream.id)
                if let request = engine.orderRequest {
                    let quantity = min(request.suggestedQuantity, (perUnit * stream.units * 0.35).rounded(.up))
                    engine.placeOrder(vendor: balanced(request.vendors), quantity: quantity)
                }
            }
        }
        if let growth = engine.growth, growth.isLaunched, growth.dailyGrowthSpend == 0 {
            engine.setGrowthSpend((growth.currentAcquisitionCost * 3).rounded())
        }
        if let trading = engine.trading {
            let onTheWay = engine.orders.contains { $0.packageID == SimulationEngine.stockOrderID }
            if !onTheWay, trading.unitsOnHand < 400 {
                engine.requestStockOrder()
                if let request = engine.orderRequest, request.suggestedQuantity > 0 {
                    engine.placeOrder(vendor: balanced(request.vendors), quantity: request.suggestedQuantity)
                } else {
                    engine.cancelMaterialOrder()
                }
            }
        }
    }

    /// The middle quote: neither the cheapest-and-flakiest nor the dearest.
    private static func balanced(_ vendors: [Vendor]) -> Vendor {
        let sorted = vendors.sorted { $0.priceFactor < $1.priceFactor }
        return sorted[sorted.count / 2]
    }
}

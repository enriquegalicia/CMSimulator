//
//  GameCenterManager.swift
//  CMSimulator
//

import Foundation
import GameKit
import SwiftUI

@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    // These exact IDs must exist as Leaderboards in App Store Connect
    // (App ▸ Features ▸ Game Center) before scores will post or appear.
    // documentation/GameCenter_Setup.md is the configuration contract and
    // is verified against this file by a test - if you change an ID here,
    // that test fails until the document is updated to match.
    //
    // Profit is per scenario. A building, a software company and a trading
    // operation are not comparable on one ranking, and the in-app boards
    // have always been filtered by scenario - Game Center simply was not.
    static let profitPrefix = "com.aguach1leLabs.CriticalPathSim.profit"

    /// Descending: higher profit is better.
    static func profitLeaderboardID(for scenario: ScenarioKind) -> String {
        "\(profitPrefix).\(scenario.rawValue.lowercased())"
    }

    static var allProfitLeaderboardIDs: [String] {
        ScenarioKind.allCases.map(profitLeaderboardID(for:))
    }

    /// Ascending, and construction only. "Built it for less" and "built it
    /// in fewer days" are coherent rankings on a contract with a fixed
    /// scope and a deadline. They are not coherent for a startup, whose
    /// length is a strategic choice, or for an import season, whose length
    /// is fixed by the calendar - submitting those to a shared board
    /// ranked noise.
    static let costLeaderboardID = "com.aguach1leLabs.CriticalPathSim.costmaster"
    static let timeLeaderboardID = "com.aguach1leLabs.CriticalPathSim.timemaster"

    /// Every board the app can post to, for the setup document and its test.
    static var allLeaderboardIDs: [String] {
        allProfitLeaderboardIDs + [costLeaderboardID, timeLeaderboardID]
    }

    @Published var isAuthenticated = false
    @Published var authViewController: UIViewController?
    /// Set to present the Game Center dashboard (leaderboards/achievements).
    @Published var dashboardViewController: UIViewController?

    func authenticate() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                self.authViewController = viewController
            } else if localPlayer.isAuthenticated {
                self.isAuthenticated = true
            } else {
                if let error {
                    print("Game Center unavailable: \(error.localizedDescription)")
                }
                self.isAuthenticated = false
            }
        }
    }

    /// Reports a completed run. Only deliveries are submitted - an
    /// insolvent run has no meaningful profit to rank.
    func report(_ result: RunResult) {
        guard GKLocalPlayer.local.isAuthenticated, result.outcome == .delivered else { return }

        let profitScore = Int(result.score.rounded())
        let profitBoard = Self.profitLeaderboardID(for: result.scenario)
        // Cost and days only rank meaningfully against a fixed scope and a
        // contractual deadline, which is construction and nothing else.
        let costBoards: [(Int, String)] = result.scenario == .construction
            ? [(Int(result.costs.total.rounded()), Self.costLeaderboardID),
               // Tenths of a day, for finer precision than whole days.
               (Int((result.days * 10).rounded()), Self.timeLeaderboardID)]
            : []

        Task {
            await submit(profitScore, to: profitBoard)
            for (score, board) in costBoards {
                await submit(score, to: board)
            }
        }
    }

    private func submit(_ score: Int, to leaderboardID: String) async {
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        } catch {
            print("Game Center score submission failed for \(leaderboardID): \(error.localizedDescription)")
        }
    }

    /// Presents the actual Game Center dashboard (leaderboards tab) - what
    /// the toolbar's Game Center button should show once signed in, rather
    /// than silently re-authenticating.
    func showDashboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = self
        dashboardViewController = vc
    }
}

extension GameCenterManager: GKGameCenterControllerDelegate {
    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            dashboardViewController = nil
        }
    }
}

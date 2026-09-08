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
    // (App ▸ Features ▸ Game Center) before scores will actually post or
    // show up - see documentation/GameCenter_Setup.md. All three should be
    // configured there with ascending sort order (lower is better).
    static let costLeaderboardID = "com.aguach1leLabs.CriticalPathSim.costmaster"
    static let timeLeaderboardID = "com.aguach1leLabs.CriticalPathSim.timemaster"
    static let combinedLeaderboardID = "com.aguach1leLabs.CriticalPathSim.constructionmaster"
    /// New for the profit-based scoring. Must be created in App Store
    /// Connect with *descending* sort (higher is better) before it will
    /// accept scores - the other three are ascending and cannot be reused
    /// for profit. Submissions to a leaderboard that does not exist fail
    /// silently and are logged, so shipping before it exists is safe.
    static let profitLeaderboardID = "com.aguach1leLabs.CriticalPathSim.profit"

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
    ///
    /// Total cost and elapsed days still go to the two existing ascending
    /// boards, where "lower is better" remains the right reading. The old
    /// combined board is deliberately not submitted to any more: it was an
    /// ascending normalized cost+days sum, and posting profit to it would
    /// rank the worst runs first.
    func report(_ result: RunResult) {
        guard GKLocalPlayer.local.isAuthenticated, result.outcome == .delivered else { return }
        let costScore = Int(result.costs.total.rounded())
        // Tenths of a day, so the board has finer precision than whole days.
        let timeScore = Int((result.days * 10).rounded())
        let profitScore = Int(result.score.rounded())

        Task {
            async let costResult: Void = submit(costScore, to: Self.costLeaderboardID)
            async let timeResult: Void = submit(timeScore, to: Self.timeLeaderboardID)
            async let profitResult: Void = submit(profitScore, to: Self.profitLeaderboardID)
            _ = await (costResult, timeResult, profitResult)
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

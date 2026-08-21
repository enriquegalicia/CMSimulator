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
    static let costLeaderboardID = "com.magarchitecture.CMSimulator.costmaster"
    static let timeLeaderboardID = "com.magarchitecture.CMSimulator.timemaster"
    static let combinedLeaderboardID = "com.magarchitecture.CMSimulator.constructionmaster"

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

    /// Reports a completed run to all three leaderboards at once. Cost and
    /// days both need "lower is better" ascending sort configured on the
    /// leaderboard itself in App Store Connect - this just submits the raw
    /// values, it can't set that sort order from the client.
    func reportScore(cost: Double, days: Double, combined: Double) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let costScore = Int(cost.rounded())
        // Submitted in tenths of a day so the leaderboard has integer
        // precision finer than whole days (e.g. 12.3 days -> 123).
        let timeScore = Int((days * 10).rounded())
        let combinedScore = Int((combined * 1000).rounded())

        Task {
            async let costResult: Void = submit(costScore, to: Self.costLeaderboardID)
            async let timeResult: Void = submit(timeScore, to: Self.timeLeaderboardID)
            async let combinedResultTask: Void = submit(combinedScore, to: Self.combinedLeaderboardID)
            _ = await (costResult, timeResult, combinedResultTask)
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

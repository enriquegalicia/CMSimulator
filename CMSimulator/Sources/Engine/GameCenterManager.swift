//
//  GameCenterManager.swift
//  CMSimulator
//

import Foundation
import GameKit
import SwiftUI

@MainActor
final class GameCenterManager: ObservableObject {
    static let leaderboardID = "com.magarchitecture.CMSimulator.constructionmaster"

    @Published var isAuthenticated = false
    @Published var authViewController: UIViewController?

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

    func reportScore(cost: Double) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let score = Int(cost)
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.leaderboardID]
                )
            } catch {
                print("Game Center score submission failed: \(error.localizedDescription)")
            }
        }
    }
}

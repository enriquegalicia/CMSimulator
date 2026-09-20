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
    static let profitPrefix = "com.aguach1leLabs.CriticalPath.profit"

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
    static let costLeaderboardID = "com.aguach1leLabs.CriticalPath.costmaster"
    static let timeLeaderboardID = "com.aguach1leLabs.CriticalPath.timemaster"

    /// Every board the app can post to, for the setup document and its test.
    static var allLeaderboardIDs: [String] {
        allProfitLeaderboardIDs + [costLeaderboardID, timeLeaderboardID]
    }

    /// What happened the last time the app talked to a board. Submission
    /// failures are otherwise completely silent - Game Center does not
    /// surface them, so "the leaderboards do not work" is unanswerable
    /// without this.
    struct BoardStatus: Identifiable {
        enum State: Equatable {
            case untested
            case registered          // exists in App Store Connect
            case missing             // the ID is not registered
            case submitted(Int)      // a score went up
            case failed(String)
        }
        let id: String
        var state: State = .untested
        var checkedAt: Date?

        var summary: String {
            switch state {
            case .untested: return String(localized: "Not checked yet", comment: "Leaderboard status")
            case .registered: return String(localized: "Registered and reachable", comment: "Leaderboard status")
            case .missing: return String(localized: "Not registered in App Store Connect", comment: "Leaderboard status")
            case .submitted(let score): return String(localized: "Last score sent: \(score)", comment: "Leaderboard status")
            case .failed(let why): return why
            }
        }

        var isHealthy: Bool {
            switch state {
            case .registered, .submitted: return true
            case .untested, .missing, .failed: return false
            }
        }
    }

    @Published var isAuthenticated = false
    /// One row per board the app can post to, in the order the setup
    /// document lists them.
    @Published private(set) var boards: [BoardStatus] =
        GameCenterManager.allLeaderboardIDs.map { BoardStatus(id: $0) }
    @Published private(set) var playerAlias: String?
    @Published private(set) var isCheckingBoards = false
    @Published private(set) var lastCheckError: String?
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
                self.playerAlias = localPlayer.alias
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
            record(leaderboardID, .submitted(score))
        } catch {
            record(leaderboardID, .failed(error.localizedDescription))
            print("Game Center score submission failed for \(leaderboardID): \(error.localizedDescription)")
        }
    }

    private func record(_ id: String, _ state: BoardStatus.State) {
        guard let idx = boards.firstIndex(where: { $0.id == id }) else { return }
        boards[idx].state = state
        boards[idx].checkedAt = Date()
    }

    /// Asks Game Center which of our boards actually exist. This is the
    /// test that answers "are the leaderboards working": it needs no
    /// completed run and posts no score, so it cannot pollute a board.
    /// A board missing here has not been created in App Store Connect,
    /// which is the single most common reason scores never appear.
    func checkBoards() async {
        guard GKLocalPlayer.local.isAuthenticated else {
            lastCheckError = String(localized: "Not signed in to Game Center.", comment: "Leaderboard check error")
            return
        }
        isCheckingBoards = true
        lastCheckError = nil
        defer { isCheckingBoards = false }

        do {
            let found = try await GKLeaderboard.loadLeaderboards(IDs: Self.allLeaderboardIDs)
            let foundIDs = Set(found.compactMap(\.baseLeaderboardID))
            for id in Self.allLeaderboardIDs {
                record(id, foundIDs.contains(id) ? .registered : .missing)
            }
        } catch {
            lastCheckError = error.localizedDescription
        }
    }

    /// Everything wrong right now, in one line, for the diagnostics export.
    var healthSummary: String {
        guard isAuthenticated else { return "Game Center: not signed in" }
        let bad = boards.filter { !$0.isHealthy }
        guard !bad.isEmpty else { return "Game Center: all \(boards.count) boards OK" }
        return "Game Center: \(bad.count) of \(boards.count) boards not OK — "
            + bad.map { "\($0.id) (\($0.summary))" }.joined(separator: "; ")
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

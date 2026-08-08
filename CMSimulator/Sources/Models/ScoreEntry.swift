//
//  ScoreEntry.swift
//  CMSimulator
//
//  Swift port of the GestorBD/DataBase SQLite leaderboard - replaced
//  with SwiftData, matching the Aguach1leLabs apps' persistence style.
//  One row per completed simulation run.
//

import Foundation
import SwiftData

@Model
final class ScoreEntry {
    var playerName: String
    var cost: Double
    var days: Double
    var completedAt: Date

    init(playerName: String, cost: Double, days: Double, completedAt: Date = Date()) {
        self.playerName = playerName
        self.cost = cost
        self.days = days
        self.completedAt = completedAt
    }

    /// Lower is better on both axes, so a simple normalized sum ranks
    /// "did well on cost and time" runs above one-sided ones.
    static func combinedScore(_ entry: ScoreEntry, maxCost: Double, maxDays: Double) -> Double {
        let c = maxCost > 0 ? entry.cost / maxCost : 0
        let d = maxDays > 0 ? entry.days / maxDays : 0
        return c + d
    }
}

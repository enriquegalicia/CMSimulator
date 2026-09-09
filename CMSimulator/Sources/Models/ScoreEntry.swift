//
//  ScoreEntry.swift
//  CMSimulator
//
//  One completed run. Now scored on profit rather than on the old
//  normalized cost + days sum, which could not express "finished cheap
//  but the building is defective" and, more importantly, does not
//  generalize: a cafe or an import business has no "days on site" in
//  common with a building, but every scenario has a P&L. Keeping the
//  leaderboard on profit is what will let the planned scenarios share
//  one Operator Rating later.
//

import Foundation
import SwiftData

@Model
final class ScoreEntry {
    var playerName: String
    /// The leaderboard number: difficulty-scaled profit.
    var score: Double
    var profit: Double
    var revenue: Double
    var days: Double
    var deadlineDays: Double
    var wasOnTime: Bool
    var openDefects: Double
    var idleCrewDays: Double
    /// Difficulty and client persona raw values, kept as strings so the
    /// stored schema does not break if the enums gain cases.
    var difficultyRaw: String
    var personaRaw: String
    var scenarioName: String
    /// Which scenario this run was, so leaderboards can be filtered.
    var scenarioKindRaw: String = ScenarioKind.construction.rawValue
    var seed: String
    var completedAt: Date

    init(playerName: String, result: RunResult, scenarioName: String, completedAt: Date = Date()) {
        self.playerName = playerName
        self.score = result.score
        self.profit = result.profit
        self.revenue = result.revenue
        self.days = result.days
        self.deadlineDays = result.deadlineDays
        self.wasOnTime = result.wasOnTime
        self.openDefects = result.openDefects
        self.idleCrewDays = result.idleCrewDays
        self.difficultyRaw = result.difficulty.rawValue
        self.personaRaw = result.persona.rawValue
        self.scenarioName = scenarioName
        self.scenarioKindRaw = result.scenario.rawValue
        self.seed = String(result.seed)
        self.completedAt = completedAt
    }

    var difficulty: Difficulty? { Difficulty(rawValue: difficultyRaw) }
    var persona: ClientPersona? { ClientPersona(rawValue: personaRaw) }
    var scenarioKind: ScenarioKind? { ScenarioKind(rawValue: scenarioKindRaw) }
}

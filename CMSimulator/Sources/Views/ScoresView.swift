//
//  ScoresView.swift
//  CMSimulator
//

import SwiftUI
import SwiftData

enum ScoreBoard: String, CaseIterable, Identifiable {
    case cost = "Cost Master"
    case time = "Time Master"
    case combined = "Construction Master"
    var id: String { rawValue }
}

struct ScoresView: View {
    @Query(sort: \ScoreEntry.completedAt, order: .reverse) private var scores: [ScoreEntry]
    let onExit: () -> Void

    @State private var board: ScoreBoard = .combined

    private var ranked: [ScoreEntry] {
        switch board {
        case .cost: return scores.sorted { $0.cost < $1.cost }
        case .time: return scores.sorted { $0.days < $1.days }
        case .combined:
            let maxCost = scores.map(\.cost).max() ?? 1
            let maxDays = scores.map(\.days).max() ?? 1
            return scores.sorted {
                ScoreEntry.combinedScore($0, maxCost: maxCost, maxDays: maxDays)
                    < ScoreEntry.combinedScore($1, maxCost: maxCost, maxDays: maxDays)
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(board.rawValue + " Leaderboard").font(.title2.bold())
                Spacer()
                Button("Exit", action: onExit)
            }

            Picker("Leaderboard", selection: $board) {
                ForEach(ScoreBoard.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if ranked.isEmpty {
                Spacer()
                Text("No runs yet - finish a simulation to appear here.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text("\(index + 1)").font(.headline).frame(width: 28)
                            VStack(alignment: .leading) {
                                Text(entry.playerName).font(.subheadline.bold())
                                Text(entry.completedAt, format: .dateTime.day().month().year())
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(entry.cost, format: .currency(code: "USD")).font(.caption.monospacedDigit())
                                Text("\(Int(entry.days))d").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding()
    }
}

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

    /// Short form for the segmented control, which truncates full names
    /// awkwardly on narrow screens - the full name still shows as the title.
    var shortTitle: String {
        switch self {
        case .cost: return "Cost"
        case .time: return "Time"
        case .combined: return "Overall"
        }
    }
}

struct ScoresView: View {
    @Query(sort: \ScoreEntry.completedAt, order: .reverse) private var scores: [ScoreEntry]
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isWide: Bool { horizontalSizeClass == .regular }

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
        VStack(spacing: isWide ? 20 : 12) {
            HStack {
                Text(board.rawValue + " Leaderboard").font(isWide ? .largeTitle.bold() : .title2.bold())
                Spacer()
                Button("Exit", action: onExit)
                    .controlSize(isWide ? .large : .regular)
            }

            Picker("Leaderboard", selection: $board) {
                ForEach(ScoreBoard.allCases) { Text($0.shortTitle).tag($0) }
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
                            Text("\(index + 1)").font(isWide ? .title2.bold() : .headline).frame(width: isWide ? 44 : 28)
                            VStack(alignment: .leading) {
                                Text(entry.playerName).font(isWide ? .title3.bold() : .subheadline.bold())
                                Text(entry.completedAt, format: .dateTime.day().month().year())
                                    .font(isWide ? .caption : .caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(entry.cost, format: .currency(code: "USD")).font(isWide ? .body.monospacedDigit() : .caption.monospacedDigit())
                                Text("\(Int(entry.days))d").font(isWide ? .caption : .caption2).monospacedDigit().foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, isWide ? 6 : 0)
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(isWide ? 32 : 16)
        .frame(maxWidth: isWide ? 700 : .infinity)
        .frame(maxWidth: .infinity)
    }
}

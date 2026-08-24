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

    /// Localized "<board> Leaderboard" title, built as one format string
    /// rather than concatenating a translated name with a translated
    /// "Leaderboard" suffix - word order isn't guaranteed to match across
    /// languages.
    var leaderboardTitle: String {
        switch self {
        case .cost: return String(localized: "Cost Leaderboard", comment: "Leaderboard screen title")
        case .time: return String(localized: "Time Leaderboard", comment: "Leaderboard screen title")
        case .combined: return String(localized: "Construction Leaderboard", comment: "Leaderboard screen title")
        }
    }

    /// Short form for the segmented control, which truncates full names
    /// awkwardly on narrow screens - the full name still shows as the title.
    var shortTitle: String {
        switch self {
        case .cost: return String(localized: "Cost", comment: "Leaderboard segmented control option")
        case .time: return String(localized: "Time", comment: "Leaderboard segmented control option")
        case .combined: return String(localized: "Overall", comment: "Leaderboard segmented control option")
        }
    }
}

struct ScoresView: View {
    @Query(sort: \ScoreEntry.completedAt, order: .reverse) private var scores: [ScoreEntry]
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
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
                Text(board.leaderboardTitle).font(isWide ? .largeTitle.bold() : .title2.bold())
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
                                Text(entry.cost, format: .currency(code: currencyCode)).font(isWide ? .body.monospacedDigit() : .caption.monospacedDigit())
                                Text(String(localized: "\(Int(entry.days))d", comment: "Days abbreviation on the leaderboard, e.g. '5d'")).font(isWide ? .caption : .caption2).monospacedDigit().foregroundStyle(.secondary)
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

//
//  ScoresView.swift
//  CMSimulator
//
//  The leaderboard, now ranked on profit. The old boards were Cost, Time
//  and a normalized sum of the two - none of which could tell a clean
//  delivery apart from a cheap one that handed over full of defects.
//

import SwiftUI
import SwiftData

enum ScoreBoard: String, CaseIterable, Identifiable {
    case profit, speed, margin
    var id: String { rawValue }

    var title: String {
        switch self {
        case .profit: return String(localized: "Profit Leaderboard", comment: "Leaderboard screen title")
        case .speed: return String(localized: "Delivery Leaderboard", comment: "Leaderboard screen title")
        case .margin: return String(localized: "Margin Leaderboard", comment: "Leaderboard screen title")
        }
    }

    var shortTitle: String {
        switch self {
        case .profit: return String(localized: "Profit", comment: "Leaderboard option")
        case .speed: return String(localized: "Speed", comment: "Leaderboard option")
        case .margin: return String(localized: "Margin", comment: "Leaderboard option")
        }
    }
}

struct ScoresView: View {
    @Query(sort: \ScoreEntry.completedAt, order: .reverse) private var scores: [ScoreEntry]
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
    private var isWide: Bool { horizontalSizeClass == .regular }

    @State private var board: ScoreBoard = .profit

    private var ranked: [ScoreEntry] {
        switch board {
        case .profit: return scores.sorted { $0.score > $1.score }
        case .speed: return scores.sorted { $0.days < $1.days }
        case .margin:
            return scores.sorted {
                let a = $0.revenue > 0 ? $0.profit / $0.revenue : -.infinity
                let b = $1.revenue > 0 ? $1.profit / $1.revenue : -.infinity
                return a > b
            }
        }
    }

    var body: some View {
        VStack(spacing: isWide ? 20 : 12) {
            HStack {
                Text(board.title).font(isWide ? .largeTitle.bold() : .title2.bold())
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
                Text("No runs yet — deliver a project to appear here.", comment: "Empty leaderboard")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { index, entry in
                        row(rank: index + 1, entry: entry)
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(isWide ? 32 : 16)
        .frame(maxWidth: isWide ? 700 : .infinity)
        .frame(maxWidth: .infinity)
    }

    private func row(rank: Int, entry: ScoreEntry) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(isWide ? .title2.bold() : .headline)
                .frame(width: isWide ? 40 : 26)
                .foregroundStyle(rank <= 3 ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName).font(isWide ? .title3.bold() : .subheadline.bold())
                HStack(spacing: 8) {
                    if let difficulty = entry.difficulty {
                        Text(difficulty.name)
                    }
                    Text(entry.completedAt, format: .dateTime.day().month().year())
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.profit, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                    .font((isWide ? Font.body : Font.caption).monospacedDigit().bold())
                    .foregroundStyle(entry.profit >= 0 ? .green : .red)
                HStack(spacing: 6) {
                    Text(String(localized: "\(Int(entry.days))d", comment: "Days abbreviation on the leaderboard"))
                    if entry.wasOnTime {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Image(systemName: "clock.badge.exclamationmark").foregroundStyle(.orange)
                    }
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, isWide ? 6 : 2)
    }
}

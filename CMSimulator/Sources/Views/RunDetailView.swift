//
//  RunDetailView.swift
//  CMSimulator
//
//  Reopens a saved run: the same P&L headline the debrief showed, how it
//  compares to the player's previous run of this scenario, and the site log
//  as it actually played out - so a finished run can be learned from, not
//  just ranked and forgotten.
//

import SwiftUI
import SwiftData

struct RunDetailView: View {
    let entry: ScoreEntry

    @Query private var allScores: [ScoreEntry]
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    /// The most recent earlier run of the same scenario, so this run reads
    /// as a step in a series rather than an isolated result.
    private var previousRun: ScoreEntry? {
        allScores
            .filter { $0.scenarioKind == entry.scenarioKind && $0.completedAt < entry.completedAt }
            .max { $0.completedAt < $1.completedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let previousRun { comparison(to: previousRun) }
                logSection
            }
            .padding(18)
        }
        .navigationTitle(entry.scenarioName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.playerName).font(.headline)
                    Text(entry.completedAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.profit, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(entry.profit >= 0 ? .green : .red)
                    if let difficulty = entry.difficulty {
                        Text(difficulty.name).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            HStack(spacing: 14) {
                Label(String(localized: "\(Int(entry.days)) days", comment: "Run detail stat"), systemImage: "calendar")
                Label(entry.wasOnTime
                      ? String(localized: "On time", comment: "Run detail stat")
                      : String(localized: "Late", comment: "Run detail stat"),
                      systemImage: entry.wasOnTime ? "checkmark.circle" : "clock.badge.exclamationmark")
                    .foregroundStyle(entry.wasOnTime ? .green : .orange)
                if entry.idleCrewDays > 0.5 {
                    Label(String(localized: "\(Int(entry.idleCrewDays)) idle days", comment: "Run detail stat"), systemImage: "hourglass")
                }
                if entry.openDefects > 0.5 {
                    Label(String(localized: "\(Int(entry.openDefects)) open defects", comment: "Run detail stat"), systemImage: "wrench.and.screwdriver")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func comparison(to previous: ScoreEntry) -> some View {
        let profitDelta = entry.profit - previous.profit
        let improved = profitDelta > 0
        return HStack(spacing: 8) {
            Image(systemName: improved ? "arrow.up.right" : "arrow.down.right")
                .foregroundStyle(improved ? .green : .red)
            Text(String(localized: "\(abs(profitDelta), format: .currency(code: currencyCode).precision(.fractionLength(0))) \(improved ? "better" : "worse") than your last \(entry.scenarioName) run", comment: "Run detail comparison to previous run"))
                .font(.subheadline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What happened", comment: "Run detail section header")
                .font(.headline)
                .padding(.bottom, 4)
            if entry.log.isEmpty {
                Text("No log was kept for this run.", comment: "Empty run log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.log) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: line.symbol)
                            .font(.caption)
                            .frame(width: 18)
                            .foregroundStyle(tint(for: line.tone))
                        Text(line.text)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(localized: "d\(line.day)", comment: "Site log day marker"))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
    }

    private func tint(for tone: SiteLogEntry.Tone) -> Color {
        switch tone {
        case .neutral: return .secondary
        case .good: return .green
        case .bad: return .red
        }
    }
}

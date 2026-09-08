//
//  ResultView.swift
//  CMSimulator
//
//  The debrief. The old screen showed final cost and elapsed time, which
//  could not express "finished cheap but the building is defective". This
//  is a P&L: what came in, every line of what went out, and the handful
//  of operational numbers that explain the result - idle crew days,
//  defects caught versus defects that reached handover.
//

import SwiftUI

struct ResultView: View {
    let result: RunResult
    let onSave: (String) -> Void
    let onRestart: () -> Void

    @State private var name: String = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    private var isWide: Bool { horizontalSizeClass == .regular }
    private var delivered: Bool { result.outcome == .delivered }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                banner
                if delivered { headline }
                ledgerCard
                operationsCard
                saveCard
            }
            .padding(isWide ? 32 : 18)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private var banner: some View {
        VStack(spacing: 6) {
            Image(systemName: delivered ? "flag.checkered" : "xmark.octagon.fill")
                .font(.system(size: 44))
                .foregroundStyle(delivered ? .green : .red)
            Text(delivered
                 ? String(localized: "Project handed over", comment: "Result title, success")
                 : String(localized: "Insolvent", comment: "Result title, failure"))
                .font(.title.bold())
            Text(delivered
                 ? String(localized: "Finished on day \(Int(result.days)) against a \(Int(result.deadlineDays))-day contract.", comment: "Result subtitle, success")
                 : String(localized: "You ran out of money on day \(Int(result.days)) with \(result.progress, format: .number.precision(.fractionLength(0)))% built.", comment: "Result subtitle, failure"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var headline: some View {
        VStack(spacing: 4) {
            Text("Profit", comment: "Result headline label")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(result.profit, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(.system(size: 40, weight: .bold).monospacedDigit())
                .foregroundStyle(result.profit >= 0 ? .green : .red)
            HStack(spacing: 12) {
                Label(result.margin.formatted(.percent.precision(.fractionLength(1))), systemImage: "percent")
                Label(result.wasOnTime
                      ? String(localized: "On time", comment: "Result badge")
                      : String(localized: "\(Int(result.days - result.deadlineDays)) days late", comment: "Result badge"),
                      systemImage: result.wasOnTime ? "checkmark.circle" : "clock.badge.exclamationmark")
                    .foregroundStyle(result.wasOnTime ? .green : .orange)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var ledgerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where the money went", comment: "Result section header")
                .font(.headline)

            row(String(localized: "Revenue", comment: "P&L line"), result.revenue, tint: .green, bold: true)
            Divider()
            ForEach(result.costs.lines, id: \.label) { line in
                row(line.label, -line.amount)
            }
            Divider()
            row(String(localized: "Total costs", comment: "P&L line"), -result.costs.total, bold: true)
            row(String(localized: "Profit", comment: "P&L line"), result.profit,
                tint: result.profit >= 0 ? .green : .red, bold: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ label: String, _ amount: Double, tint: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .subheadline)
            Spacer()
            Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font((bold ? Font.subheadline.bold() : Font.subheadline).monospacedDigit())
                .foregroundStyle(tint == .primary && amount < 0 ? .secondary : tint)
        }
    }

    private var operationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How it ran", comment: "Result section header")
                .font(.headline)

            if result.idleCrewDays > 0.5 {
                lesson(systemImage: "hourglass",
                       title: String(localized: "\(Int(result.idleCrewDays)) idle crew-days", comment: "Result operational stat"),
                       detail: String(localized: "Crews on full pay with nothing to build. Order materials earlier, or pay for a faster supplier.", comment: "Result lesson: idle crew"),
                       tint: result.idleCrewDays > 20 ? .red : .orange)
            }
            if result.openDefects > 0.5 {
                lesson(systemImage: "wrench.and.screwdriver.fill",
                       title: String(localized: "\(Int(result.openDefects)) defects reached handover", comment: "Result operational stat"),
                       detail: String(localized: "Caught during the build these cost a fraction as much. Quality inspections pay for themselves.", comment: "Result lesson: defects"),
                       tint: .red)
            }
            if result.resolvedDefects > 0.5 {
                lesson(systemImage: "checkmark.seal.fill",
                       title: String(localized: "\(Int(result.resolvedDefects)) defects caught early", comment: "Result operational stat"),
                       detail: String(localized: "Fixed in place instead of at handover.", comment: "Result lesson: defects caught"),
                       tint: .green)
            }
            lesson(systemImage: "person.2.fill",
                   title: String(localized: "\(result.finalCrewSize) on the books at the end", comment: "Result operational stat"),
                   detail: String(localized: "Client trust finished at \(result.clientTrust, format: .percent.precision(.fractionLength(0))).", comment: "Result trust detail"),
                   tint: .secondary)
            lesson(systemImage: "person.crop.square.filled.and.at.rectangle",
                   title: result.persona.name,
                   detail: String(localized: "\(result.difficulty.name) difficulty · seed \(String(result.seed % 1_000_000))", comment: "Result run parameters"),
                   tint: .secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func lesson(systemImage: String, title: String, detail: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var saveCard: some View {
        VStack(spacing: 12) {
            if delivered {
                HStack {
                    Text("Leaderboard score", comment: "Result label")
                        .font(.subheadline)
                    Spacer()
                    Text(result.score, format: .number.precision(.fractionLength(0)))
                        .font(.headline.monospacedDigit())
                }
                TextField(String(localized: "Your name", comment: "Score name field"), text: $name)
                    .textFieldStyle(.roundedBorder)
                Button {
                    onSave(name)
                } label: {
                    Text("Save score", comment: "Save score button").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            Button {
                onRestart()
            } label: {
                Text("New contract", comment: "Start a new run button").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

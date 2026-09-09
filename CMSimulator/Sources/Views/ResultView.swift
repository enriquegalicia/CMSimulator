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
                exitCard
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
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    /// Reads as the end of whichever kind of run this was.
    private var subtitle: String {
        guard delivered else {
            return String(localized: "You ran out of money on day \(Int(result.days)) with \(result.progress, format: .number.precision(.fractionLength(0)))% built.", comment: "Result subtitle, failure")
        }
        if result.scenario == .startup {
            guard let launchDay = result.launchDay else {
                return String(localized: "You reached the exit without ever launching. A product nobody used is worth nothing.", comment: "Result subtitle, never launched")
            }
            return String(localized: "Launched on day \(Int(launchDay)), sold on day \(Int(result.days)).", comment: "Result subtitle, startup exit")
        }
        return String(localized: "Finished on day \(Int(result.days)) against a \(Int(result.deadlineDays))-day contract.", comment: "Result subtitle, success")
    }

    @ViewBuilder
    private var exitCard: some View {
        if let offer = result.exitOffer {
            VStack(alignment: .leading, spacing: 8) {
                Text("The offer", comment: "Result section header")
                    .font(.headline)
                row(String(localized: "Customers at exit", comment: "Exit line"), offer.customers, isCurrency: false)
                row(String(localized: "Annual recurring revenue", comment: "Exit line"), offer.annualRecurringRevenue)
                HStack {
                    Text(String(localized: "Multiple, set by growth", comment: "Exit line")).font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f×", offer.multiple)).font(.subheadline.monospacedDigit())
                }
                row(String(localized: "Headline valuation", comment: "Exit line"), offer.headlineValuation, bold: true)
                if offer.diligenceHaircut > 0 {
                    row(String(localized: "Diligence haircut, tech debt", comment: "Exit line"), -offer.diligenceHaircut, tint: .red)
                }
                Divider()
                row(String(localized: "Company sold for", comment: "Exit line"), offer.netValuation, bold: true)
                HStack {
                    Text(String(localized: "Your share after \(result.capitalRaised, format: .currency(code: currencyCode).precision(.fractionLength(0))) raised", comment: "Exit line: founder equity")).font(.subheadline)
                    Spacer()
                    Text(result.founderEquity, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.monospacedDigit())
                }
                row(String(localized: "You took home", comment: "Exit line"),
                    offer.netValuation * result.founderEquity, tint: .green, bold: true)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
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

    private func row(_ label: String, _ amount: Double, tint: Color = .primary,
                     bold: Bool = false, isCurrency: Bool = true) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .subheadline)
            Spacer()
            Text(isCurrency
                 ? amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
                 : Int(amount).formatted())
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
            lesson(systemImage: result.scenario.symbolName,
                   title: String(localized: "\(result.scenario.name) · \(result.persona.name(in: result.scenario))", comment: "Result scenario and counterparty"),
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

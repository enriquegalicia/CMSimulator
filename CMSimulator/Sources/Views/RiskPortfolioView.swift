//
//  RiskPortfolioView.swift
//  CMSimulator
//
//  Risk as a portfolio rather than a gauge. Each mitigation covers one
//  named class of incident, so the player is deciding which tail to buy
//  protection against with money that has other claims on it - and will
//  often pay for cover they never need, which is the point.
//

import SwiftUI

struct RiskPortfolioView: View {
    let scenario: ScenarioKind
    let held: Set<MitigationClass>
    let riskLevel: Int
    let insuranceCoverage: Double
    let spendingPower: Double
    let exposure: Double
    let forecast: RiskForecast?
    let register: [RiskRegisterRow]
    let incidentsFired: Int
    let nearMisses: Int
    let incidentsPrevented: Int
    let savedByMitigation: Double
    let savedByInsurance: Double
    let savedByNearMiss: Double
    let onBuy: (MitigationClass) -> Void
    let onExit: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    private var exposureLabel: String {
        switch exposure {
        case ..<0.9: return String(localized: "Well run", comment: "Site exposure level")
        case ..<1.3: return String(localized: "Normal", comment: "Site exposure level")
        case ..<1.8: return String(localized: "Elevated", comment: "Site exposure level")
        default: return String(localized: "Dangerous", comment: "Site exposure level")
        }
    }

    private var exposureTint: Color {
        switch exposure {
        case ..<0.9: return .green
        case ..<1.3: return .primary
        case ..<1.8: return .orange
        default: return .red
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Exposure", comment: "Risk sheet label")
                        Spacer()
                        Text(exposureLabel)
                            .font(.subheadline.bold())
                            .foregroundStyle(exposureTint)
                    }
                    if let forecast {
                        Label(String(localized: "\(forecast.severityLabel) \(forecast.mitigationClass.name(in: scenario).lowercased()) risk in about \(Int(forecast.daysAway)) days", comment: "Planning forecast warning"),
                              systemImage: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } footer: {
                    Text("Overtime, overcrowded workstreams and low morale all raise exposure. Incidents can be made rarer and milder, but never switched off.", comment: "Risk sheet explanation")
                        .font(.caption)
                }

                Section {
                    ForEach(register) { row in
                        registerRow(row)
                    }
                } header: {
                    Text("Risk register", comment: "Risk sheet section header")
                } footer: {
                    Text("Ranked by likelihood against what it would cost you. The order changes as you work — overtime pulls safety up the list, a bad relationship pulls the client up it.", comment: "Risk register explanation")
                        .font(.caption)
                }

                Section {
                    LabeledContent {
                        Text(incidentsFired.formatted()).font(.subheadline.monospacedDigit().bold())
                    } label: {
                        Label(String(localized: "Incidents that landed", comment: "Risk tally"), systemImage: "bolt.fill")
                    }
                    LabeledContent {
                        Text(nearMisses.formatted()).font(.subheadline.monospacedDigit().bold())
                    } label: {
                        Label(String(localized: "Near misses", comment: "Risk tally"), systemImage: "exclamationmark.triangle")
                    }
                    LabeledContent {
                        Text(incidentsPrevented.formatted()).font(.subheadline.monospacedDigit().bold())
                    } label: {
                        Label(String(localized: "Stopped by cover you held", comment: "Risk tally"), systemImage: "shield.lefthalf.filled")
                    }
                    if totalAvoided > 1 {
                        LabeledContent {
                            Text(totalAvoided, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                .font(.subheadline.monospacedDigit().bold())
                                .foregroundStyle(.green)
                        } label: {
                            Label(String(localized: "Losses avoided", comment: "Risk tally"), systemImage: "checkmark.shield.fill")
                        }
                    }
                } header: {
                    Text("This run so far", comment: "Risk sheet section header")
                } footer: {
                    Text("A near miss is the same roll without the bill. Run the job well and you get warnings; run it hot and you get invoices.", comment: "Near miss explanation")
                        .font(.caption)
                }

                if riskLevel > 0 {
                    Section {
                        ForEach(MitigationClass.allCases) { mitigation in
                            mitigationRow(mitigation)
                        }
                    } header: {
                        Text("Mitigations", comment: "Risk sheet section header")
                    } footer: {
                        Text("Each one cuts the odds and the damage for its own class of incident only.", comment: "Mitigations explanation")
                            .font(.caption)
                    }

                    Section {
                        HStack {
                            Label(String(localized: "Insurance", comment: "Risk sheet label"), systemImage: "umbrella.fill")
                            Spacer()
                            Text(insuranceCoverage, format: .percent.precision(.fractionLength(0)))
                                .font(.subheadline.monospacedDigit().bold())
                        }
                    } footer: {
                        Text("Comes with the Risk capability. Covers this share of any incident above the deductible, in exchange for a daily premium.", comment: "Insurance explanation")
                            .font(.caption)
                    }
                } else {
                    Section {
                        Label(String(localized: "Staff the Risk capability to buy mitigations and insurance.", comment: "Risk locked hint"),
                              systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "Risk", comment: "Risk sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onExit)
                }
            }
        }
    }

    private var totalAvoided: Double { savedByMitigation + savedByInsurance + savedByNearMiss }

    /// One register line. Probability is shown as a plain interval - "about
    /// every 24 days" reads far better than "4.1% per day".
    private func registerRow(_ row: RiskRegisterRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: row.mitigationClass.symbolName)
                .foregroundStyle(row.isCovered ? Color.green : .orange)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.mitigationClass.name(in: scenario))
                    .font(.subheadline.bold())
                Text(row.daysBetween.isFinite
                     ? String(localized: "About every \(Int(row.daysBetween)) days", comment: "Risk register frequency")
                     : String(localized: "Not expected", comment: "Risk register frequency when impossible"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                Text(row.worstCaseCost, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                    .font(.subheadline.monospacedDigit())
                Text(row.isCovered
                     ? String(localized: "covered", comment: "Risk register cover state")
                     : String(localized: "uncovered", comment: "Risk register cover state"))
                    .font(.caption2)
                    .foregroundStyle(row.isCovered ? .green : .orange)
            }
        }
        .padding(.vertical, 2)
    }

    private func mitigationRow(_ mitigation: MitigationClass) -> some View {
        let owned = held.contains(mitigation)
        let affordable = mitigation.purchaseCost <= spendingPower
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(mitigation.name(in: scenario), systemImage: mitigation.symbolName)
                    .font(.subheadline.bold())
                Spacer()
                if owned {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            Text(mitigation.blurb(in: scenario))
                .font(.caption2)
                .foregroundStyle(.secondary)
            if owned {
                Text(String(localized: "In place — \(mitigation.dailyUpkeep, format: .currency(code: currencyCode).precision(.fractionLength(0)))/day", comment: "Mitigation held status"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    onBuy(mitigation)
                } label: {
                    Text(String(localized: "Put in place — \(mitigation.purchaseCost, format: .currency(code: currencyCode).precision(.fractionLength(0))) plus \(mitigation.dailyUpkeep, format: .currency(code: currencyCode).precision(.fractionLength(0)))/day", comment: "Buy mitigation button"))
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!affordable)
            }
        }
        .padding(.vertical, 2)
    }
}

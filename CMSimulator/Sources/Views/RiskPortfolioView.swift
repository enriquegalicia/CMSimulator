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
    let held: Set<MitigationClass>
    let riskLevel: Int
    let insuranceCoverage: Double
    let spendingPower: Double
    let exposure: Double
    let forecast: RiskForecast?
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
                        Text("Site exposure", comment: "Risk sheet label")
                        Spacer()
                        Text(exposureLabel)
                            .font(.subheadline.bold())
                            .foregroundStyle(exposureTint)
                    }
                    if let forecast {
                        Label(String(localized: "\(forecast.severityLabel) \(forecast.mitigationClass.name.lowercased()) risk in about \(Int(forecast.daysAway)) days", comment: "Planning forecast warning"),
                              systemImage: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } footer: {
                    Text("Overtime, crowded crews and low morale all raise exposure. Incidents can be made rarer and milder, but never switched off.", comment: "Risk sheet explanation")
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

    private func mitigationRow(_ mitigation: MitigationClass) -> some View {
        let owned = held.contains(mitigation)
        let affordable = mitigation.purchaseCost <= spendingPower
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(mitigation.name, systemImage: mitigation.symbolName)
                    .font(.subheadline.bold())
                Spacer()
                if owned {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            Text(mitigation.blurb)
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

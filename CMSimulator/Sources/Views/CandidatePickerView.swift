//
//  CandidatePickerView.swift
//  CMSimulator
//
//  The hiring decision. The old sheet showed four multipliers that all
//  sat within a few percent of 1.0, so the choice washed out. These
//  candidates differ on axes that visibly change the run: raw output,
//  what they cost every single day, how fast they learn, how much rework
//  they leave behind, and how likely they are to still be here in a month.
//

import SwiftUI

struct CandidatePickerView: View {
    let request: HiringRequest
    let spendingPower: Double
    /// What the company turned out to be, once Discovery has said so.
    /// Nil means you are still hiring blind, which is the point.
    let venture: VentureKind?
    let onSelect: (Candidate) -> Void
    let onCancel: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(request.candidates) { candidate in
                        candidateRow(candidate)
                    }
                } header: {
                    Text("Applicants", comment: "Candidate picker section header")
                } footer: {
                    footer
                }
            }
            .navigationTitle(String(localized: "Hire for \(request.packageTitle)", comment: "Candidate picker sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("A signing cost comes out of cash today. The wage comes out every day after that, whether or not there is work for them to do.", comment: "Candidate picker explanation")
            if request.marketWageFactor > 1.08 {
                Label(String(localized: "Tight labour market — everyone is quoting high right now.", comment: "Candidate picker market warning"),
                      systemImage: "arrow.up.right")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption)
    }

    private func candidateRow(_ candidate: Candidate) -> some View {
        let worker = candidate.worker
        let affordable = worker.signingCost <= spendingPower
        return Button {
            onSelect(candidate)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(worker.name).font(.headline)
                    Spacer()
                    Text(worker.dailyWage, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .font(.subheadline.monospacedDigit().bold())
                    Text("/day", comment: "Per-day wage suffix")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if worker.role != .generalist || venture != nil {
                    HStack(spacing: 5) {
                        Text(worker.role.name)
                            .font(.caption.bold())
                        if let venture {
                            let wanted = venture.valuedRoles.contains(worker.role)
                            Label(wanted
                                  ? String(localized: "what you need", comment: "Candidate role fit, good")
                                  : String(localized: "not what you need", comment: "Candidate role fit, poor"),
                                  systemImage: wanted ? "checkmark.circle.fill" : "minus.circle")
                                .font(.caption2)
                                .foregroundStyle(wanted ? .green : .orange)
                        } else {
                            Text("— you do not know yet whether this matters", comment: "Candidate role fit, unknown")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                Text(worker.archetype.traitName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(worker.archetype.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    barStat(String(localized: "Output", comment: "Candidate stat"), worker.skill / 1.5, .blue)
                    barStat(String(localized: "Learns", comment: "Candidate stat"), worker.archetype.learningRate / 2, .purple)
                    barStat(String(localized: "Clean work", comment: "Candidate stat"), 1 - worker.archetype.defectRate / 0.15, .green)
                    barStat(String(localized: "Resilient", comment: "Candidate stat"), 1 - (worker.archetype.burnoutSensitivity - 0.7) / 0.9, .orange)
                }

                HStack(spacing: 12) {
                    Label(String(localized: "Signing \(worker.signingCost, format: .currency(code: currencyCode).precision(.fractionLength(0)))", comment: "Candidate signing cost"),
                          systemImage: "creditcard")
                    if worker.experience > 0.3 {
                        Label(String(localized: "Experienced", comment: "Candidate badge"), systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if !affordable {
                    Label(String(localized: "Cannot cover the signing cost", comment: "Candidate unaffordable warning"),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
        .opacity(affordable ? 1 : 0.55)
    }

    private func barStat(_ label: String, _ value: Double, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(2, geo.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

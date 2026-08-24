//
//  CandidatePickerView.swift
//  CMSimulator
//
//  The candidate-picker sheet: three named hires with a legible tradeoff,
//  replacing the old blind +1 hire button. See Candidate.swift.
//

import SwiftUI

struct CandidatePickerView: View {
    let request: HiringRequest
    let onSelect: (Candidate) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List(request.candidates) { candidate in
                Button {
                    onSelect(candidate)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.name).font(.headline)
                        Text(candidate.trait).font(.subheadline).foregroundStyle(.secondary)
                        statLine(candidate)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(String(localized: "Hire for \(request.packageTitle)", comment: "Candidate picker sheet title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // Best-of-the-three per axis, not a fixed threshold - a 0.94 cost
    // factor only reads as "good" relative to the other two offers, not
    // against some absolute cutoff.
    private var bestCost: Double { request.candidates.map(\.costFactor).min() ?? 1 }
    private var bestRate: Double { request.candidates.map(\.rateFactor).max() ?? 1 }
    private var bestRisk: Double { request.candidates.map(\.riskFactor).max() ?? 1 }
    private var bestQuality: Double { request.candidates.map(\.qualityFactor).max() ?? 1 }

    private func statLine(_ candidate: Candidate) -> some View {
        HStack(spacing: 12) {
            statBadge(String(localized: "Cost", comment: "Candidate stat label"), candidate.costFactor, isBest: candidate.costFactor == bestCost)
            statBadge(String(localized: "Rate", comment: "Candidate stat label"), candidate.rateFactor, isBest: candidate.rateFactor == bestRate)
            statBadge(String(localized: "Risk", comment: "Candidate stat label"), candidate.riskFactor, isBest: candidate.riskFactor == bestRisk)
            statBadge(String(localized: "Quality", comment: "Candidate stat label"), candidate.qualityFactor, isBest: candidate.qualityFactor == bestQuality)
        }
        .font(.caption2.monospacedDigit())
    }

    private func statBadge(_ title: String, _ factor: Double, isBest: Bool) -> some View {
        Text(String(localized: "\(title) \(factor, specifier: "%.2f")", comment: "Stat badge, e.g. 'Cost 1.02' - title is already localized text"))
            .foregroundStyle(isBest ? .green : .secondary)
            .fontWeight(isBest ? .semibold : .regular)
    }
}

//
//  VendorBidPickerView.swift
//  CMSimulator
//
//  The vendor-bid-picker sheet: lowest-bid-vs-best-value, replacing
//  Procurement's old single "buy = one fixed random nudge" purchase.
//  See VendorBid.swift.
//

import SwiftUI

struct VendorBidPickerView: View {
    let request: VendorBidRequest
    let onSelect: (VendorBid) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List(request.bids) { bid in
                Button {
                    onSelect(bid)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bid.vendorName).font(.headline)
                        Text(bid.pitch).font(.subheadline).foregroundStyle(.secondary)
                        statLine(bid)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose a Vendor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var bestCost: Double { request.bids.map(\.costFactor).min() ?? 1 }
    private var bestDiscount: Double { request.bids.map(\.alliedDiscountFactor).min() ?? 1 }
    private var bestQuality: Double { request.bids.map(\.qualityFactor).max() ?? 1 }

    private func statLine(_ bid: VendorBid) -> some View {
        HStack(spacing: 12) {
            statBadge(String(localized: "Cost", comment: "Vendor bid stat label"), bid.costFactor, isBest: bid.costFactor == bestCost)
            statBadge(String(localized: "Relationship", comment: "Vendor bid stat label"), bid.alliedDiscountFactor, isBest: bid.alliedDiscountFactor == bestDiscount)
            statBadge(String(localized: "Quality", comment: "Vendor bid stat label"), bid.qualityFactor, isBest: bid.qualityFactor == bestQuality)
        }
        .font(.caption2.monospacedDigit())
    }

    private func statBadge(_ title: String, _ factor: Double, isBest: Bool) -> some View {
        Text(String(localized: "\(title) \(factor, specifier: "%.2f")", comment: "Stat badge, e.g. 'Cost 1.02' - title is already localized text"))
            .foregroundStyle(isBest ? .green : .secondary)
            .fontWeight(isBest ? .semibold : .regular)
    }
}

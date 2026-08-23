//
//  VendorBid.swift
//  CMSimulator
//
//  Replaces Procurement's old flat "buy = one fixed random nudge" purchase
//  with the classic PM tradeoff: lowest bid saves money now but risks
//  quality, best-value costs more but pays off through the relationship
//  (cheaper Planning/Risk booster pricing going forward) and steadier
//  quality. Three bids are generated each time Procurement is purchased -
//  the archetypes are fixed so the tradeoff stays legible, only the vendor
//  name and exact factor within each band are randomized per offer.
//

import Foundation

struct VendorBid: Identifiable {
    let id = UUID()
    let vendorName: String
    let pitch: String
    /// Applied to every work package's cost.
    let costFactor: Double
    /// Applied to Planning's and Risk's booster price - a real vendor
    /// relationship makes the rest of procurement cheaper too.
    let alliedDiscountFactor: Double
    /// Applied to the quality gauge.
    let qualityFactor: Double
}

/// Drives the vendor-bid-picker sheet.
struct VendorBidRequest: Identifiable {
    let id = UUID()
    let bids: [VendorBid]
}

private struct BidArchetype {
    let pitch: String
    let costRange: ClosedRange<Double>
    let alliedDiscountRange: ClosedRange<Double>
    let qualityRange: ClosedRange<Double>
}

extension VendorBid {
    private static let vendorNames = [
        "Ironclad Supply Co.", "Meridian Materials", "BuildRight Partners",
        "Cornerstone Vendors", "Apex Sourcing Group", "Foundry & Co.",
    ]

    private static let archetypes = [
        BidArchetype(
            pitch: "Lowest bid",
            costRange: 0.94...0.97, alliedDiscountRange: 0.99...1.00,
            qualityRange: 0.97...0.99
        ),
        BidArchetype(
            pitch: "Balanced value",
            costRange: 0.97...0.995, alliedDiscountRange: 0.98...1.00,
            qualityRange: 0.995...1.005
        ),
        BidArchetype(
            pitch: "Premium & reliable",
            costRange: 0.99...1.00, alliedDiscountRange: 0.96...0.98,
            qualityRange: 1.01...1.04
        ),
    ]

    /// Always offers all three archetypes (low/balanced/premium) so the
    /// tradeoff is consistent run to run, with fresh vendor names each time.
    static func randomPool() -> [VendorBid] {
        let pickedNames = vendorNames.shuffled().prefix(archetypes.count)
        return zip(archetypes, pickedNames).map { archetype, vendorName in
            VendorBid(
                vendorName: vendorName,
                pitch: archetype.pitch,
                costFactor: .random(in: archetype.costRange),
                alliedDiscountFactor: .random(in: archetype.alliedDiscountRange),
                qualityFactor: .random(in: archetype.qualityRange)
            )
        }
    }
}

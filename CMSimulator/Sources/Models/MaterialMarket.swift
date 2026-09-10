//
//  MaterialMarket.swift
//  CMSimulator
//
//  Acquisitions, rebuilt. The old Procurement booster applied a one-off
//  random multiplier to every package's cost and was otherwise identical
//  to the other five boosters.
//
//  Here materials are physical and late. Work stops when a package runs
//  dry, and the crew standing in the mud is still on full pay - which is
//  what makes ordering ahead a real decision instead of a menu. Prices
//  move on a random walk with occasional shocks, so the player is taking
//  a position, not paying a fixed rate: buy spot and ride it, or pay a
//  premium to lock the index for a while and stop caring.
//

import Foundation

// MARK: - Price index

/// A commodity index that drifts, with occasional supply shocks. Starts
/// at 1.0; every material price in the game is multiplied by it.
struct MaterialMarket {
    private(set) var index: Double = 1.0
    /// Rolling history for the sparkline, one sample per simulated day.
    private(set) var history: [Double] = [1.0]
    /// While > 0, orders price at `lockedIndex` instead of the spot index.
    private(set) var lockDaysRemaining: Double = 0
    private(set) var lockedIndex: Double = 1.0
    /// Days until the current shock decays out. Purely cosmetic - it lets
    /// the UI explain a spike instead of the number just jumping.
    private(set) var shockDaysRemaining: Double = 0
    private(set) var lastShockWasSpike = false

    let volatility: Double
    private var daysAccumulated: Double = 0

    init(volatility: Double) {
        self.volatility = volatility
    }

    var isLocked: Bool { lockDaysRemaining > 0 }
    /// The index an order actually prices at right now.
    var effectiveIndex: Double { isLocked ? lockedIndex : index }

    var trend: Double {
        guard history.count > 5 else { return 0 }
        let recent = history.suffix(6)
        return (recent.last! - recent.first!) / recent.first!
    }

    mutating func advance(days: Double) {
        if lockDaysRemaining > 0 { lockDaysRemaining = max(0, lockDaysRemaining - days) }
        if shockDaysRemaining > 0 { shockDaysRemaining = max(0, shockDaysRemaining - days) }

        // Mean-reverting geometric walk: without the pull back toward 1.0
        // a long run drifts arbitrarily far and the numbers stop reading
        // as prices.
        let reversion = (1.0 - index) * 0.02 * days
        let noise = Double.random(in: -1...1) * volatility * days.squareRoot()
        index = max(0.55, min(2.4, index * (1 + noise) + reversion))

        daysAccumulated += days
        while daysAccumulated >= 1 {
            daysAccumulated -= 1
            history.append(index)
            if history.count > 120 { history.removeFirst() }
        }
    }

    /// A supply shock - fired by events, not by the walk.
    mutating func applyShock(magnitude: Double, isSpike: Bool) {
        index = max(0.55, min(2.4, index * (isSpike ? 1 + magnitude : 1 - magnitude)))
        shockDaysRemaining = 8
        lastShockWasSpike = isSpike
    }

    /// Locks today's index for `days`. The premium is charged by the
    /// caller - this only records the hedge.
    mutating func lockPrice(for days: Double) {
        lockedIndex = index
        lockDaysRemaining = days
    }

    /// What locking costs, as a fraction of the order value it protects.
    /// Rises with volatility: insurance is dearer when the risk is real.
    var lockPremiumRate: Double { 0.03 + volatility * 1.4 }
}

// MARK: - Vendors

/// A supplier's standing offer. Unlike the old one-shot bid, a vendor is
/// a relationship the player keeps using: every order to them prices and
/// delivers by these terms.
struct Vendor: Identifiable {
    let id = UUID()
    let name: String
    let pitch: String
    /// Multiplier on the base material price.
    let priceFactor: Double
    /// Multiplier on the package's base lead time.
    let leadTimeFactor: Double
    /// Chance per order that delivery slips badly.
    let unreliability: Double
    /// Defects introduced per unit of material, added to the crew's own.
    let defectPerUnit: Double

    var reliabilityLabel: String {
        switch unreliability {
        case ..<0.06: return String(localized: "Dependable", comment: "Vendor reliability label")
        case ..<0.16: return String(localized: "Usually on time", comment: "Vendor reliability label")
        default: return String(localized: "Slips often", comment: "Vendor reliability label")
        }
    }
}

extension Vendor {
    /// Localized as one comma-separated list, same reasoning as the worker
    /// name pools: suppliers should sound like firms the player would
    /// actually ring up.
    private static var names: [String] {
        NamePool.split(String(localized: "Ironclad Supply Co.,Meridian Materials,BuildRight Partners,Cornerstone Vendors,Apex Sourcing Group,Foundry & Co.,Delta Trade Supply,Northgate Aggregates,Halberd Steel,Kestrel Builders Merchants",
                            comment: "Comma-separated pool of material supplier company names. Replace with company names that read naturally in your language - do not translate these literally."))
    }

    /// Three standing offers: the classic cheap/balanced/premium spread,
    /// but the axes that matter are lead time and reliability, not just
    /// price. "Lowest bid" is a trap that idles your crews.
    static func standingPanel() -> [Vendor] {
        let picked = names.shuffled().prefix(3)
        let specs: [(String, Double, Double, Double, Double)] = [
            (String(localized: "Lowest price, slow and patchy", comment: "Vendor pitch"), 0.84, 1.55, 0.24, 0.008),
            (String(localized: "Balanced terms", comment: "Vendor pitch"), 1.00, 1.00, 0.10, 0.003),
            (String(localized: "Premium, fast and dependable", comment: "Vendor pitch"), 1.26, 0.60, 0.03, 0.0005),
        ]
        return zip(picked, specs).map { name, spec in
            Vendor(name: name, pitch: spec.0,
                   priceFactor: spec.1 * Double.random(in: 0.97...1.03),
                   leadTimeFactor: spec.2 * Double.random(in: 0.95...1.05),
                   unreliability: spec.3,
                   defectPerUnit: spec.4)
        }
    }
}

// MARK: - Orders

struct MaterialOrder: Identifiable {
    let id = UUID()
    let packageID: String
    let vendorName: String
    let quantity: Double
    let pricePaid: Double
    /// Simulated day the order lands.
    var arrivalDay: Double
    let orderedDay: Double
    /// Carried through to delivery so vendor quality lands as defects on
    /// the work actually built from this batch.
    let vendorDefectPerUnit: Double
    /// Where a stock consignment was bought. Nil for construction
    /// materials, which have no origin decision attached.
    var origin: SourceOrigin? = nil
    var hasSlipped = false

    func daysOut(from currentDay: Double) -> Double { max(0, arrivalDay - currentDay) }
}

/// Drives the ordering sheet.
struct MaterialOrderRequest: Identifiable {
    let id: String
    let packageTitle: String
    let vendors: [Vendor]
    /// Units still needed to finish the package, net of stock and orders
    /// already in flight - the "order exactly enough" shortcut.
    let suggestedQuantity: Double
    let baseCostPerUnit: Double
    let baseLeadTimeDays: Double
    let marketIndex: Double
    let isLocked: Bool
    /// What this discipline buys, so the order sheet can say "Pipework,
    /// fixtures & ductwork" rather than a generic "Order".
    let inputName: String?
}

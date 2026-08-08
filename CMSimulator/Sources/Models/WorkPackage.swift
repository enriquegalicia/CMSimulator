//
//  WorkPackage.swift
//  CMSimulator
//
//  Swift port of Recurso - one of the 6 construction work packages
//  (Design, Structure, Engineering, Construction, IHS & IAA, IES & IEL).
//

import Foundation

struct WorkPackage: Identifiable {
    let id: String
    let title: String
    let imageName: String
    let initialCost: Double
    let units: Double
    let initialRate: Double
    /// 0...100 - the % of overall project progress at which this package unlocks.
    var startThreshold: Double

    var cost: Double
    var rate: Double
    var cumulativeCost: Double = 0
    var cumulativeRateEarned: Double = 0
    var purchasedCount: Int = 0
    var unitsCompleted: Double = 0
    var isUnlocked: Bool = false
    var totalSpent: Double = 0

    init(id: String, title: String, imageName: String, initialCost: Double, units: Double, initialRate: Double, startThreshold: Double) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.initialCost = initialCost
        self.units = units
        self.initialRate = initialRate
        self.startThreshold = startThreshold
        self.cost = initialCost
        self.rate = initialRate
    }

    var progress: Double {
        units > 0 ? min(unitsCompleted / units, 1.0) : 0
    }

    /// Mirrors the original's clamps: cost stays within [initial/2, initial*3],
    /// rate stays within [initial*0.3, initial*1.8].
    mutating func clampCost() {
        cost = min(max(cost, initialCost / 2), initialCost * 3)
    }

    mutating func clampRate() {
        rate = min(max(rate, initialRate * 0.3), initialRate * 1.8)
    }
}

//
//  WorkPackage.swift
//  CMSimulator
//
//  One work stream's mutable run state. The static definition lives in
//  ProjectBrief.WorkStreamSpec, so this holds only what changes.
//
//  Gone from the old version: `cost`, `rate`, `headcount` and the clamps
//  around them. Those were the degenerate core - a package-level rate
//  multiplied by a headcount integer, charged at a package-level cost
//  multiplied by the same integer, so crew size cancelled out of the
//  total exactly. Output is now the sum of individual workers' output
//  (see Worker.swift) shaped by crowding, mentoring and materials.
//

import Foundation

struct WorkPackage: Identifiable {
    typealias ID = String

    let spec: WorkStreamSpec
    var unitsCompleted: Double = 0
    /// Units of material on site and available to install.
    var materialStock: Double = 0
    /// Latent defects built into the work. Invisible to the player until
    /// Quality inspects, or until the client finds them at handover.
    var defectDebt: Double = 0
    /// Defects surfaced by inspection and already paid to fix. Kept so
    /// the player can see Quality earning its upkeep.
    var defectsResolved: Double = 0
    var isUnlocked: Bool = false
    /// Started early via Planning's fast-track, at a defect penalty.
    var isFastTracked: Bool = false
    /// 0...1. Overtime buys output and burns morale.
    var overtime: Double = 0
    /// Extra scope handed down by client change orders. Real additional
    /// work, so a change order is a schedule problem and not a windfall.
    var addedScope: Double = 0
    /// Material defect rate carried by whatever is currently on site,
    /// set by deliveries. A cheap supplier shows up later as rework.
    var materialDefectPerUnit: Double = 0
    /// Cumulative days this package's crew stood idle waiting on
    /// materials while drawing full pay. Surfaced on the results screen
    /// because it is the clearest possible lesson about lead times.
    var idleCrewDays: Double = 0

    var id: ID { spec.id }
    var title: String { spec.title }
    var imageName: String { spec.imageName }
    var units: Double { spec.units + addedScope }
    var optimalCrew: Int { spec.optimalCrew }

    var progress: Double { units > 0 ? min(unitsCompleted / units, 1) : 0 }
    var isComplete: Bool { unitsCompleted >= units - 0.0001 }
    var unitsRemaining: Double { max(0, units - unitsCompleted) }

    /// Whether this stream consumes a physical input at all. A trading
    /// business buys goods through the same supplier panel, but its work
    /// streams are people opening product lines and consume nothing.
    var consumesMaterials: Bool { spec.materialUnitsPerWorkUnit > 0 }

    /// True when there is work left and nothing to build it out of. Only
    /// meaningful for streams that actually consume something.
    var isStarvedOfMaterials: Bool {
        consumesMaterials && !isComplete && materialStock < 0.01
    }

    /// Crowding: beyond the optimal crew size, output per head falls
    /// away. Twenty people on a slab is not twenty times one person on a
    /// slab, and this is what stops "hire everyone immediately" from
    /// being the dominant line it used to be.
    static func congestionFactor(crewSize: Int, optimalCrew: Int) -> Double {
        guard crewSize > optimalCrew, optimalCrew > 0 else { return 1 }
        return pow(Double(optimalCrew) / Double(crewSize), 0.6)
    }

    /// Mentoring drag: everyone already on the crew slows down while new
    /// hires find their feet.
    static func mentoringDrag(greenCount: Int) -> Double {
        guard greenCount > 0 else { return 1 }
        return max(WorkerTuning.minimumCrewDragMultiplier,
                   1 - WorkerTuning.mentoringDragPerGreenHire * Double(greenCount))
    }

    /// Overtime buys up to 45% more output.
    static func overtimeFactor(_ overtime: Double) -> Double {
        1 + 0.45 * min(max(overtime, 0), 1)
    }
}

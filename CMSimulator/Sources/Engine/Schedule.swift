//
//  Schedule.swift
//  CMSimulator
//
//  The critical path. Added for build 3 (2026-10-15).
//
//  The app is called Critical Path and, until now, never showed one. This
//  turns the run state into a schedule a project manager would recognise:
//  for every work stream, when it started (or can start), when it will
//  finish at the pace its crew is actually working, and how much float it
//  has - how many days it could slip before it moved the finish date. The
//  stream with no float is the one that sets the date, and the board says
//  why and what would move it.
//
//  Two kinds of forecast, kept visibly apart:
//  · a *forecast* comes from the crew's real output today;
//  · a *planned* bar is an assumption - an unstaffed or not-yet-started
//    stream, timed as if it got its ideal crew working at your current
//    average pace. A scheduler has to assume something, and saying so is
//    the honest version.
//
//  Payment milestones are projected onto the same timeline, certified and
//  paid, because in this game the schedule *is* the cash flow.
//

import Foundation

enum ScheduleTuning {
    /// Average output of a newly hired crew over a stream's life, as a
    /// multiple of raw skill: a slow first week (ramp-up and mentoring
    /// drag), crews that are rarely full, deliveries that run late. 0.6
    /// came from playing seeded Steady runs with a careful player and
    /// comparing the forecast on days 10, 25 and 40 with the real handover:
    /// mean error about 11%, against 50-120% for 0.75 and up. Locked in by
    /// `ScheduleAndCashCurveTests.testTheForecastTracksWhatActuallyHappens`.
    static let newCrewFactor = 0.6
}

/// One day of the cash curve.
struct CashPoint: Identifiable, Equatable {
    let day: Double
    /// Everything spent so far.
    let spent: Double
    /// Everything received so far: payments, sales, and capital raised.
    let received: Double
    /// Earned but not yet in the bank: certified milestones, retainage,
    /// marketplace payouts still clearing.
    let owed: Double
    /// Cash minus debt.
    let balance: Double

    var id: Double { day }
    /// What you would have received if everyone paid the day they owed it.
    var earned: Double { received + owed }
}

struct MilestoneDates: Equatable {
    var certified: Double
    var paid: Double?
}

struct ScheduleRow: Identifiable, Equatable {
    enum Status: Equatable {
        case done, building, noCrew, waitingOnInputs, notYetStarted
    }

    let id: String
    let title: String
    let imageName: String
    let status: Status
    /// Actual start day, or when it is expected to be able to start.
    let start: Double?
    let startIsProjected: Bool
    /// Actual, forecast or planned finish. Nil when nothing can be said.
    let finish: Double?
    /// True when the finish is an assumption (no crew working on it yet).
    let finishIsPlanned: Bool
    /// 0...1
    let progress: Double
    /// Overall progress (0...100) at which this stream can start.
    let unlockAt: Double
    let crew: Int
    let optimalCrew: Int
    /// Days this stream can slip before it moves the finish date.
    var float: Double?
    var isCritical: Bool = false
}

struct ScheduleMilestone: Identifiable, Equatable {
    let id: Int
    /// Overall progress (0...100) that certifies it.
    let threshold: Double
    let share: Double
    let certified: Double?
    let paid: Double?
    /// True when the days are a projection, not history.
    let isProjected: Bool
}

struct ProjectSchedule: Equatable {
    let scenario: ScenarioKind
    let rows: [ScheduleRow]
    let today: Double
    let deadline: Double
    /// When the last stream finishes. Nil while any stream can't be timed.
    let finish: Double?
    /// The stream that sets the finish date (or blocks any forecast).
    let criticalID: ScheduleRow.ID?
    let milestones: [ScheduleMilestone]
    /// The stream whose completion puts the product in front of customers.
    let launchID: ScheduleRow.ID?
    /// Import runs: the season peak as Demand planning currently reads it.
    let seasonPeak: Double?

    var critical: ScheduleRow? { rows.first { $0.id == criticalID } }
    var launch: ScheduleRow? { rows.first { $0.id == launchID } }

    /// Right edge of the chart: enough to show the deadline, the forecast
    /// and every bar, with a little air.
    var horizon: Double {
        let ends = rows.compactMap(\.finish) + milestones.compactMap { $0.paid } + [deadline, today, finish ?? 0]
        return max(10, (ends.max() ?? deadline) * 1.06)
    }

    /// Positive when the forecast finishes before the deadline.
    var margin: Double? { finish.map { deadline - $0 } }
}

extension SimulationEngine {
    /// Units per day this stream will keep producing. Zero when nobody is
    /// on it or it is starved of its inputs.
    func dailyOutput(of package: WorkPackage) -> Double {
        guard package.isUnlocked, !package.isComplete, !package.isStarvedOfMaterials else { return 0 }
        return crewOutput(for: package)
    }

    /// What its crew settles at once the new hires have found their feet:
    /// the first-week ramp and the mentoring drag are left out, because
    /// they pass. Timing a stream at its slowest week made a crew hired
    /// yesterday look like a job that would take a year.
    private func crewOutput(for package: WorkPackage) -> Double {
        let crew = workers.filter { $0.packageID == package.id && !$0.isInTraining }
        guard !crew.isEmpty else { return 0 }
        let settled = crew.reduce(0) { $0 + $1.skill * $1.experienceMultiplier * $1.moraleMultiplier * $1.roleFit }
        return settled
            * WorkPackage.congestionFactor(crewSize: crew.count, optimalCrew: package.optimalCrew)
            * WorkPackage.overtimeFactor(package.overtime)
    }

    /// The pace a planner assumes for a stream nobody is working on yet:
    /// its ideal crew, hired new, at the raw skill of the people you
    /// already have. A new crew starts slow and learns the job as it goes,
    /// which `ScheduleTuning.newCrewFactor` averages over a stream's life.
    private func plannedOutput(for package: WorkPackage) -> Double {
        let active = workers.filter { !$0.isInTraining }
        let skill = active.isEmpty ? 1.0 : active.reduce(0) { $0 + $1.skill } / Double(active.count)
        return max(0.05, skill * ScheduleTuning.newCrewFactor) * Double(package.optimalCrew)
    }

    var schedule: ProjectSchedule {
        let today = elapsedDays
        let totalUnits = workPackages.reduce(0) { $0 + $1.units }
        let builtUnits = workPackages.reduce(0) { $0 + $1.unitsCompleted }

        // Overall progress over time, read off the bars themselves: each
        // timed stream builds its remaining units evenly between now (or
        // its start) and its finish. Locked streams start on the day this
        // curve reaches their threshold, and payment milestones certify on
        // the day it reaches theirs - so the payments row, the bars and
        // the forecast finish always tell one story.
        var placed: [(remaining: Double, from: Double, to: Double)] = []
        func unitsBuilt(by day: Double) -> Double {
            placed.reduce(builtUnits) { total, bar in
                guard bar.to > bar.from else { return total + (day >= bar.to ? bar.remaining : 0) }
                return total + bar.remaining * min(1, max(0, (day - bar.from) / (bar.to - bar.from)))
            }
        }
        func dayOverallReaches(_ percent: Double) -> Double? {
            let target = percent / 100 * totalUnits - 0.0001
            if builtUnits >= target { return today }
            let last = placed.map(\.to).max() ?? today
            guard unitsBuilt(by: last) >= target else { return nil }
            var low = today, high = last
            for _ in 0..<40 {
                let mid = (low + high) / 2
                if unitsBuilt(by: mid) >= target { high = mid } else { low = mid }
            }
            return high
        }

        var rows: [ScheduleRow] = []
        for package in workPackages {
            let crewCount = crew(for: package.id).count
            func row(_ status: ScheduleRow.Status, start: Double?, projected: Bool,
                     finish: Double?, planned: Bool) -> ScheduleRow {
                ScheduleRow(id: package.id, title: package.title, imageName: package.imageName, status: status,
                            start: start, startIsProjected: projected, finish: finish, finishIsPlanned: planned,
                            progress: package.progress, unlockAt: package.spec.startThreshold, crew: crewCount,
                            optimalCrew: package.optimalCrew)
            }

            if package.isComplete {
                rows.append(row(.done, start: package.startedDay ?? 0, projected: false,
                                finish: package.finishedDay ?? today, planned: false))
                continue
            }
            if !package.isUnlocked {
                // Timed below, once the open streams are on the curve.
                rows.append(row(.notYetStarted, start: nil, projected: true, finish: nil, planned: true))
                continue
            }
            let started = package.startedDay
            let pace = dailyOutput(of: package)
            if pace > 0.01 {
                rows.append(row(.building, start: started ?? today, projected: started == nil,
                                finish: today + package.unitsRemaining / pace, planned: false))
            } else if crewCount > 0, package.isStarvedOfMaterials {
                // The crew is there and paid; it just has nothing to build
                // with. Time it at the crew's own pace once inputs land.
                let crewPace = crewOutput(for: package)
                rows.append(row(.waitingOnInputs, start: started ?? today, projected: started == nil,
                                finish: crewPace > 0.01 ? today + package.unitsRemaining / crewPace : nil, planned: true))
            } else {
                rows.append(row(.noCrew, start: started ?? today, projected: started == nil,
                                finish: today + package.unitsRemaining / plannedOutput(for: package), planned: true))
            }
            if let finish = rows.last?.finish {
                placed.append((remaining: package.unitsRemaining, from: today, to: finish))
            }
        }

        // Locked streams, in the order they unlock.
        let locked = workPackages.indices
            .filter { !workPackages[$0].isUnlocked && !workPackages[$0].isComplete }
            .sorted { workPackages[$0].spec.startThreshold < workPackages[$1].spec.startThreshold }
        for index in locked {
            let package = workPackages[index]
            guard let start = dayOverallReaches(package.spec.startThreshold) else { continue }
            let finish = start + package.unitsRemaining / plannedOutput(for: package)
            let old = rows[index]
            rows[index] = ScheduleRow(id: old.id, title: old.title, imageName: old.imageName, status: .notYetStarted,
                                      start: start, startIsProjected: true, finish: finish, finishIsPlanned: true,
                                      progress: old.progress, unlockAt: old.unlockAt, crew: old.crew,
                                      optimalCrew: old.optimalCrew)
            placed.append((remaining: package.unitsRemaining, from: start, to: finish))
        }

        // The finish is the last stream out. Float is how far behind it
        // each stream finishes; the one with none is the critical path.
        let finish = rows.allSatisfy({ $0.finish != nil }) ? rows.compactMap(\.finish).max() : nil
        for i in rows.indices {
            guard let projectFinish = finish, let own = rows[i].finish else { continue }
            rows[i].float = max(0, projectFinish - own)
            rows[i].isCritical = rows[i].status != .done && projectFinish - own < 1
        }
        let blocker = rows.first { $0.finish == nil && $0.status != .done }
        let critical = blocker ?? rows.filter { $0.isCritical }.max { ($0.finish ?? 0) < ($1.finish ?? 0) }
        if let blocker, let i = rows.firstIndex(where: { $0.id == blocker.id }) { rows[i].isCritical = true }

        let milestones: [ScheduleMilestone] = brief.milestones.compactMap { milestone in
            guard case .progress(let threshold) = milestone.trigger else { return nil }
            if let dates = milestoneDates[milestone.id] {
                let projectedPaid = dates.paid ?? (dates.certified + paymentDelayDays)
                return ScheduleMilestone(id: milestone.id, threshold: threshold, share: milestone.share,
                                         certified: dates.certified, paid: projectedPaid, isProjected: dates.paid == nil)
            }
            let certified = dayOverallReaches(threshold)
            return ScheduleMilestone(id: milestone.id, threshold: threshold, share: milestone.share,
                                     certified: certified, paid: certified.map { $0 + paymentDelayDays },
                                     isProjected: true)
        }

        return ProjectSchedule(scenario: brief.scenario, rows: rows, today: today, deadline: deadlineDays,
                               finish: finish, criticalID: critical?.id, milestones: milestones,
                               launchID: brief.launchStreamID, seasonPeak: seasonEstimate?.peakDay)
    }
}

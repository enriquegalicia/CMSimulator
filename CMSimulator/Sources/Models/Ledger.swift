//
//  Ledger.swift
//  CMSimulator
//
//  Phase 1 of the rebuild, and the single most important change in it.
//
//  The old engine had `totalCost`, an accumulator that nothing ever
//  checked. Nothing was denied, nothing ran out, and the number was only
//  read at the results screen. That is why the game felt purposeless:
//  at the moment of every decision, everything was free.
//
//  This is a real balance sheet. Cash is finite, payroll runs whether or
//  not anyone is productive, the client pays in arrears behind the work,
//  and running out ends the run. Every other system in the game becomes a
//  decision the moment it has to compete for money in here.
//

import Foundation

/// Every way money leaves the project. Kept as separate lines so the
/// results screen can show a real P&L instead of one opaque total - and
/// so the player can find out *what* bankrupted them.
struct CostBreakdown {
    var wages: Double = 0
    var signing: Double = 0
    var severance: Double = 0
    var materials: Double = 0
    var capabilities: Double = 0
    var training: Double = 0
    var inspections: Double = 0
    var rework: Double = 0
    var incidents: Double = 0
    var insurance: Double = 0
    var interest: Double = 0
    var liquidatedDamages: Double = 0

    var total: Double {
        wages + signing + severance + materials + capabilities + training
            + inspections + rework + incidents + insurance + interest + liquidatedDamages
    }

    /// Ordered for display, skipping lines that never fired.
    var lines: [(label: String, amount: Double)] {
        let all: [(String, Double)] = [
            (String(localized: "Wages", comment: "Cost breakdown line"), wages),
            (String(localized: "Hiring", comment: "Cost breakdown line"), signing),
            (String(localized: "Severance", comment: "Cost breakdown line"), severance),
            (String(localized: "Materials", comment: "Cost breakdown line"), materials),
            (String(localized: "Capabilities", comment: "Cost breakdown line"), capabilities),
            (String(localized: "Training", comment: "Cost breakdown line"), training),
            (String(localized: "Inspections", comment: "Cost breakdown line"), inspections),
            (String(localized: "Rework", comment: "Cost breakdown line"), rework),
            (String(localized: "Incidents", comment: "Cost breakdown line"), incidents),
            (String(localized: "Insurance", comment: "Cost breakdown line"), insurance),
            (String(localized: "Interest", comment: "Cost breakdown line"), interest),
            (String(localized: "Late penalties", comment: "Cost breakdown line"), liquidatedDamages),
        ]
        return all.filter { $0.1 > 0.5 }.map { (label: $0.0, amount: $0.1) }
    }
}

struct Ledger {
    /// Cash in the bank. Can go negative only by drawing the credit line.
    private(set) var cash: Double
    /// Outstanding balance on the credit line.
    private(set) var debt: Double = 0
    let creditLimit: Double
    let dailyInterestRate: Double

    var costs = CostBreakdown()
    /// Progress payments actually received from the client.
    private(set) var revenueReceived: Double = 0
    /// Retainage the client is holding back until handover.
    private(set) var retainageHeld: Double = 0
    /// Milestone indices already paid, so each releases exactly once.
    var milestonesPaid: Set<Int> = []
    /// Days the project has been unable to make payroll in full.
    var daysInArrears: Double = 0

    init(startingCash: Double, creditLimit: Double, dailyInterestRate: Double) {
        self.cash = startingCash
        self.creditLimit = creditLimit
        self.dailyInterestRate = dailyInterestRate
    }

    var availableCredit: Double { max(0, creditLimit - debt) }
    /// What the player can actually spend right now.
    var spendingPower: Double { cash + availableCredit }

    /// Spends `amount`, drawing on the credit line if cash runs short.
    /// Returns false and changes nothing if even the credit line can't
    /// cover it - callers use this to gate discretionary purchases.
    @discardableResult
    mutating func spend(_ amount: Double, into line: WritableKeyPath<CostBreakdown, Double>) -> Bool {
        guard amount > 0 else { return true }
        guard amount <= spendingPower else { return false }
        costs[keyPath: line] += amount
        drawDown(amount)
        return true
    }

    /// Spends what it can and reports the shortfall. Used for costs the
    /// project cannot decline to pay - payroll, penalties, disasters -
    /// where "can't afford it" is a story beat, not a rejected button.
    @discardableResult
    mutating func forceSpend(_ amount: Double, into line: WritableKeyPath<CostBreakdown, Double>) -> Double {
        guard amount > 0 else { return 0 }
        costs[keyPath: line] += amount
        let shortfall = max(0, amount - spendingPower)
        drawDown(min(amount, spendingPower))
        return shortfall
    }

    private mutating func drawDown(_ amount: Double) {
        let fromCash = min(cash, amount)
        cash -= fromCash
        let remainder = amount - fromCash
        if remainder > 0 {
            debt += remainder
        }
    }

    /// Money in from the client. Pays down the credit line first - you
    /// don't get to sit on borrowed cash while interest accrues.
    mutating func receive(_ amount: Double, retainage: Double) {
        revenueReceived += amount
        retainageHeld += retainage
        let toDebt = min(debt, amount)
        debt -= toDebt
        cash += amount - toDebt
    }

    /// Releases held retainage at handover, minus any deduction for
    /// defects the client refuses to accept.
    mutating func releaseRetainage(deduction: Double) {
        let released = max(0, retainageHeld - deduction)
        revenueReceived += released
        retainageHeld = 0
        let toDebt = min(debt, released)
        debt -= toDebt
        cash += released - toDebt
    }

    mutating func accrueInterest(days: Double) {
        guard debt > 0 else { return }
        let interest = debt * dailyInterestRate * days
        costs.interest += interest
        debt += interest
    }

    /// Net position if the project stopped right now.
    var profit: Double { revenueReceived + retainageHeld - costs.total }

    /// Test support: empties cash and consumes the credit line, so an
    /// insolvency path can be exercised without playing a whole bad run.
    mutating func debugDrain() {
        cash = 0
        debt = creditLimit
    }

    /// How many days of current burn the project can survive. The single
    /// most useful number to put in front of the player.
    func runwayDays(dailyBurn: Double) -> Double {
        guard dailyBurn > 0.01 else { return .infinity }
        return spendingPower / dailyBurn
    }
}

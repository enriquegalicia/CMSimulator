//
//  SimulationEngine.swift
//  CMSimulator
//
//  The rebuilt game loop.
//
//  What changed, and why:
//
//  The old engine had no binding constraint anywhere in it. `totalCost`
//  was an accumulator nothing checked, so at the moment of every decision
//  everything was free. Worse, headcount cancelled out of total cost
//  exactly - `rate * crew * step` earned against `cost * crew * step`
//  charged meant a package always cost `units * cost / rate` no matter
//  how many people worked it. Fifty workers finished fifty times faster
//  for the same money, so "hire everyone immediately" was strictly
//  dominant and there was no decision left to make.
//
//  Now: cash is finite and payroll runs every day whether or not anyone
//  produces anything; the client pays in lumps behind the work; crowding
//  and onboarding make extra bodies genuinely worse per head; materials
//  are physical and arrive late; defects are a debt that comes due at
//  handover; and running out of money ends the run.
//

import Foundation
import Combine

enum SimSpeed {
    case paused, normal, fast, superFast

    var tickInterval: TimeInterval { 0.1 }

    /// Simulated days per tick. At `normal` a day takes five seconds,
    /// which is about the pace at which a player can actually react to a
    /// delivery landing or morale sliding.
    var dayStep: Double {
        switch self {
        case .paused: return 0
        case .normal: return 0.02
        case .fast: return 0.1
        case .superFast: return 0.3
        }
    }
}

enum RunOutcome: Equatable {
    case delivered
    case insolvent
}

/// A transient line for the activity feed - deliveries, resignations,
/// payments. The old build had no way to tell the player that something
/// happened unless it was a full-screen disaster banner.
struct SiteLogEntry: Identifiable {
    enum Tone { case neutral, good, bad }
    let id = UUID()
    let day: Int
    let text: String
    let symbol: String
    let tone: Tone
}

@MainActor
final class SimulationEngine: ObservableObject {

    // MARK: Published run state

    @Published private(set) var brief: ProjectBrief
    @Published private(set) var ledger: Ledger
    @Published private(set) var workPackages: [WorkPackage]
    @Published private(set) var workers: [Worker] = []
    @Published private(set) var capabilities: [Capability]
    @Published private(set) var market: MaterialMarket
    @Published private(set) var vendors: [Vendor]
    @Published private(set) var orders: [MaterialOrder] = []
    @Published private(set) var mitigationsHeld: Set<MitigationClass> = []
    /// Customers, revenue and valuation. Nil for scenarios with no market.
    @Published private(set) var growth: GrowthModel?
    /// The offer on the table once the run ends, for the debrief.
    @Published private(set) var exitOffer: ExitOffer?
    /// Inventory, sales and the marketplace's cut. Nil unless the business
    /// buys goods to resell.
    @Published private(set) var trading: TradingModel?
    /// Season-close accounting, for the debrief.
    @Published private(set) var seasonClose: SeasonClose?

    @Published private(set) var totalProgress: Double = 0
    @Published private(set) var elapsedDays: Double = 0
    @Published private(set) var deadlineDays: Double
    @Published private(set) var clientTrust: Double = 0.55
    @Published private(set) var reputation: Double = 0.75
    @Published private(set) var speed: SimSpeed = .paused
    @Published private(set) var outcome: RunOutcome?

    @Published private(set) var activeEvent: SimEvent?
    @Published private(set) var hiringRequest: HiringRequest?
    @Published private(set) var orderRequest: MaterialOrderRequest?
    @Published private(set) var forecast: RiskForecast?
    @Published private(set) var siteLog: [SiteLogEntry] = []
    @Published private(set) var extensionUsed = false
    /// How many incidents have actually struck this run.
    @Published private(set) var incidentsFired = 0
    /// How many were stopped before they struck by a mitigation you held.
    @Published private(set) var incidentsPrevented = 0

    // MARK: Private run state

    private var timerCancellable: AnyCancellable?
    private var pendingPayments: [(net: Double, retainage: Double, dueDay: Double)] = []
    private var penalizedThroughDay: Double = 0
    private var nextIncidentDay: Double = .greatestFiniteMagnitude
    private var nextIncidentClass: MitigationClass = .weather
    private var nextIncidentSeverity: Double = 0.5
    private var logDayAccumulator: Double = 0
    /// Incidents that fired while an earlier banner was still on screen.
    /// The banner is a display device; it must never be able to hold the
    /// risk model back.
    private var eventQueue: [SimEvent] = []
    /// Sim-days the current banner has been up, so it can retire itself.
    private var activeEventAge: Double = 0
    /// Consecutive simulated days with no work happening and no means to
    /// restart it. Without this a project that sheds its whole crew never
    /// misses payroll (there is none to miss) and so never ends - it just
    /// accrues late penalties for ever.
    private var stalledDays: Double = 0
    /// Extra contract value earned from client change orders.
    private var scopeRevenue: Double = 0

    private let baseIncidentIntervalDays: Double = 17

    // MARK: Init

    init(brief: ProjectBrief = .construction()) {
        self.brief = brief
        self.ledger = Ledger(startingCash: brief.startingCash,
                             creditLimit: brief.creditLimit,
                             dailyInterestRate: brief.dailyInterestRate)
        self.deadlineDays = brief.deadlineDays
        self.market = MaterialMarket(volatility: brief.marketVolatility)
        self.vendors = Vendor.standingPanel()
        self.workPackages = brief.streams.map { WorkPackage(spec: $0) }
        self.capabilities = CapabilityKind.allCases.map { Capability(kind: $0) }
        self.growth = brief.growth.map(GrowthModel.init(spec:))
        self.trading = brief.trade.map { TradingModel(spec: $0.marketplace) }
        configureFreshRun()
    }

    private func configureFreshRun() {
        workPackages[0].isUnlocked = true
        // Mobilization stock, procured under the contract's advance. Enough
        // to start without an order, not enough to coast.
        for i in workPackages.indices where workPackages[i].consumesMaterials {
            workPackages[i].materialStock = workPackages[i].units * workPackages[i].spec.materialUnitsPerWorkUnit * 0.15
        }
        for i in capabilities.indices where capabilities[i].kind.unlockThreshold <= 0 {
            capabilities[i].isUnlocked = true
        }
        scheduleNextIncident()
        let advance = brief.contractValue * brief.advanceRate
        ledger.receive(advance * (1 - brief.retainageRate), retainage: advance * brief.retainageRate)
        log(String(localized: "Contract signed with \(brief.counterpartyName). \(Int(deadlineDays)) days to hand over.", comment: "Site log: run start"),
            symbol: "signature", tone: .neutral)
        log(String(localized: "Mobilisation advance of \(Int(advance).formatted()) received.", comment: "Site log: advance payment"),
            symbol: "banknote.fill", tone: .good)
        recomputeProgress()
    }

    func restart(with newBrief: ProjectBrief? = nil) {
        setSpeed(.paused)
        let next = newBrief ?? .make(scenario: brief.scenario, difficulty: brief.difficulty)
        brief = next
        ledger = Ledger(startingCash: next.startingCash,
                        creditLimit: next.creditLimit,
                        dailyInterestRate: next.dailyInterestRate)
        deadlineDays = next.deadlineDays
        market = MaterialMarket(volatility: next.marketVolatility)
        vendors = Vendor.standingPanel()
        workPackages = next.streams.map { WorkPackage(spec: $0) }
        capabilities = CapabilityKind.allCases.map { Capability(kind: $0) }
        growth = next.growth.map(GrowthModel.init(spec:))
        trading = next.trade.map { TradingModel(spec: $0.marketplace) }
        exitOffer = nil
        seasonClose = nil
        workers = []
        orders = []
        mitigationsHeld = []
        pendingPayments = []
        siteLog = []
        totalProgress = 0
        elapsedDays = 0
        clientTrust = 0.55
        reputation = 0.75
        penalizedThroughDay = 0
        scopeRevenue = 0
        stalledDays = 0
        logDayAccumulator = 0
        extensionUsed = false
        outcome = nil
        activeEvent = nil
        eventQueue.removeAll()
        activeEventAge = 0
        incidentsFired = 0
        incidentsPrevented = 0
        hiringRequest = nil
        orderRequest = nil
        forecast = nil
        configureFreshRun()
    }

    // MARK: - Transport

    func play() { setSpeed(.normal) }
    func fastForward() { setSpeed(.fast) }
    func superFastForward() { setSpeed(.superFast) }
    func pause() { setSpeed(.paused) }

    private func setSpeed(_ newSpeed: SimSpeed) {
        speed = newSpeed
        timerCancellable?.cancel()
        guard newSpeed != .paused, outcome == nil else { return }
        timerCancellable = Timer.publish(every: newSpeed.tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    // MARK: - The day

    private func tick() {
        advance(byDays: speed.dayStep)
    }

    /// One simulated slice. Split out from `tick()` so the whole
    /// simulation can be driven deterministically from tests without
    /// waiting on a wall-clock timer.
    func advance(byDays step: Double) {
        guard step > 0, outcome == nil else { return }

        elapsedDays += step

        market.advance(days: step)
        receiveDeliveries()
        advanceWork(step: step)
        advanceRoster(step: step)
        payPayroll(step: step)
        payUpkeep(step: step)
        runInspections(step: step)
        ledger.accrueInterest(days: step)
        advanceTrust(step: step)
        releaseDuePayments()
        accrueLatePenalties()
        recomputeProgress()
        updateUnlocks()
        advanceGrowth(step: step)
        advanceTrading(step: step)
        raisePaymentMilestones()
        advanceIncidentClock(step: step)
        ageActiveEvent(step: step)
        updateForecast()

        if brief.trade != nil {
            // A trader's run ends when the selling season does. There is
            // no handover and no acquirer - just whatever the books say
            // once the leftovers have been dumped.
            if elapsedDays >= deadlineDays {
                closeSeason()
                return
            }
        } else if brief.growth != nil {
            // A startup does not stop when the backlog is empty - that is
            // the point at which it is finally free to just grow. The run
            // ends at the exit horizon.
            if elapsedDays >= deadlineDays {
                performExit()
                return
            }
        } else if workPackages.allSatisfy(\.isComplete) {
            performHandover()
            return
        }
        if ledger.daysInArrears >= 4 {
            finish(.insolvent)
            return
        }
        updateStall(step: step)
        if stalledDays >= 10 {
            finish(.insolvent)
        }
    }

    /// A project is finished - just not delivered - when nothing is being
    /// built and there is no money to start it again. Checked separately
    /// from payroll arrears because a site with no crew has no payroll to
    /// miss.
    private func updateStall(step: Double) {
        let building = currentThroughput > 0.001
        // Enough to sign one cheap hire and buy them something to build with.
        let escapeCost = 6_000.0
        if building || ledger.spendingPower > escapeCost {
            stalledDays = 0
        } else {
            stalledDays += step
        }
    }

    // MARK: Work

    private func advanceWork(step: Double) {
        for i in workPackages.indices {
            guard workPackages[i].isUnlocked, !workPackages[i].isComplete else { continue }
            let crew = workers.filter { $0.packageID == workPackages[i].id && !$0.isInTraining }
            guard !crew.isEmpty else { continue }

            // Crew waiting on materials are still on full pay. This is the
            // single clearest lesson in the game about lead times, so it is
            // tracked explicitly and reported at the end.
            if workPackages[i].isStarvedOfMaterials {
                workPackages[i].idleCrewDays += Double(crew.count) * step
                continue
            }

            let overtime = workPackages[i].overtime
            let rawOutput = crew.reduce(0) { $0 + $1.effectiveOutput }
            let congestion = WorkPackage.congestionFactor(crewSize: crew.count, optimalCrew: workPackages[i].optimalCrew)
            let drag = WorkPackage.mentoringDrag(greenCount: crew.filter(\.isOnboarding).count)
            let otFactor = WorkPackage.overtimeFactor(overtime)

            var produced = rawOutput * congestion * drag * otFactor * step
            if workPackages[i].consumesMaterials {
                let materialCap = workPackages[i].materialStock / workPackages[i].spec.materialUnitsPerWorkUnit
                produced = min(produced, workPackages[i].unitsRemaining, materialCap)
            } else {
                produced = min(produced, workPackages[i].unitsRemaining)
            }
            guard produced > 0 else { continue }

            workPackages[i].unitsCompleted += produced
            if workPackages[i].consumesMaterials {
                workPackages[i].materialStock -= produced * workPackages[i].spec.materialUnitsPerWorkUnit
            }

            var defectPerUnit = crew.reduce(0) { $0 + $1.defectRate(overtime: overtime) } / Double(crew.count)
            if workPackages[i].isFastTracked { defectPerUnit += CapabilityEffects.fastTrackDefectPenalty }
            defectPerUnit += workPackages[i].materialDefectPerUnit
            workPackages[i].defectDebt += produced * defectPerUnit

            if workPackages[i].isComplete {
                log(String(localized: "\(workPackages[i].title) complete.", comment: "Site log: package finished"),
                    symbol: "checkmark.seal.fill", tone: .good)
                demobilise(packageID: workPackages[i].id, title: workPackages[i].title)
            }
        }
    }

    // MARK: Roster

    private func advanceRoster(step: Double) {
        var resignations: [(id: Worker.ID, name: String)] = []
        for i in workers.indices {
            let overtime = workPackages.first { $0.id == workers[i].packageID }?.overtime ?? 0
            let package = workPackages.first { $0.id == workers[i].packageID }
            let isWorking = (package?.isUnlocked ?? false)
                && !(package?.isComplete ?? true)
                && !(package?.isStarvedOfMaterials ?? true)
            let wasTraining = workers[i].isInTraining
            workers[i].advance(days: step, overtime: overtime, isWorking: isWorking)
            if wasTraining, !workers[i].isInTraining {
                log(String(localized: "\(workers[i].name) returned from training.", comment: "Site log: training complete"),
                    symbol: "graduationcap.fill", tone: .good)
            }
        }
        for worker in workers where Double.random(in: 0...1) < worker.quitProbability(over: step) {
            resignations.append((id: worker.id, name: worker.name))
        }
        guard !resignations.isEmpty else { return }
        let leaving = Set(resignations.map(\.id))
        workers.removeAll { leaving.contains($0.id) }
        reputation = max(0, reputation - 0.03 * Double(resignations.count))
        for resignation in resignations {
            log(String(localized: "\(resignation.name) resigned. Morale was too low.", comment: "Site log: worker quit"),
                symbol: "figure.walk.departure", tone: .bad)
        }
    }

    /// Releases a crew once their scope is finished. No severance: this is
    /// a trade leaving at the end of its works, not a layoff. Without it,
    /// finished crews would draw full pay to the end of the job and no
    /// amount of good play could turn a profit.
    private func demobilise(packageID: WorkPackage.ID, title: String) {
        let leaving = workers.filter { $0.packageID == packageID }
        guard !leaving.isEmpty else { return }
        workers.removeAll { $0.packageID == packageID }
        log(String(localized: "\(leaving.count) released from \(title) — scope complete.", comment: "Site log: crew demobilised"),
            symbol: "figure.walk.motion", tone: .neutral)
    }

    private func payPayroll(step: Double) {
        let payroll = workers.reduce(0) { $0 + $1.dailyWage } * step
        guard payroll > 0 else { ledger.daysInArrears = 0; return }
        let shortfall = ledger.forceSpend(payroll, into: \.wages)
        if shortfall > 0.5 {
            let wasSolvent = ledger.daysInArrears <= 0
            ledger.daysInArrears += step
            // Once per episode, not once per tick.
            if wasSolvent {
                log(String(localized: "Payroll missed. Crews walk if this is not fixed.", comment: "Site log: payroll missed"),
                    symbol: "exclamationmark.octagon.fill", tone: .bad)
            }
        } else {
            ledger.daysInArrears = 0
        }
    }

    /// What every lever costs to run across the organisation you actually
    /// have. Sublinear, so growing is a drag on your initiatives rather
    /// than a wall, and clamped so neither a skeleton crew nor an empire
    /// makes capabilities free or unpayable.
    var organisationLoad: Double {
        let heads = Double(workers.count)
        guard heads > 0 else { return 0.75 }
        let ratio = heads / max(1, brief.capabilityHeadcountReference)
        return min(3.0, max(0.75, pow(ratio, 0.7)))
    }

    private func payUpkeep(step: Double) {
        let scale = brief.capabilityCostFactor * organisationLoad
        let capabilityUpkeep = capabilities.reduce(0) { $0 + $1.dailyUpkeep } * scale
        let mitigationUpkeep = mitigationsHeld.reduce(0) { $0 + $1.dailyUpkeep } * scale
        ledger.forceSpend((capabilityUpkeep + mitigationUpkeep) * step, into: \.capabilities)

        let riskLevel = level(of: .risk)
        if riskLevel > 0 {
            let premium = brief.contractValue * 0.00022 * Double(riskLevel) * step
            ledger.forceSpend(premium, into: \.insurance)
        }
    }

    private func runInspections(step: Double) {
        let rate = CapabilityEffects.inspectionRatePerDay(level: level(of: .quality))
        guard rate > 0 else { return }
        var budget = rate * step
        for i in workPackages.indices where workPackages[i].defectDebt > 0 {
            guard budget > 0 else { break }
            let fixable = min(workPackages[i].defectDebt, budget)
            let cost = fixable * CapabilityEffects.inspectionCostPerDefect
            guard ledger.spend(cost, into: \.inspections) else { return }
            workPackages[i].defectDebt -= fixable
            workPackages[i].defectsResolved += fixable
            budget -= fixable
        }
    }

    private func advanceTrust(step: Double) {
        let gain = CapabilityEffects.trustGainPerDay(level: level(of: .communications))
        // Trust decays on its own: a client left alone assumes the worst.
        var delta = (gain - 0.004) * step
        if elapsedDays > deadlineDays { delta -= 0.010 * step }
        clientTrust = min(1, max(0, clientTrust + delta))
    }

    // MARK: Money in

    private func raisePaymentMilestones() {
        for milestone in brief.milestones where !ledger.milestonesPaid.contains(milestone.id) {
            guard isTriggered(milestone.trigger) else { continue }
            ledger.milestonesPaid.insert(milestone.id)

            if milestone.isFinancing {
                // A round is cash today paid for with a slice of the exit.
                // It never counts as earnings, or raising and then failing
                // would score as a profitable run.
                let amount = brief.contractValue * milestone.share
                ledger.raise(amount, dilution: milestone.dilution)
                reputation = min(1, reputation + 0.04)
                clientTrust = min(1, clientTrust + 0.08)
                log(String(localized: "\(milestone.name) closed: \(Int(amount).formatted()) in, \(Int(milestone.dilution * 100))% sold.", comment: "Site log: funding round closed"),
                    symbol: "chart.line.uptrend.xyaxis", tone: .good)
            } else {
                let gross = (brief.contractValue + scopeRevenue) * milestone.share
                let retainage = gross * brief.retainageRate
                let delay = max(1, brief.clientPersona.basePaymentDelayDays
                    - CapabilityEffects.paymentSpeedUpDays(level: level(of: .communications))
                    - clientTrust * 4)
                pendingPayments.append((net: gross - retainage, retainage: retainage, dueDay: elapsedDays + delay))
                reputation = min(1, reputation + 0.03)
                log(String(localized: "Milestone certified. Payment due in \(Int(delay)) days.", comment: "Site log: milestone reached"),
                    symbol: "checkmark.circle.fill", tone: .good)
            }
        }
    }

    /// Clients certify progress; investors price traction.
    private func isTriggered(_ trigger: PaymentTrigger) -> Bool {
        switch trigger {
        case .progress(let threshold): return totalProgress >= threshold
        case .customers(let threshold): return (growth?.customers ?? 0) >= threshold
        }
    }

    private func releaseDuePayments() {
        let due = pendingPayments.filter { $0.dueDay <= elapsedDays }
        guard !due.isEmpty else { return }
        pendingPayments.removeAll { $0.dueDay <= elapsedDays }
        for payment in due {
            ledger.receive(payment.net, retainage: payment.retainage)
            log(String(localized: "Client paid \(Int(payment.net).formatted()).", comment: "Site log: payment received"),
                symbol: "banknote.fill", tone: .good)
        }
    }

    private func accrueLatePenalties() {
        guard elapsedDays > deadlineDays else { return }
        let from = max(deadlineDays, penalizedThroughDay)
        let newLateDays = elapsedDays - from
        guard newLateDays > 0 else { return }
        penalizedThroughDay = elapsedDays
        ledger.forceSpend(newLateDays * brief.latePenaltyPerDay, into: \.liquidatedDamages)
    }

    // MARK: Materials

    private func receiveDeliveries() {
        let landed = orders.filter { $0.arrivalDay <= elapsedDays }
        guard !landed.isEmpty else { return }
        orders.removeAll { $0.arrivalDay <= elapsedDays }
        for order in landed {
            if let spec = brief.trade, order.packageID == Self.stockOrderID {
                // Landed cost is what you paid, spread over the units that
                // actually arrived - that is the number every later
                // calculation is measured against.
                let landedCost = order.quantity > 0 ? order.pricePaid / order.quantity : spec.landedCostPerUnit
                // Pre-shipment inspection catches bad batches at the
                // factory, before you have paid to ship and store them.
                let inspection = [1.0, 0.62, 0.40, 0.24][min(level(of: .quality), 3)]
                trading?.receive(units: order.quantity, landedCostPerUnit: landedCost,
                                 defectRate: order.vendorDefectPerUnit * 15 * inspection,
                                 onDay: elapsedDays)
                log(String(localized: "\(Int(order.quantity).formatted()) units cleared customs and are sellable.", comment: "Site log: stock arrived"),
                    symbol: "shippingbox.fill", tone: .good)
                continue
            }
            guard let i = workPackages.firstIndex(where: { $0.id == order.packageID }) else { continue }
            // Blend the incoming batch's quality into what is already on
            // site, so a cheap vendor shows up as rework only on the work
            // actually built from their material.
            let existing = workPackages[i].materialStock
            let total = existing + order.quantity
            if total > 0 {
                workPackages[i].materialDefectPerUnit =
                    (workPackages[i].materialDefectPerUnit * existing + order.vendorDefectPerUnit * order.quantity) / total
            }
            workPackages[i].materialStock += order.quantity
            log(String(localized: "\(Int(order.quantity)) units delivered to \(workPackages[i].title).", comment: "Site log: delivery arrived"),
                symbol: "shippingbox.fill", tone: .good)
        }
    }

    // MARK: Growth

    /// Moves the customer base, banks subscription revenue and pays to
    /// serve it. Only runs for scenarios that have a market at all.
    private func advanceGrowth(step: Double) {
        guard growth != nil else { return }

        // The product reaches people when its launch stream is finished.
        if let launchID = brief.launchStreamID,
           let launchStream = workPackages.first(where: { $0.id == launchID }),
           launchStream.isComplete, growth?.isLaunched == false {
            growth?.launch(onDay: elapsedDays)
            log(String(localized: "Launched. The product is live and can start acquiring customers.", comment: "Site log: product launched"),
                symbol: "paperplane.fill", tone: .good)
        }

        let totalUnits = workPackages.reduce(0) { $0 + $1.units }
        let built = workPackages.reduce(0) { $0 + $1.unitsCompleted }
        let breadth = totalUnits > 0 ? built / totalUnits : 0
        let debt = workPackages.reduce(0) { $0 + $1.defectDebt }

        let result = growth!.advance(days: step, techDebt: debt,
                                     breadth: breadth, currentDay: elapsedDays)
        if result.revenue > 0 {
            // Subscription income is genuinely earned, unlike a round.
            ledger.receive(result.revenue, retainage: 0)
        }
        if result.costToServe > 0 {
            ledger.forceSpend(result.costToServe, into: \.materials)
        }
        if growth!.dailyGrowthSpend > 0 {
            let spend = growth!.dailyGrowthSpend * step
            if !ledger.spend(spend, into: \.capabilities) {
                growth?.dailyGrowthSpend = 0
                log(String(localized: "Growth spend paused - not enough cash.", comment: "Site log: growth spend halted"),
                    symbol: "exclamationmark.triangle.fill", tone: .bad)
            }
        }
    }

    // MARK: Trading

    /// Sells stock into the season, and bills every fee the marketplace
    /// charges for the privilege.
    private func advanceTrading(step: Double) {
        guard trading != nil, let spec = brief.trade else { return }

        if let gate = workPackages.first(where: { $0.id == spec.tradingStreamID }),
           gate.isComplete, trading?.isTrading == false {
            trading?.beginTrading(onDay: elapsedDays)
            log(String(localized: "Listings are live. Stock can start selling.", comment: "Site log: trading opens"),
                symbol: "storefront.fill", tone: .good)
        }

        let totalUnits = workPackages.reduce(0) { $0 + $1.units }
        let built = totalUnits > 0 ? workPackages.reduce(0) { $0 + $1.unitsCompleted } / totalUnits : 0
        let demand = spec.demand(on: elapsedDays, breadth: built)

        let day = trading!.advance(days: step, demand: demand, currentDay: elapsedDays)

        // Every one of these is a real line on a real seller's statement.
        if day.platformFees > 0 { ledger.forceSpend(day.platformFees, into: \.marketplaceFees) }
        if day.refunds > 0      { ledger.forceSpend(day.refunds, into: \.returns) }
        if day.storage > 0      { ledger.forceSpend(day.storage, into: \.storage) }
        if day.adSpend > 0 {
            if !ledger.spend(day.adSpend, into: \.advertising) {
                trading?.dailyAdSpend = 0
                log(String(localized: "Advertising paused - not enough cash.", comment: "Site log: ad spend halted"),
                    symbol: "exclamationmark.triangle.fill", tone: .bad)
            }
        }
        // Sales money arrives on the platform's payout schedule, not the
        // day the customer buys.
        if day.payoutsReceived > 0 { ledger.receive(day.payoutsReceived, retainage: 0) }
    }

    /// What the player believes about the season. Without Demand planning
    /// there is no read at all; with it, the estimate tightens toward the
    /// truth. Buying stock is the decision this information is for.
    var seasonEstimate: (peakDay: Double, confidence: Double)? {
        guard let spec = brief.trade else { return nil }
        let planning = level(of: .planning)
        guard planning > 0 else { return nil }
        let confidence = [0, 0.45, 0.72, 0.93][min(planning, 3)]
        // A deterministic offset from the seed, so the same run always
        // misleads you the same way rather than shimmering each tick.
        var rng = SeededGenerator(seed: brief.seed &+ 977)
        let bias = Double.random(in: -1...1, using: &rng) * (1 - confidence) * 26
        return (peakDay: spec.seasonPeakDay + bias, confidence: confidence)
    }

    func setListPrice(_ price: Double) {
        trading?.listPrice = max(1, price)
    }

    func setAdSpend(_ perDay: Double) {
        trading?.dailyAdSpend = max(0, perDay)
    }

    /// What the season really cost, once the stock nobody wanted is dumped.
    private func closeSeason() {
        guard trading != nil else { return finish(.insolvent) }
        let outstanding = trading!.settleOutstandingPayouts()
        if outstanding > 0 { ledger.receive(outstanding, retainage: 0) }

        let dump = trading!.liquidate()
        if dump.units > 0.5 {
            ledger.receive(dump.recovered, retainage: 0)
            log(String(localized: "Dumped \(Int(dump.units).formatted()) unsold units for \(Int(dump.recovered).formatted()) — they cost \(Int(dump.costWritten).formatted()).", comment: "Site log: liquidation"),
                symbol: "arrow.down.circle.fill", tone: .bad)
        }
        seasonClose = SeasonClose(
            unitsSold: trading!.unitsSold,
            unitsReturned: trading!.unitsReturned,
            unitsDumped: dump.units,
            grossSales: trading!.grossSales,
            marketplaceFees: trading!.marketplaceFees,
            refunds: trading!.refundsPaid,
            storage: trading!.storagePaid,
            liquidationRecovered: dump.recovered,
            liquidationCost: dump.costWritten,
            finalRating: trading!.rating
        )
        finish(.delivered)
    }

    /// Player control over acquisition spend.
    func setGrowthSpend(_ perDay: Double) {
        growth?.dailyGrowthSpend = max(0, perDay)
    }

    // MARK: Progress and unlocks

    private func recomputeProgress() {
        // Weighted across *all* packages, not just unlocked ones. The old
        // build weighted only unlocked packages, so unlocking one enlarged
        // the denominator and the headline percentage visibly fell while
        // the player was doing well.
        let totalUnits = workPackages.reduce(0) { $0 + $1.units }
        guard totalUnits > 0 else { totalProgress = 0; return }
        let completed = workPackages.reduce(0) { $0 + $1.unitsCompleted }
        totalProgress = min(100, completed / totalUnits * 100)
    }

    private func updateUnlocks() {
        for i in workPackages.indices where !workPackages[i].isUnlocked {
            if totalProgress >= workPackages[i].spec.startThreshold {
                workPackages[i].isUnlocked = true
                log(String(localized: "\(workPackages[i].title) can now start.", comment: "Site log: package unlocked"),
                    symbol: "lock.open.fill", tone: .neutral)
            }
        }
        for i in capabilities.indices where !capabilities[i].isUnlocked {
            if totalProgress >= capabilities[i].kind.unlockThreshold {
                capabilities[i].isUnlocked = true
            }
        }
    }

    // MARK: Incidents

    /// How exposed the site is right now. Overtime, crowding, low morale
    /// and a shortage of safety-minded people all make incidents both
    /// likelier and sooner. Unlike the old build - where owning five
    /// boosters pinned the gauges and switched disasters off entirely -
    /// this can be reduced but never eliminated.
    var siteExposure: Double {
        let activeCrew = workers.filter { !$0.isInTraining }
        guard !activeCrew.isEmpty else { return 0.6 }
        let avgMorale = activeCrew.reduce(0) { $0 + $1.morale } / Double(activeCrew.count)
        var crowding = 0.0
        for package in workPackages where package.isUnlocked && !package.isComplete {
            let crew = activeCrew.filter { $0.packageID == package.id }.count
            if crew > package.optimalCrew {
                crowding += Double(crew - package.optimalCrew) / Double(max(1, package.optimalCrew))
            }
        }
        let overtimeLoad = workPackages.filter { $0.isUnlocked && !$0.isComplete }
            .reduce(0) { $0 + $1.overtime }
        let safety = activeCrew.reduce(0) { $0 + $1.archetype.safetyContribution }

        var exposure = 1.0
        exposure += 0.55 * overtimeLoad
        exposure += 0.40 * crowding
        exposure += 0.70 * (1 - avgMorale)
        exposure -= min(0.45, safety)
        return min(3.0, max(0.3, exposure))
    }

    private func scheduleNextIncident() {
        let riskDamping = 1 / CapabilityEffects.incidentProbabilityMultiplier(level: level(of: .risk))
        let interval = baseIncidentIntervalDays
            / brief.difficulty.eventFrequencyFactor
            / max(0.3, siteExposure)
            * riskDamping
        nextIncidentDay = elapsedDays + Double.random(in: interval * 0.55...interval * 1.55)
        nextIncidentClass = weightedIncidentClass()
        nextIncidentSeverity = Double.random(in: 0.2...1.0)
    }

    private func weightedIncidentClass() -> MitigationClass {
        var weights: [MitigationClass: Double] = [
            .weather: 1.0, .security: 1.0, .safety: 1.0, .technical: 1.0, .client: 1.0,
        ]
        // Bad practice pulls specific categories toward you, so incidents
        // read as consequences rather than as arbitrary punishment.
        let overtimeLoad = workPackages.reduce(0) { $0 + $1.overtime }
        weights[.safety]! += overtimeLoad * 1.6
        weights[.technical]! += Double(workPackages.filter(\.isFastTracked).count) * 1.4
        weights[.client]! += (1 - clientTrust) * 1.8
        weights[.security]! += market.trend > 0.05 ? 0.8 : 0
        // Sitting well above the going rate is an invitation: somebody
        // will list the same goods cheaper. Pricing for margin is a real
        // strategy, not a free one.
        if let trading, trading.listPrice > trading.spec.referencePrice {
            let over = (trading.listPrice / trading.spec.referencePrice) - 1
            weights[.technical]! += over * 9.0
        }
        let total = weights.values.reduce(0, +)
        var roll = Double.random(in: 0...total)
        for (kind, weight) in weights {
            roll -= weight
            if roll <= 0 { return kind }
        }
        return .weather
    }

    private func advanceIncidentClock(step: Double) {
        // A dangerous site pulls the next incident closer rather than
        // only affecting the roll, so the schedule stays responsive to
        // what the player is doing right now.
        let exposure = siteExposure
        if exposure > 1.15 {
            nextIncidentDay -= (exposure - 1.15) * 0.2 * step
        }
        guard elapsedDays >= nextIncidentDay else { return }

        let mitigationClass = nextIncidentClass
        if mitigationsHeld.contains(mitigationClass),
           Double.random(in: 0...1) < mitigationClass.probabilityReduction {
            incidentsPrevented += 1
            log(String(localized: "\(mitigationClass.name(in: brief.scenario)) prevented an incident.", comment: "Site log: mitigation worked"),
                symbol: "shield.lefthalf.filled", tone: .good)
            scheduleNextIncident()
            return
        }
        fire(SimEventKind.random(in: mitigationClass, from: brief.incidentDeck), severity: nextIncidentSeverity)
        scheduleNextIncident()
    }

    private func fire(_ kind: SimEventKind, severity: Double) {
        var consequences: [String] = []
        let mitigated = mitigationsHeld.contains(kind.mitigationClass)
        let severityScale = severity * (mitigated ? kind.mitigationClass.severityReduction : 1)

        // Direct cost, anchored to contract value rather than to
        // spend-to-date, so late incidents cannot compound into a spiral.
        var gross = 0.0
        if kind.costFractionRange.upperBound > 0 {
            let fraction = kind.costFractionRange.lowerBound
                + (kind.costFractionRange.upperBound - kind.costFractionRange.lowerBound) * severityScale
            gross = brief.contractValue * fraction
        }

        var covered = 0.0
        let coverage = CapabilityEffects.insuranceCoverage(level: level(of: .risk))
        if coverage > 0, gross > CapabilityEffects.insuranceDeductible {
            covered = (gross - CapabilityEffects.insuranceDeductible) * coverage
            consequences.append(String(localized: "Insurance covered \(Int(covered).formatted()).", comment: "Incident consequence: insurance"))
        }
        if gross > 0 {
            ledger.forceSpend(gross - covered, into: \.incidents)
        }

        if let range = kind.setbackRange,
           let idx = workPackages.indices
               .filter({ workPackages[$0].isUnlocked && workPackages[$0].unitsCompleted > 0 })
               .max(by: { workPackages[$0].unitsCompleted < workPackages[$1].unitsCompleted }) {
            let setback = scaled(range, severityScale)
            workPackages[idx].unitsCompleted = max(0, workPackages[idx].unitsCompleted - setback)
            consequences.append(String(localized: "\(workPackages[idx].title) lost \(Int(setback)) units of work.", comment: "Incident consequence: progress lost"))
        }

        if let range = kind.materialLossRange, brief.trade != nil, trading != nil {
            // Stolen or damaged goods come straight off the shelf.
            let lost = trading!.loseStock(fraction: min(0.5, scaled(range, severityScale) / 40))
            if lost > 1 {
                consequences.append(String(localized: "\(Int(lost).formatted()) units of stock lost.", comment: "Incident consequence: stock lost"))
            }
        } else if let range = kind.materialLossRange,
           let idx = workPackages.indices
               .filter({ workPackages[$0].materialStock > 0 })
               .max(by: { workPackages[$0].materialStock < workPackages[$1].materialStock }) {
            let lost = min(workPackages[idx].materialStock, scaled(range, severityScale))
            workPackages[idx].materialStock -= lost
            consequences.append(String(localized: "\(Int(lost)) units of material lost.", comment: "Incident consequence: material lost"))
        }

        if let range = kind.deliveryDelayRange, !orders.isEmpty {
            let delay = scaled(range, severityScale)
            for i in orders.indices {
                orders[i].arrivalDay += delay
                orders[i].hasSlipped = true
            }
            consequences.append(String(localized: "Deliveries slipped \(Int(delay)) days.", comment: "Incident consequence: deliveries delayed"))
        }

        if let range = kind.moraleHitRange, !workers.isEmpty {
            let hit = scaled(range, severityScale)
            for i in workers.indices { workers[i].morale = max(0, workers[i].morale - hit) }
            consequences.append(String(localized: "Morale fell across the site.", comment: "Incident consequence: morale"))
        }

        if let range = kind.receivableLossRange, trading != nil {
            let lost = trading!.loseReceivable(fraction: scaled(range, severityScale))
            if lost > 1 {
                consequences.append(String(localized: "\(Int(lost).formatted()) already sold will never be paid.", comment: "Incident consequence: receivable written off"))
            }
        }

        if let range = kind.trustHitRange {
            clientTrust = max(0, clientTrust - scaled(range, severityScale))
            consequences.append(String(localized: "Client confidence took a hit.", comment: "Incident consequence: trust"))
        }

        if kind == .competitorUndercut, trading != nil {
            // You either follow them down or watch the volume go.
            let drop = 1 - scaled(0.04...0.12, severityScale)
            trading!.listPrice = max(trading!.spec.referencePrice * 0.6, trading!.listPrice * drop)
            consequences.append(String(localized: "You had to drop your price to \(Int(trading!.listPrice)).", comment: "Incident consequence: forced price cut"))
        }

        if let range = kind.defectInjectionRange,
           let idx = workPackages.indices.filter({ workPackages[$0].unitsCompleted > 0 }).randomElement() {
            let defects = scaled(range, severityScale)
            workPackages[idx].defectDebt += defects
            consequences.append(String(localized: "Latent defects added to \(workPackages[idx].title).", comment: "Incident consequence: defects"))
        }

        if let range = kind.priceShockRange {
            let magnitude = scaled(range, severityScale)
            market.applyShock(magnitude: magnitude, isSpike: true)
            consequences.append(String(localized: "Materials index jumped \(Int(magnitude * 100))%.", comment: "Incident consequence: price shock"))
        }

        if let range = kind.scopeAddedRange {
            let extra = scaled(range, severityScale)
            let factor = brief.clientPersona.changeOrderFactor
            if let idx = workPackages.indices.filter({ workPackages[$0].isUnlocked && !workPackages[$0].isComplete }).randomElement() {
                // Real extra work, and the client pays for it - a change
                // order is a schedule problem, not free punishment and not
                // a windfall either.
                workPackages[idx].addedScope += extra
                let value = brief.contractValue * 0.012 * extra / 8 * factor
                scopeRevenue += value
                consequences.append(String(localized: "\(workPackages[idx].title) grew by \(Int(extra)) units, contract value up \(Int(value).formatted()).", comment: "Incident consequence: change order"))
            }
        }

        if kind.takesAWorker, !workers.isEmpty {
            // Whoever knows the most walks - which is what makes this
            // incident hurt long after the cash hit is forgotten.
            if let idx = workers.indices.max(by: { workers[$0].experience < workers[$1].experience }) {
                let leaver = workers[idx]
                workers.remove(at: idx)
                consequences.append(String(localized: "\(leaver.name) left, taking their experience with them.", comment: "Incident consequence: worker leaves"))
            }
        }

        if mitigated {
            consequences.append(String(localized: "\(kind.mitigationClass.name(in: brief.scenario)) limited the damage.", comment: "Incident consequence: mitigation softened it"))
        }

        incidentsFired += 1
        let event = SimEvent(kind: kind, message: kind.message, grossCost: gross,
                             insuranceCovered: covered, consequences: consequences)
        if activeEvent == nil {
            activeEvent = event
            activeEventAge = 0
        } else if eventQueue.count < 4 {
            eventQueue.append(event)
        }
        // Incidents fire after this tick's recompute, so refresh the
        // headline figures here - otherwise destroyed work and added scope
        // do not show up until the following tick and the banner appears to
        // contradict the progress bar.
        recomputeProgress()
        log(kind.title, symbol: kind.symbolName, tone: .bad)
    }

    private func scaled(_ range: ClosedRange<Double>, _ t: Double) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * min(max(t, 0), 1)
    }

    func dismissEvent() {
        activeEvent = eventQueue.isEmpty ? nil : eventQueue.removeFirst()
        activeEventAge = 0
    }

    /// Banners expire on their own after a few simulated days. Before this,
    /// an undismissed banner suppressed every later incident for the rest
    /// of the run - a run played without touching it saw exactly one.
    private func ageActiveEvent(step: Double) {
        guard activeEvent != nil else { return }
        activeEventAge += step
        if activeEventAge >= 3.0 || !eventQueue.isEmpty && activeEventAge >= 1.5 {
            dismissEvent()
        }
    }

    /// How many incidents are waiting behind the one on screen.
    var queuedEventCount: Int { eventQueue.count }

    // MARK: Forecast (Planning)

    private func updateForecast() {
        let horizon = CapabilityEffects.forecastHorizonDays(level: level(of: .planning))
        guard horizon > 0 else { forecast = nil; return }
        let daysAway = nextIncidentDay - elapsedDays
        guard daysAway <= horizon, daysAway >= 0 else { forecast = nil; return }
        forecast = RiskForecast(mitigationClass: nextIncidentClass,
                                daysAway: daysAway,
                                severity: nextIncidentSeverity)
    }

    /// Current throughput in units per day, used for the completion
    /// estimate. Only meaningful once Planning is staffed.
    var currentThroughput: Double {
        var total = 0.0
        for package in workPackages where package.isUnlocked && !package.isComplete
            && !package.isStarvedOfMaterials {
            let crew = workers.filter { $0.packageID == package.id && !$0.isInTraining }
            guard !crew.isEmpty else { continue }
            let raw = crew.reduce(0) { $0 + $1.effectiveOutput }
            total += raw
                * WorkPackage.congestionFactor(crewSize: crew.count, optimalCrew: package.optimalCrew)
                * WorkPackage.mentoringDrag(greenCount: crew.filter(\.isOnboarding).count)
                * WorkPackage.overtimeFactor(package.overtime)
        }
        return total
    }

    /// Estimated completion day with a confidence band, or nil when
    /// Planning is not staffed. Buying certainty is Planning's whole job.
    var completionEstimate: (day: Double, low: Double, high: Double)? {
        let planningLevel = level(of: .planning)
        guard planningLevel > 0 else { return nil }
        let throughput = currentThroughput
        guard throughput > 0.01 else { return nil }
        let remaining = workPackages.reduce(0) { $0 + $1.unitsRemaining }
        let eta = elapsedDays + remaining / throughput
        let band = (eta - elapsedDays) * CapabilityEffects.forecastUncertainty(level: planningLevel)
        return (day: eta, low: eta - band, high: eta + band)
    }

    // MARK: - Player actions: hiring

    func requestHire(for packageID: WorkPackage.ID) {
        guard let package = workPackages.first(where: { $0.id == packageID }), package.isUnlocked else { return }
        // A tight labour market and a bad reputation both show up here as
        // worse people asking for more money.
        let tightness = brief.labourMarketFactor * (1 + max(0, 0.75 - reputation) * 0.5)
        hiringRequest = HiringRequest(
            id: packageID,
            packageTitle: package.title,
            candidates: Candidate.pool(for: packageID, marketWageFactor: tightness, poolQuality: reputation),
            marketWageFactor: tightness
        )
    }

    func confirmHire(_ candidate: Candidate) {
        defer { hiringRequest = nil }
        guard ledger.spend(candidate.worker.signingCost, into: \.signing) else {
            log(String(localized: "Not enough funds to hire \(candidate.name).", comment: "Site log: hire failed"),
                symbol: "xmark.circle.fill", tone: .bad)
            return
        }
        workers.append(candidate.worker)
        log(String(localized: "\(candidate.name) hired to \(workPackages.first { $0.id == candidate.worker.packageID }?.title ?? "").", comment: "Site log: hired"),
            symbol: "person.badge.plus", tone: .neutral)
    }

    func cancelHiring() { hiringRequest = nil }

    /// Firing costs cash now, destroys the experience that worker built
    /// up, dents morale across the whole company, and makes the next
    /// candidate pool worse. In the old build firing *improved* both
    /// gauges, which made churn a repair mechanic.
    func fire(workerID: Worker.ID) {
        guard let idx = workers.firstIndex(where: { $0.id == workerID }) else { return }
        let worker = workers[idx]
        ledger.forceSpend(worker.severanceCost, into: \.severance)
        workers.remove(at: idx)
        // Company-wide, not just that crew - a layoff on Structure slows
        // Construction too.
        for i in workers.indices {
            workers[i].morale = max(0, workers[i].morale - 0.07)
        }
        reputation = max(0, reputation - 0.06)
        clientTrust = max(0, clientTrust - 0.01)
        log(String(localized: "\(worker.name) let go. Severance \(Int(worker.severanceCost).formatted()).", comment: "Site log: fired"),
            symbol: "person.badge.minus", tone: .bad)
    }

    func crew(for packageID: WorkPackage.ID) -> [Worker] {
        workers.filter { $0.packageID == packageID }
    }

    func setOvertime(_ value: Double, for packageID: WorkPackage.ID) {
        guard let idx = workPackages.firstIndex(where: { $0.id == packageID }) else { return }
        workPackages[idx].overtime = min(1, max(0, value))
    }

    // MARK: - Player actions: capabilities

    func level(of kind: CapabilityKind) -> Int {
        capabilities.first { $0.kind == kind }?.level ?? 0
    }

    func upgrade(_ kind: CapabilityKind) {
        guard let idx = capabilities.firstIndex(where: { $0.kind == kind }),
              capabilities[idx].isUnlocked, !capabilities[idx].isMaxed else { return }
        let cost = capabilities[idx].nextLevelCost * brief.capabilityCostFactor * organisationLoad
        guard ledger.spend(cost, into: \.capabilities) else {
            log(String(localized: "Not enough funds to staff \(kind.displayName(in: brief.scenario)).", comment: "Site log: capability unaffordable"),
                symbol: "xmark.circle.fill", tone: .bad)
            return
        }
        capabilities[idx].level += 1
        capabilities[idx].invested += cost
        log(String(localized: "\(kind.displayName(in: brief.scenario)) staffed to level \(capabilities[idx].level).", comment: "Site log: capability upgraded"),
            symbol: "arrow.up.circle.fill", tone: .good)
    }

    /// Stepping a capability back down. Refunds nothing - you are standing
    /// a team down, not returning a purchase. The old build refunded the
    /// full price and re-rolled the effect, which made buy/sell an
    /// arbitrage loop with positive expected value.
    func standDown(_ kind: CapabilityKind) {
        guard let idx = capabilities.firstIndex(where: { $0.kind == kind }), capabilities[idx].level > 0 else { return }
        capabilities[idx].level -= 1
        log(String(localized: "\(kind.displayName(in: brief.scenario)) stood down to level \(capabilities[idx].level).", comment: "Site log: capability reduced"),
            symbol: "arrow.down.circle", tone: .neutral)
    }

    // MARK: - Player actions: risk portfolio

    func buyMitigation(_ mitigationClass: MitigationClass) {
        guard level(of: .risk) > 0, !mitigationsHeld.contains(mitigationClass) else { return }
        guard ledger.spend(mitigationClass.purchaseCost, into: \.capabilities) else { return }
        mitigationsHeld.insert(mitigationClass)
        log(String(localized: "\(mitigationClass.name(in: brief.scenario)) in place.", comment: "Site log: mitigation bought"),
            symbol: mitigationClass.symbolName, tone: .good)
    }

    // MARK: - Player actions: materials

    /// Sentinel package id for a purchase that goes to inventory rather
    /// than to a work stream.
    static let stockOrderID = "__stock__"

    /// Opens the supplier panel to buy goods for resale. Same suppliers,
    /// same trade-off between price, lead time and reliability - but here
    /// what arrives is the thing you sell, not an input to labour.
    func requestStockOrder() {
        guard let spec = brief.trade else { return }
        let discount = 1 - CapabilityEffects.materialDiscount(level: level(of: .procurement))
        orderRequest = MaterialOrderRequest(
            id: Self.stockOrderID,
            packageTitle: String(localized: "Stock", comment: "Order sheet title for a stock purchase"),
            vendors: vendors,
            suggestedQuantity: suggestedStockQuantity,
            baseCostPerUnit: spec.landedCostPerUnit * discount,
            baseLeadTimeDays: 26 * CapabilityEffects.leadTimeMultiplier(level: level(of: .procurement)),
            marketIndex: market.effectiveIndex,
            isLocked: market.isLocked
        )
    }

    /// Enough to cover the next stretch of selling at the current rate,
    /// which is a starting point rather than an answer - the whole skill
    /// is deciding how far ahead to commit.
    private var suggestedStockQuantity: Double {
        guard let trading, let spec = brief.trade else { return 0 }
        let inFlight = orders.filter { $0.packageID == Self.stockOrderID }.reduce(0) { $0 + $1.quantity }
        let totalUnits = workPackages.reduce(0) { $0 + $1.units }
        let breadth = totalUnits > 0 ? workPackages.reduce(0) { $0 + $1.unitsCompleted } / totalUnits : 0
        let horizon = 30.0
        var expected = 0.0
        for d in 0..<Int(horizon) {
            expected += spec.demand(on: elapsedDays + 26 + Double(d), breadth: max(breadth, 0.4))
        }
        return max(0, (expected - trading.unitsOnHand - inFlight)).rounded()
    }

    func requestMaterialOrder(for packageID: WorkPackage.ID) {
        guard let package = workPackages.first(where: { $0.id == packageID }) else { return }
        let inFlight = orders.filter { $0.packageID == packageID }.reduce(0) { $0 + $1.quantity }
        let needed = package.unitsRemaining * package.spec.materialUnitsPerWorkUnit
        let suggested = max(0, needed - package.materialStock - inFlight)
        let discount = 1 - CapabilityEffects.materialDiscount(level: level(of: .procurement))
        orderRequest = MaterialOrderRequest(
            id: packageID,
            packageTitle: package.title,
            vendors: vendors,
            suggestedQuantity: suggested > 0 ? suggested.rounded(.up) : 0,
            baseCostPerUnit: package.spec.materialCostPerUnit * discount,
            baseLeadTimeDays: package.spec.baseLeadTimeDays
                * CapabilityEffects.leadTimeMultiplier(level: level(of: .procurement)),
            marketIndex: market.effectiveIndex,
            isLocked: market.isLocked
        )
    }

    func cancelMaterialOrder() { orderRequest = nil }

    func placeOrder(vendor: Vendor, quantity: Double) {
        defer { orderRequest = nil }
        guard let request = orderRequest, quantity > 0 else { return }
        let unitPrice = request.baseCostPerUnit * market.effectiveIndex * vendor.priceFactor
        let total = unitPrice * quantity
        guard ledger.spend(total, into: \.materials) else {
            log(String(localized: "Not enough funds for that order.", comment: "Site log: order unaffordable"),
                symbol: "xmark.circle.fill", tone: .bad)
            return
        }
        var leadTime = request.baseLeadTimeDays * vendor.leadTimeFactor
        var slipped = false
        if Double.random(in: 0...1) < vendor.unreliability {
            leadTime += Double.random(in: 4...11)
            slipped = true
        }
        var order = MaterialOrder(packageID: request.id, vendorName: vendor.name, quantity: quantity,
                                  pricePaid: total, arrivalDay: elapsedDays + leadTime,
                                  orderedDay: elapsedDays, vendorDefectPerUnit: vendor.defectPerUnit)
        order.hasSlipped = slipped
        orders.append(order)

        log(String(localized: "Ordered \(Int(quantity)) units from \(vendor.name), \(Int(leadTime)) days out.", comment: "Site log: order placed"),
            symbol: "cart.fill", tone: .neutral)
    }

    /// Locks the materials index for 30 days at a premium. Needs a real
    /// procurement desk (Acquisitions level 2) behind it.
    func hedgeMaterialPrice() {
        guard CapabilityEffects.canHedge(level: level(of: .procurement)), !market.isLocked else { return }
        let exposure = workPackages.reduce(0) { partial, package in
            partial + package.unitsRemaining * package.spec.materialUnitsPerWorkUnit * package.spec.materialCostPerUnit
        }
        let premium = exposure * market.lockPremiumRate * 0.35
        guard ledger.spend(premium, into: \.materials) else { return }
        market.lockPrice(for: 30)
        log(String(localized: "Price locked for 30 days at \(String(format: "%.2f", market.lockedIndex)).", comment: "Site log: hedge placed"),
            symbol: "lock.fill", tone: .good)
    }

    // MARK: - Player actions: planning and training

    var fastTrackablePackages: [WorkPackage] {
        let allowance = CapabilityEffects.fastTrackAllowance(level: level(of: .planning))
        guard allowance > 0 else { return [] }
        return workPackages.filter {
            !$0.isUnlocked && totalProgress >= $0.spec.startThreshold - allowance
        }
    }

    func fastTrack(_ packageID: WorkPackage.ID) {
        guard fastTrackablePackages.contains(where: { $0.id == packageID }),
              let idx = workPackages.firstIndex(where: { $0.id == packageID }) else { return }
        workPackages[idx].isUnlocked = true
        workPackages[idx].isFastTracked = true
        log(String(localized: "\(workPackages[idx].title) fast-tracked. Expect rework.", comment: "Site log: fast-tracked"),
            symbol: "bolt.fill", tone: .neutral)
    }

    func enrollInTraining(_ workerID: Worker.ID) {
        let trainingLevel = level(of: .training)
        guard trainingLevel > 0, let idx = workers.firstIndex(where: { $0.id == workerID }),
              !workers[idx].isInTraining else { return }
        guard ledger.spend(CapabilityEffects.courseCostPerWorker, into: \.training) else { return }
        workers[idx].trainingDaysRemaining = CapabilityEffects.courseDays(level: trainingLevel)
        workers[idx].pendingSkillGain = CapabilityEffects.courseSkillGain(level: trainingLevel)
        workers[idx].pendingExperienceGain = CapabilityEffects.courseExperienceGain(level: trainingLevel)
        log(String(localized: "\(workers[idx].name) sent on a course.", comment: "Site log: training started"),
            symbol: "graduationcap", tone: .neutral)
    }

    /// Asks the client for more time. Only granted with real trust behind
    /// it, and only once - Communications buying you a deadline extension
    /// is the clearest possible payoff for a capability that otherwise
    /// only shows up as faster payments.
    var canRequestExtension: Bool {
        !extensionUsed && clientTrust >= CapabilityEffects.extensionTrustThreshold && outcome == nil
    }

    func requestExtension() {
        guard canRequestExtension else { return }
        extensionUsed = true
        deadlineDays += CapabilityEffects.extensionDaysGranted
        clientTrust = max(0, clientTrust - 0.18)
        log(String(localized: "Client granted \(Int(CapabilityEffects.extensionDaysGranted)) more days.", comment: "Site log: extension granted"),
            symbol: "calendar.badge.plus", tone: .good)
    }

    // MARK: - Handover

    /// The end of a startup run: an acquirer prices the company on its
    /// revenue, its growth rate and whatever diligence turns up, and the
    /// founder takes home whatever share of that they still own.
    private func performExit() {
        guard let growth else { return finish(.insolvent) }
        let openDebt = workPackages.reduce(0) { $0 + $1.defectDebt }
        let offer = growth.exitValuation(openTechDebt: openDebt)
        exitOffer = offer

        for payment in pendingPayments { ledger.receive(payment.net, retainage: payment.retainage) }
        pendingPayments = []

        let proceeds = offer.netValuation * ledger.founderEquity
        if proceeds > 0 {
            ledger.receive(proceeds, retainage: 0)
            log(String(localized: "Acquired for \(Int(offer.netValuation).formatted()). Your share: \(Int(proceeds).formatted()).", comment: "Site log: exit"),
                symbol: "sparkles", tone: .good)
        } else {
            log(String(localized: "No acquirer. With no revenue there is nothing to price.", comment: "Site log: no exit"),
                symbol: "xmark.octagon.fill", tone: .bad)
        }
        if offer.diligenceHaircut > 0 {
            log(String(localized: "Diligence knocked \(Int(offer.diligenceHaircut).formatted()) off for tech debt.", comment: "Site log: diligence haircut"),
                symbol: "doc.text.magnifyingglass", tone: .bad)
        }
        finish(.delivered)
    }

    private func performHandover() {
        let openDefects = workPackages.reduce(0) { $0 + $1.defectDebt }
        if openDefects > 0.01 {
            // Everything Quality did not catch during the build comes due
            // here, at four and a half times the price, plus delay.
            ledger.forceSpend(openDefects * CapabilityEffects.reworkCostPerDefect, into: \.rework)
            elapsedDays += openDefects * CapabilityEffects.reworkDaysPerDefect
            accrueLatePenalties()
        }
        // Close out anything the client still owed.
        for payment in pendingPayments { ledger.receive(payment.net, retainage: payment.retainage) }
        pendingPayments = []

        let deduction = openDefects * CapabilityEffects.reworkCostPerDefect
            * 0.5 * brief.clientPersona.defectWithholdingFactor
        ledger.releaseRetainage(deduction: deduction)

        if elapsedDays < deadlineDays {
            let bonus = (deadlineDays - elapsedDays) * brief.earlyBonusPerDay
            ledger.receive(bonus, retainage: 0)
            log(String(localized: "Early completion bonus \(Int(bonus).formatted()).", comment: "Site log: early bonus"),
                symbol: "star.fill", tone: .good)
        }
        finish(.delivered)
    }

    private func finish(_ result: RunOutcome) {
        outcome = result
        setSpeed(.paused)
        log(result == .delivered
            ? String(localized: "Project handed over.", comment: "Site log: delivered")
            : String(localized: "Insolvent. The project is over.", comment: "Site log: insolvent"),
            symbol: result == .delivered ? "flag.checkered" : "xmark.octagon.fill",
            tone: result == .delivered ? .good : .bad)
    }

    // MARK: - Derived readouts

    var dailyBurn: Double {
        let payroll = workers.reduce(0) { $0 + $1.dailyWage }
        let upkeep = capabilities.reduce(0) { $0 + $1.dailyUpkeep }
            + mitigationsHeld.reduce(0) { $0 + $1.dailyUpkeep }
        let lateCost = elapsedDays > deadlineDays ? brief.latePenaltyPerDay : 0
        return payroll + upkeep + lateCost
    }

    /// Everything going out, net of what comes in. Once subscription
    /// revenue covers the burn this goes to zero and the runway is
    /// infinite - the company is default alive.
    var netDailyBurn: Double {
        var net = dailyBurn
        if let growth {
            net += growth.dailyCostToServe + growth.dailyGrowthSpend
            net -= growth.dailyRevenue
        }
        return net
    }

    var runwayDays: Double { ledger.runwayDays(dailyBurn: max(0, netDailyBurn)) }

    var averageMorale: Double {
        guard !workers.isEmpty else { return 1 }
        return workers.reduce(0) { $0 + $1.morale } / Double(workers.count)
    }

    /// Defects the player can actually see. Without Quality staffed this
    /// is deliberately hidden - not knowing is the cost of not inspecting.
    var visibleDefectDebt: Double? {
        guard level(of: .quality) > 0 else { return nil }
        return workPackages.reduce(0) { $0 + $1.defectDebt }
    }

    var totalIdleCrewDays: Double {
        workPackages.reduce(0) { $0 + $1.idleCrewDays }
    }

    var daysRemaining: Double { deadlineDays - elapsedDays }

    var result: RunResult {
        RunResult(
            scenario: brief.scenario,
            exitOffer: exitOffer,
            seasonClose: seasonClose,
            founderEquity: ledger.founderEquity,
            capitalRaised: ledger.capitalRaised,
            launchDay: growth?.launchDay,
            outcome: outcome ?? .insolvent,
            profit: ledger.profit,
            revenue: ledger.revenueReceived + ledger.retainageHeld,
            costs: ledger.costs,
            days: elapsedDays,
            deadlineDays: deadlineDays,
            progress: totalProgress,
            openDefects: workPackages.reduce(0) { $0 + $1.defectDebt },
            resolvedDefects: workPackages.reduce(0) { $0 + $1.defectsResolved },
            idleCrewDays: totalIdleCrewDays,
            finalCrewSize: workers.count,
            clientTrust: clientTrust,
            reputation: reputation,
            difficulty: brief.difficulty,
            persona: brief.clientPersona,
            seed: brief.seed
        )
    }

    // MARK: - Test support
    //
    // Deliberately narrow hooks for forcing the states that are hard to
    // reach by playing normally - a stranded crew, an empty bank. Not
    // reachable from the UI.

    /// Strands or resupplies a package, to exercise the idle-crew path.
    func debugSetMaterialStock(_ quantity: Double, for packageID: WorkPackage.ID) {
        guard let idx = workPackages.firstIndex(where: { $0.id == packageID }) else { return }
        workPackages[idx].materialStock = max(0, quantity)
    }

    /// Forces a package's built quantity, to exercise end-of-package edges.
    func debugSetUnitsCompleted(_ units: Double, for packageID: WorkPackage.ID) {
        guard let idx = workPackages.firstIndex(where: { $0.id == packageID }) else { return }
        workPackages[idx].unitsCompleted = max(0, min(units, workPackages[idx].units))
    }

    /// Puts the product live without playing through the build, so the
    /// growth loop can be tested on its own.
    func debugLaunchProduct() {
        growth?.launch(onDay: elapsedDays)
    }

    /// Empties the bank and the credit line, to exercise insolvency.
    func debugDrainCash() {
        ledger.debugDrain()
    }

    // MARK: - Site log

    private func log(_ text: String, symbol: String, tone: SiteLogEntry.Tone) {
        siteLog.insert(SiteLogEntry(day: Int(elapsedDays), text: text, symbol: symbol, tone: tone), at: 0)
        if siteLog.count > 60 { siteLog.removeLast(siteLog.count - 60) }
        // Same trail, kept for crash reports - if the app dies, this is
        // what says which action it died on.
        Diagnostics.shared.breadcrumb("d\(Int(elapsedDays)) \(text)")
    }
}

// MARK: - Result

struct RunResult {
    let scenario: ScenarioKind
    /// Startup runs only. What the company sold for and on what basis.
    let exitOffer: ExitOffer?
    /// Import runs only. What the season came to once the leftovers went.
    let seasonClose: SeasonClose?
    /// The founder's remaining share at the exit.
    let founderEquity: Double
    /// Capital taken in. Not earnings - kept separate so the debrief can
    /// show that raising is not the same as making money.
    let capitalRaised: Double
    let launchDay: Double?
    let outcome: RunOutcome
    let profit: Double
    let revenue: Double
    let costs: CostBreakdown
    let days: Double
    let deadlineDays: Double
    let progress: Double
    let openDefects: Double
    let resolvedDefects: Double
    let idleCrewDays: Double
    let finalCrewSize: Int
    let clientTrust: Double
    let reputation: Double
    let difficulty: Difficulty
    let persona: ClientPersona
    let seed: UInt64

    var wasOnTime: Bool { days <= deadlineDays }
    var margin: Double { revenue > 0 ? profit / revenue : 0 }

    /// The leaderboard number. Profit is the only metric that generalizes
    /// across every planned scenario - a café and an import business have
    /// no "days" or "quality gauge" in common with a building, but they
    /// all have a P&L. Difficulty scales it so a Tight win outranks a
    /// Steady one.
    var score: Double {
        guard outcome == .delivered else { return 0 }
        // Never launching is not a delivery, however tidy the books look.
        if scenario == .startup, launchDay == nil { return 0 }
        let onTimeBonus = wasOnTime ? 1.1 : 1.0
        return max(0, profit) * difficulty.scoreMultiplier * onTimeBonus
    }
}

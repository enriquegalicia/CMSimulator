//
//  ScheduleBoardView.swift
//  CMSimulator
//
//  The Path board (build 3): the run as a live schedule. One bar per work
//  stream on a day axis, the deadline and today drawn across it, the
//  critical path in lime and every other stream's float written beside it.
//  Under the chart: what is setting the finish date right now and the one
//  move that would change it, then (on a contract) each progress payment's
//  certified day against the day the money actually lands.
//
//  The model is in Engine/Schedule.swift.
//

import SwiftUI

struct ScheduleBoardView: View {
    let schedule: ProjectSchedule
    let operationNoun: String
    let usesSupplyChain: Bool
    let paymentDelayDays: Double
    let launchedDay: Double?
    let isTrading: Bool
    /// Without Planning staffed the board still draws the plan, but calls
    /// it rough: certainty is what Planning sells.
    let hasPlanning: Bool
    let onHire: (WorkPackage.ID) -> Void
    let onOrder: (WorkPackage.ID) -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    var body: some View {
        VStack(spacing: 10) {
            headline
            VStack(alignment: .leading, spacing: 8) {
                GanttChart(schedule: schedule)
                    .frame(height: GanttChart.height(for: schedule))
                legend
            }
            .padding(12)
            .cpPanel()

            if let row = focusRow { criticalCard(row) }
            if !schedule.milestones.isEmpty { paymentsCard }
        }
    }

    // MARK: Headline

    /// A startup is judged on when it launches, a trader on when it starts
    /// selling; a contract on when it hands over.
    private var focusRow: ScheduleRow? {
        switch schedule.scenario {
        case .construction:
            return schedule.critical
        case .startup, .importing:
            if launchedDay == nil, !isTrading, let launch = schedule.launch, launch.status != .done { return launch }
            return schedule.critical
        }
    }

    private var headline: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.title2)
                .foregroundStyle(CP.lime)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(headlineTitle)
                    .font(.headline)
                    .foregroundStyle(CP.ink)
                if let detail = headlineDetail {
                    Text(detail.text)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(detail.tint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cpPanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("path.headline")
    }

    private var headlineTitle: String {
        switch schedule.scenario {
        case .construction:
            if let finish = schedule.finish {
                return hasPlanning
                    ? String(localized: "Handover forecast: day \(Int(finish.rounded()))", comment: "Path board headline")
                    : String(localized: "Rough plan: handover around day \(Int(finish.rounded()))", comment: "Path board headline without Planning")
            }
            return String(localized: "No handover date yet", comment: "Path board headline when nothing can be forecast")
        case .startup:
            if let launchedDay { return String(localized: "Launched on day \(Int(launchedDay))", comment: "Path board headline, startup") }
            if let finish = schedule.launch?.finish {
                return hasPlanning
                    ? String(localized: "Launch forecast: day \(Int(finish.rounded()))", comment: "Path board headline, startup")
                    : String(localized: "Rough plan: launch around day \(Int(finish.rounded()))", comment: "Path board headline without Planning")
            }
            return String(localized: "No launch date yet", comment: "Path board headline, startup")
        case .importing:
            if isTrading { return String(localized: "Selling. The season closes on day \(Int(schedule.deadline))", comment: "Path board headline, import") }
            if let finish = schedule.launch?.finish {
                return hasPlanning
                    ? String(localized: "First sales forecast: day \(Int(finish.rounded()))", comment: "Path board headline, import")
                    : String(localized: "Rough plan: first sales around day \(Int(finish.rounded()))", comment: "Path board headline without Planning")
            }
            return String(localized: "No first-sales date yet", comment: "Path board headline, import")
        }
    }

    private var headlineDetail: (text: String, tint: Color)? {
        switch schedule.scenario {
        case .construction:
            guard let margin = schedule.margin else {
                return focusRow.map { (String(localized: "\($0.title) can't be timed yet.", comment: "Path board: blocker"), CP.amber) }
            }
            if !hasPlanning {
                return (String(localized: "Staff Planning on the Levers tab for a real forecast and early warnings.", comment: "Path board: no Planning"), CP.inkSoft)
            }
            if margin >= 0 {
                return (String(localized: "\(Int(margin.rounded())) days inside the \(Int(schedule.deadline))-day contract", comment: "Path board: margin"), CP.lime)
            }
            return (String(localized: "\(Int((-margin).rounded())) days late against the contract: penalties run every one of them", comment: "Path board: late"), CP.late)
        case .startup:
            return (String(localized: "The exit is on day \(Int(schedule.deadline)). Every day before launch is growth you don't get.", comment: "Path board: startup detail"), CP.inkSoft)
        case .importing:
            if let peak = schedule.seasonPeak {
                return (String(localized: "Demand planning reads the season peak at about day \(Int(peak.rounded())).", comment: "Path board: import detail"), CP.amber)
            }
            return (String(localized: "Staff Demand planning to see when the season peaks.", comment: "Path board: import detail, no planning"), CP.inkSoft)
        }
    }

    // MARK: Critical card

    private func criticalCard(_ row: ScheduleRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(cardTitle, systemImage: "scope")
                .font(.subheadline.bold())
                .foregroundStyle(CP.lime)
            Text(explanation(for: row))
                .font(.subheadline)
                .foregroundStyle(CP.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                if row.status == .noCrew || (row.status == .building && row.crew < row.optimalCrew) {
                    Button { onHire(row.id) } label: {
                        Label(String(localized: "Hire for \(row.title)", comment: "Path board action"), systemImage: "person.badge.plus")
                            .font(.caption.bold())
                    }
                    .cpProminent()
                    .controlSize(.small)
                    .accessibilityIdentifier("path.hire")
                }
                if row.status == .waitingOnInputs, usesSupplyChain {
                    Button { onOrder(row.id) } label: {
                        Label(String(localized: "Order for \(row.title)", comment: "Path board action"), systemImage: "cart.fill")
                            .font(.caption.bold())
                    }
                    .cpProminent()
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cpPanel()
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CP.lime.opacity(0.45), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("path.critical")
    }

    private var cardTitle: String {
        switch schedule.scenario {
        case .construction: return String(localized: "What sets your finish date", comment: "Path board card title")
        case .startup: return launchedDay == nil
            ? String(localized: "What sets your launch date", comment: "Path board card title")
            : String(localized: "What sets your finish date", comment: "Path board card title")
        case .importing: return isTrading
            ? String(localized: "What sets your finish date", comment: "Path board card title")
            : String(localized: "What sets your first sale", comment: "Path board card title")
        }
    }

    private func explanation(for row: ScheduleRow) -> String {
        switch row.status {
        case .noCrew:
            return String(localized: "Nobody is working on \(row.title). Until someone is, it can't finish, and neither can \(operationNoun). It works best with \(row.optimalCrew) people.", comment: "Critical path explanation: no crew")
        case .waitingOnInputs:
            return String(localized: "\(row.title)'s crew is on full pay with nothing to work with. Every idle day pushes the finish back.", comment: "Critical path explanation: starved")
        case .notYetStarted:
            return String(localized: "\(row.title) can't start until \(operationNoun) is \(Int(row.unlockAt))% done. Speed up what is running now and it starts sooner.", comment: "Critical path explanation: locked")
        case .building:
            if let margin = schedule.margin, margin < 0, schedule.scenario == .construction {
                return String(localized: "\(row.title) finishes on day \(Int((row.finish ?? 0).rounded())), after the deadline. A fuller crew (it works best with \(row.optimalCrew)), overtime or Planning's fast-track would pull it in.", comment: "Critical path explanation: late")
            }
            return String(localized: "\(row.title) has no float: if it slips a day, so does the finish. The other streams could slip a little and the date would hold.", comment: "Critical path explanation: on time")
        case .done:
            return String(localized: "\(row.title) is finished.", comment: "Critical path explanation: done")
        }
    }

    // MARK: Payments

    private var paymentsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Paid behind the work", comment: "Path board: payments card title"), systemImage: "banknote")
                .font(.subheadline.bold())
                .foregroundStyle(CP.ink)
            ForEach(schedule.milestones) { milestone in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(localized: "\(milestone.share, format: .percent.precision(.fractionLength(0))) of the contract", comment: "Payment milestone share"))
                            .font(.caption.bold())
                            .foregroundStyle(CP.ink)
                        Text(String(localized: "at \(Int(milestone.threshold))% built", comment: "Payment milestone trigger"))
                            .font(.caption2)
                            .foregroundStyle(CP.inkFaint)
                    }
                    Spacer()
                    Text(datesLine(milestone))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(milestone.isProjected ? CP.inkSoft : CP.lime)
                }
            }
            Text(String(localized: "Money lands about \(Int(paymentDelayDays.rounded())) days after a milestone is certified at today's trust. Communications and a happy client shorten the wait.", comment: "Path board: payment lag note"))
                .font(.caption2)
                .foregroundStyle(CP.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cpPanel()
        .accessibilityElement(children: .combine)
    }

    private func datesLine(_ milestone: ScheduleMilestone) -> String {
        guard let certified = milestone.certified, let paid = milestone.paid else {
            return String(localized: "not yet timed", comment: "Payment milestone with no forecast")
        }
        if milestone.isProjected, milestone.paid != nil, milestone.certified ?? .infinity <= schedule.today {
            return String(localized: "certified d\(Int(certified)) → ≈ paid d\(Int(paid.rounded()))", comment: "Payment milestone: certified, payment due")
        }
        if milestone.isProjected {
            return String(localized: "≈ d\(Int(certified.rounded())) → ≈ paid d\(Int(paid.rounded()))", comment: "Payment milestone: projected")
        }
        return String(localized: "certified d\(Int(certified)) → paid d\(Int(paid))", comment: "Payment milestone: history")
    }

    // MARK: Legend

    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(String(localized: "Done so far", comment: "Gantt legend")) {
                RoundedRectangle(cornerRadius: 2).fill(CP.steel)
            }
            legendItem(String(localized: "Forecast", comment: "Gantt legend")) {
                RoundedRectangle(cornerRadius: 2).strokeBorder(CP.steel, lineWidth: 1.2)
            }
            legendItem(String(localized: "Planned", comment: "Gantt legend")) {
                RoundedRectangle(cornerRadius: 2).fill(CP.steel.opacity(0.3))
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(CP.steel.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
            }
            legendItem(String(localized: "Critical path", comment: "Gantt legend")) {
                RoundedRectangle(cornerRadius: 2).fill(CP.lime)
            }
        }
        .font(.caption2)
        .foregroundStyle(CP.inkSoft)
        .accessibilityHidden(true)
    }

    private func legendItem<S: View>(_ label: String, @ViewBuilder swatch: () -> S) -> some View {
        HStack(spacing: 4) {
            swatch().frame(width: 16, height: 8)
            Text(label)
        }
    }
}

// MARK: - Gantt

/// One canvas: day axis, a bar per stream, today / deadline / finish lines,
/// float whiskers, and (on a contract) the payment milestones. Also drawn
/// in the debrief, for the schedule as the run left it.
struct GanttChart: View {
    let schedule: ProjectSchedule

    static let axisHeight: CGFloat = 20
    static let rowHeight: CGFloat = 34
    static let paymentsHeight: CGFloat = 30

    static func height(for schedule: ProjectSchedule) -> CGFloat {
        axisHeight + rowHeight * CGFloat(schedule.rows.count)
            + (schedule.milestones.isEmpty ? 8 : paymentsHeight) + 40
    }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(accessibilitySummary))
        .accessibilityIdentifier("path.gantt")
    }

    private var accessibilitySummary: String {
        schedule.rows.map { row in
            if row.status == .done {
                return String(localized: "\(row.title): done", comment: "Gantt accessibility row")
            }
            guard let finish = row.finish else {
                return String(localized: "\(row.title): can't be timed yet", comment: "Gantt accessibility row")
            }
            if row.isCritical {
                return String(localized: "\(row.title): finishes about day \(Int(finish.rounded())), on the critical path", comment: "Gantt accessibility row")
            }
            return String(localized: "\(row.title): finishes about day \(Int(finish.rounded())), \(Int((row.float ?? 0).rounded())) days of float", comment: "Gantt accessibility row")
        }
        .joined(separator: ". ")
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let labelWidth = min(128, size.width * 0.33)
        let x0 = labelWidth + 6
        let chartWidth = max(10, size.width - x0 - 30)
        let horizon = schedule.horizon
        func x(_ day: Double) -> CGFloat { x0 + CGFloat(min(max(day, 0), horizon) / horizon) * chartWidth }
        let top = Self.axisHeight
        let rowsBottom = top + Self.rowHeight * CGFloat(schedule.rows.count)
        let chartBottom = rowsBottom + (schedule.milestones.isEmpty ? 0 : Self.paymentsHeight)

        // Day axis and gridlines.
        // Four or five labels, whatever the width and the run's length.
        let room = max(1, Int(chartWidth / 44))
        let step = [5.0, 10, 20, 25, 30, 50, 100, 200].first { horizon / $0 <= Double(room) } ?? 200
        var tick = 0.0
        while tick <= horizon {
            let tx = x(tick)
            var grid = Path()
            grid.move(to: CGPoint(x: tx, y: top - 2))
            grid.addLine(to: CGPoint(x: tx, y: chartBottom))
            context.stroke(grid, with: .color(CP.rule.opacity(0.55)), lineWidth: 0.5)
            context.draw(Text(verbatim: "d\(Int(tick))").font(.system(size: 9, weight: .medium).monospacedDigit())
                            .foregroundColor(CP.inkFaint),
                         at: CGPoint(x: tx, y: top / 2), anchor: .center)
            tick += step
        }

        // Rows.
        for (index, row) in schedule.rows.enumerated() {
            let midY = top + Self.rowHeight * (CGFloat(index) + 0.5)
            let color = row.isCritical ? CP.lime : CP.steel

            // Label: status glyph + title.
            var glyph = context.resolve(Image(systemName: symbol(for: row.status)))
            glyph.shading = .color(row.isCritical ? CP.lime : CP.inkSoft)
            context.draw(glyph, in: CGRect(x: 0, y: midY - 6, width: 12, height: 12))
            context.draw(Text(row.title).font(.system(size: 11, weight: row.isCritical ? .bold : .medium))
                            .foregroundColor(row.isCritical ? CP.ink : CP.inkSoft),
                         in: CGRect(x: 16, y: midY - 8, width: labelWidth - 16, height: 16))

            guard let start = row.start else {
                context.draw(Text(verbatim: "?").font(.system(size: 11, weight: .bold)).foregroundColor(CP.amber),
                             at: CGPoint(x: x0 + 8, y: midY), anchor: .center)
                continue
            }
            let barHeight: CGFloat = 12
            let barY = midY - barHeight / 2
            let end = row.finish ?? horizon

            // Built so far.
            let builtEnd = row.status == .done ? end : min(schedule.today, end)
            if builtEnd > start {
                let rect = CGRect(x: x(start), y: barY, width: max(2, x(builtEnd) - x(start)), height: barHeight)
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color.opacity(0.95)))
            }

            // Still to come: outline when it's the crew's real pace, hatched
            // when it's a planning assumption.
            if row.status != .done {
                let from = max(start, schedule.today)
                if end > from {
                    let rect = CGRect(x: x(from), y: barY, width: max(2, x(end) - x(from)), height: barHeight)
                    let shape = Path(roundedRect: rect, cornerRadius: 3)
                    if row.finishIsPlanned || row.finish == nil {
                        context.fill(shape, with: .color(color.opacity(0.18)))
                        var hatch = Path()
                        var hx = rect.minX - barHeight
                        while hx < rect.maxX {
                            hatch.move(to: CGPoint(x: hx, y: rect.maxY))
                            hatch.addLine(to: CGPoint(x: hx + barHeight, y: rect.minY))
                            hx += 6
                        }
                        context.drawLayer { layer in
                            layer.clip(to: shape)
                            layer.stroke(hatch, with: .color(color.opacity(0.55)), lineWidth: 1)
                        }
                        context.stroke(shape, with: .color(color.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    } else {
                        context.fill(shape, with: .color(color.opacity(0.12)))
                        context.stroke(shape, with: .color(color), lineWidth: 1.4)
                    }
                    if row.isCritical, row.finish != nil {
                        var glow = context
                        glow.addFilter(.shadow(color: CP.lime.opacity(0.6), radius: 4))
                        glow.stroke(shape, with: .color(CP.lime.opacity(0.7)), lineWidth: 1)
                    }
                }
            }

            // Float whisker to the project finish.
            if let finish = row.finish, let float = row.float, float >= 1, row.status != .done,
               let projectFinish = schedule.finish {
                var whisker = Path()
                whisker.move(to: CGPoint(x: x(finish) + 2, y: midY))
                whisker.addLine(to: CGPoint(x: x(projectFinish), y: midY))
                context.stroke(whisker, with: .color(CP.inkFaint), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                context.draw(Text(verbatim: "+\(Int(float.rounded()))d").font(.system(size: 9, weight: .semibold).monospacedDigit())
                                .foregroundColor(CP.inkSoft),
                             at: CGPoint(x: x(finish) + 3, y: midY - 9), anchor: .leading)
            }
            if row.finish == nil {
                context.draw(Text(verbatim: "?").font(.system(size: 12, weight: .heavy)).foregroundColor(CP.amber),
                             at: CGPoint(x: x(horizon) + 8, y: midY), anchor: .center)
            }
            if row.id == schedule.launchID, schedule.scenario != .construction, let finish = row.finish {
                var flag = context.resolve(Image(systemName: schedule.scenario == .startup ? "paperplane.fill" : "cart.fill"))
                flag.shading = .color(CP.lime)
                context.draw(flag, in: CGRect(x: x(finish) + 3, y: midY - 6, width: 12, height: 12))
            }
        }

        // Payment milestones: certified (diamond) to paid (coin).
        if !schedule.milestones.isEmpty {
            let midY = rowsBottom + Self.paymentsHeight / 2
            var label = context.resolve(Image(systemName: "banknote"))
            label.shading = .color(CP.inkSoft)
            context.draw(label, in: CGRect(x: 0, y: midY - 6, width: 14, height: 12))
            context.draw(Text(String(localized: "Payments", comment: "Gantt payments row")).font(.system(size: 11, weight: .medium))
                            .foregroundColor(CP.inkSoft),
                         in: CGRect(x: 18, y: midY - 8, width: labelWidth - 18, height: 16))
            for milestone in schedule.milestones {
                guard let certified = milestone.certified, let paid = milestone.paid else { continue }
                let alpha = milestone.isProjected ? 0.45 : 1
                var lag = Path()
                lag.move(to: CGPoint(x: x(certified), y: midY))
                lag.addLine(to: CGPoint(x: x(paid), y: midY))
                context.stroke(lag, with: .color(CP.lime.opacity(0.5 * alpha)), style: StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
                let cx = x(certified)
                var diamond = Path()
                diamond.move(to: CGPoint(x: cx, y: midY - 5))
                diamond.addLine(to: CGPoint(x: cx + 5, y: midY))
                diamond.addLine(to: CGPoint(x: cx, y: midY + 5))
                diamond.addLine(to: CGPoint(x: cx - 5, y: midY))
                diamond.closeSubpath()
                context.stroke(diamond, with: .color(CP.lime.opacity(alpha)), lineWidth: 1.2)
                context.fill(Path(ellipseIn: CGRect(x: x(paid) - 4, y: midY - 4, width: 8, height: 8)),
                             with: .color(CP.lime.opacity(alpha)))
            }
        }

        // Vertical markers last, so they read over the bars.
        func marker(_ day: Double, _ color: Color, _ text: String, dashed: Bool, labelRow: CGFloat) {
            let mx = x(day)
            var line = Path()
            line.move(to: CGPoint(x: mx, y: top - 2))
            line.addLine(to: CGPoint(x: mx, y: chartBottom))
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.2, dash: dashed ? [4, 3] : []))
            context.draw(Text(verbatim: text).font(.system(size: 9, weight: .bold)).foregroundColor(color),
                         at: CGPoint(x: min(max(mx, x0 + 14), size.width - 22), y: chartBottom + 4 + labelRow * 11), anchor: .top)
        }
        if let peak = schedule.seasonPeak { marker(peak, CP.amber, String(localized: "peak", comment: "Gantt marker: season peak"), dashed: true, labelRow: 2) }
        marker(schedule.deadline, CP.late, String(localized: "deadline", comment: "Gantt marker"), dashed: false, labelRow: 1)
        if let finish = schedule.finish, schedule.scenario == .construction, abs(finish - schedule.deadline) > 0.5 {
            marker(finish, CP.lime, String(localized: "finish", comment: "Gantt marker"), dashed: false, labelRow: 2)
        }
        marker(schedule.today, CP.ink.opacity(0.8), String(localized: "today", comment: "Gantt marker"), dashed: true, labelRow: 0)
    }

    private func symbol(for status: ScheduleRow.Status) -> String {
        switch status {
        case .done: return "checkmark.circle.fill"
        case .building: return "hammer.fill"
        case .noCrew: return "person.fill.questionmark"
        case .waitingOnInputs: return "shippingbox"
        case .notYetStarted: return "lock.fill"
        }
    }
}

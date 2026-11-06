//
//  CashCurveView.swift
//  CMSimulator
//
//  The cash curve (build 3): money out, money in, and money earned but not
//  yet received, one point per day. The gap between "out" and "in" is what
//  your own capital and the credit line are carrying - the gap that sinks
//  businesses that are profitable on paper. Shown live on the main board
//  and again, for the whole run, in the debrief.
//

import Charts
import SwiftUI

struct CashCurveView: View, Equatable {
    let points: [CashPoint]
    var title: String = String(localized: "Cash curve", comment: "Cash curve card title")
    var height: CGFloat = 150

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    /// The board redraws ten times a second while the clock runs; the curve
    /// only changes once a day, so it skips every redraw in between.
    static func == (lhs: CashCurveView, rhs: CashCurveView) -> Bool {
        lhs.points == rhs.points && lhs.title == rhs.title && lhs.height == rhs.height
    }

    private var last: CashPoint? { points.last }
    private var gap: Double { (last?.spent ?? 0) - (last?.received ?? 0) }
    private var showsEarned: Bool { points.contains { $0.owed > 1 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: "chart.xyaxis.line")
                    .font(.subheadline.bold())
                    .foregroundStyle(CP.ink)
                Spacer()
                if let last {
                    Text(String(localized: "day \(Int(last.day))", comment: "Cash curve: current day"))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(CP.inkFaint)
                }
            }

            if points.count < 2 {
                Text("Press play. The curve draws itself one day at a time.", comment: "Cash curve placeholder")
                    .font(.caption)
                    .foregroundStyle(CP.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: height * 0.5)
            } else {
                chart.frame(height: height)
                legend
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(gap > 0 ? CP.amber : CP.lime)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .cpPanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cashCurve")
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Day", point.day), y: .value("Amount", point.spent),
                         series: .value("Line", "out"))
                    .foregroundStyle(CP.amber)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                if showsEarned {
                    LineMark(x: .value("Day", point.day), y: .value("Amount", point.earned),
                             series: .value("Line", "earned"))
                        .foregroundStyle(CP.inkSoft)
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }
                LineMark(x: .value("Day", point.day), y: .value("Amount", point.received),
                         series: .value("Line", "in"))
                    .foregroundStyle(CP.lime)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine().foregroundStyle(CP.rule.opacity(0.6))
                AxisValueLabel {
                    if let day = value.as(Double.self) {
                        Text(verbatim: "d\(Int(day))").foregroundStyle(CP.inkFaint)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(CP.rule.opacity(0.6))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount, format: .number.notation(.compactName).precision(.significantDigits(2)))
                            .foregroundStyle(CP.inkFaint)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var legend: some View {
        HStack(spacing: 12) {
            swatch(CP.amber, String(localized: "Money out", comment: "Cash curve legend"))
            swatch(CP.lime, String(localized: "Money in", comment: "Cash curve legend"))
            if showsEarned {
                swatch(CP.inkSoft, String(localized: "Earned, incl. not yet paid", comment: "Cash curve legend"), dashed: true)
            }
        }
        .font(.caption2)
        .foregroundStyle(CP.inkSoft)
    }

    private func swatch(_ color: Color, _ label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 4) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 4))
                path.addLine(to: CGPoint(x: 14, y: 4))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: dashed ? [3, 2] : []))
            .frame(width: 14, height: 8)
            Text(label)
        }
    }

    private var caption: String {
        let money = FloatingPointFormatStyle<Double>.Currency(code: currencyCode).precision(.fractionLength(0))
        if gap > 0 {
            return String(localized: "You have paid out \(gap.formatted(money)) more than has come in. Your own capital and the credit line are carrying that gap.", comment: "Cash curve caption: funding gap")
        }
        return String(localized: "Money in is ahead of money out by \((-gap).formatted(money)).", comment: "Cash curve caption: ahead")
    }
}

//
//  GaugeView.swift
//  CMSimulator
//
//  Compact meters for the header. Rewritten from the old semicircular
//  dial: the two things worth watching every day are now crew morale and
//  client trust, both plain 0...1 quantities, and a small horizontal bar
//  reads faster at a glance than a needle - which matters more now that
//  the header has to carry cash, runway and the deadline too.
//

import SwiftUI

struct MeterView: View {
    let title: String
    /// 0...1.
    let value: Double
    /// Below this the meter turns amber, and half of it turns red.
    var warningThreshold: Double = 0.45
    var icon: String?

    private var clamped: Double { min(max(value, 0), 1) }

    private var tint: Color {
        if clamped < warningThreshold / 2 { return .red }
        if clamped < warningThreshold { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.caption2)
                }
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Text(clamped, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(2, geo.size.width * clamped))
                }
            }
            .frame(height: 6)
        }
        .foregroundStyle(.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}

/// A headline number with a caption. The results screen and the header
/// both need these, and they must line up, so they share one view.
struct StatTile: View {
    let label: String
    let value: String
    var tint: Color = .primary
    var caption: String?
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .accessibilityElement(children: .combine)
    }
}

/// The materials price index, drawn as a sparkline. Acquisitions is the
/// one system where the player is holding a position rather than paying a
/// rate, so the shape of the line is the information.
struct MarketSparkline: View {
    let history: [Double]
    let current: Double
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: isLocked ? "lock.fill" : "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                Text("Materials")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Text(String(format: "%.2f", current))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(current > 1.08 ? .red : (current < 0.94 ? .green : .secondary))
            }
            GeometryReader { geo in
                let samples = history.suffix(40)
                let lo = (samples.min() ?? 1) - 0.02
                let hi = (samples.max() ?? 1) + 0.02
                let span = max(0.04, hi - lo)
                Path { path in
                    for (i, value) in samples.enumerated() {
                        let x = samples.count > 1
                            ? geo.size.width * Double(i) / Double(samples.count - 1)
                            : 0
                        let y = geo.size.height * (1 - (value - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(isLocked ? Color.blue : Color.accentColor,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Materials price index", comment: "Accessibility label for the market sparkline"))
        .accessibilityValue(String(format: "%.2f", current))
    }
}

#Preview {
    VStack(spacing: 16) {
        MeterView(title: "Morale", value: 0.72, icon: "figure.2")
        MeterView(title: "Client trust", value: 0.3, icon: "person.crop.circle")
        MarketSparkline(history: [1, 1.02, 0.99, 1.05, 1.12, 1.08, 1.15], current: 1.15, isLocked: false)
    }
    .padding()
}

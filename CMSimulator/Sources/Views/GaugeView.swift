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
    /// What this scenario calls the thing being priced.
    let supplyName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: isLocked ? "lock.fill" : "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                Text(supplyName)
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
        .accessibilityLabel(Text("\(supplyName) price index", comment: "Accessibility label for the market sparkline"))
        .accessibilityValue(String(format: "%.2f", current))
    }
}

#Preview {
    VStack(spacing: 16) {
        MeterView(title: "Morale", value: 0.72, icon: "figure.2")
        MeterView(title: "Client trust", value: 0.3, icon: "person.crop.circle")
        MarketSparkline(history: [1, 1.02, 0.99, 1.05, 1.12, 1.08, 1.15], current: 1.15,
                        isLocked: false, supplyName: "Materials")
    }
    .padding()
}

// MARK: - Progress drawing
//
//  Seeing the thing get built.
//
//  A percentage bar tells you how far along you are; it does not tell you
//  what exists. This draws the work itself, layer by layer, with each
//  layer's weight and opacity driven by its own stream's completion - so
//  the picture is not an illustration of progress, it is a readout of it.
//
//  Drawn as vectors rather than commissioned art because a blueprint is
//  line-work: it resolves cleanly at any size, animates exactly against
//  the numbers, and costs nothing to re-cut when the streams change.
//

/// How far each work stream has got, keyed by stream id.
struct StreamProgress {
    let fractions: [String: Double]

    subscript(_ id: String) -> Double {
        min(1, max(0, fractions[id] ?? 0))
    }

    /// Line weight and opacity both key off completion, so a stream that
    /// has barely started reads as a ghost and a finished one as ink.
    func ink(_ id: String) -> Double { 0.12 + 0.88 * self[id] }
}

struct ProgressDrawingView: View {
    let scenario: ScenarioKind
    let progress: StreamProgress

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height * 1.6)
            ZStack {
                switch scenario {
                case .construction: building(scale: s)
                case .startup: product(scale: s)
                case .importing: trade(scale: s)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: 148)
        .accessibilityLabel(Text("Progress drawing", comment: "Accessibility label for the progress illustration"))
        .accessibilityValue(Text(summary))
    }

    private var summary: String {
        let done = progress.fractions.values.filter { $0 >= 1 }.count
        return String(localized: "\(done) of \(progress.fractions.count) streams complete",
                      comment: "Accessibility value for the progress illustration")
    }

    // MARK: Construction — design first, then the building

    private func building(scale s: CGFloat) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let bx = w * 0.5, base = h * 0.88, bw = min(w * 0.52, h * 0.95), bh = h * 0.66
            let left = bx - bw / 2, right = bx + bw / 2, top = base - bh

            // Sheet grid — the paper everything is drawn on.
            var grid = Path()
            for i in 1..<6 { let x = w * CGFloat(i) / 6; grid.move(to: .init(x: x, y: 0)); grid.addLine(to: .init(x: x, y: h)) }
            for i in 1..<4 { let y = h * CGFloat(i) / 4; grid.move(to: .init(x: 0, y: y)); grid.addLine(to: .init(x: w, y: y)) }
            ctx.stroke(grid, with: .color(.secondary.opacity(0.10)), lineWidth: 0.5)

            // Design — the outline, drawn faint and sharpening.
            let d = progress.ink("design")
            var outline = Path()
            outline.move(to: .init(x: left, y: base))
            outline.addLine(to: .init(x: left, y: top + bh * 0.16))
            outline.addLine(to: .init(x: bx, y: top))
            outline.addLine(to: .init(x: right, y: top + bh * 0.16))
            outline.addLine(to: .init(x: right, y: base))
            outline.closeSubpath()
            ctx.stroke(outline, with: .color(.accentColor.opacity(d)), lineWidth: 1 + d)

            // Construction — the envelope filling in behind the frame.
            let c = progress["construction"]
            if c > 0.01 {
                ctx.fill(outline, with: .color(.orange.opacity(0.06 + 0.18 * c)))
            }

            // Structure — floors and columns gaining weight.
            let st = progress["structure"]
            if st > 0.01 {
                var frame = Path()
                let floors = 4
                for i in 1...floors where Double(i) / Double(floors) <= st + 0.001 {
                    let y = base - bh * 0.84 * CGFloat(i) / CGFloat(floors)
                    frame.move(to: .init(x: left, y: y)); frame.addLine(to: .init(x: right, y: y))
                }
                frame.move(to: .init(x: bx, y: base)); frame.addLine(to: .init(x: bx, y: top + bh * 0.16))
                ctx.stroke(frame, with: .color(.orange.opacity(0.35 + 0.65 * st)), lineWidth: 1 + 1.4 * st)
            }

            // Plumbing & HVAC — a riser climbing the building.
            let p = progress["ihs"]
            if p > 0.01 {
                var riser = Path()
                riser.move(to: .init(x: left + bw * 0.22, y: base - bh * 0.06))
                riser.addLine(to: .init(x: left + bw * 0.22, y: base - bh * 0.78 * CGFloat(p)))
                ctx.stroke(riser, with: .color(.teal.opacity(0.4 + 0.6 * p)), lineWidth: 2)
            }

            // Electrical — circuits, and the lights come on at the end.
            let e = progress["ies"]
            if e > 0.01 {
                var circuit = Path()
                circuit.move(to: .init(x: right - bw * 0.22, y: base - bh * 0.06))
                circuit.addLine(to: .init(x: right - bw * 0.22, y: base - bh * 0.62 * CGFloat(e)))
                ctx.stroke(circuit, with: .color(.purple.opacity(0.4 + 0.6 * e)),
                           style: .init(lineWidth: 1.6, dash: [4, 3]))
                if e > 0.98 {
                    for i in 0..<3 {
                        let y = base - bh * (0.22 + 0.22 * CGFloat(i))
                        let dot = Path(ellipseIn: .init(x: right - bw * 0.26, y: y - 3, width: 6, height: 6))
                        ctx.fill(dot, with: .color(.yellow))
                    }
                }
            }

            // Engineering — approval stamps on the sheet border.
            let g = progress["engineering"]
            let stamps = Int((g * 3).rounded(.down))
            for i in 0..<max(0, stamps) {
                let r = CGRect(x: w - 34 - CGFloat(i) * 13, y: h - 15, width: 10, height: 10)
                ctx.stroke(Path(roundedRect: r, cornerRadius: 2),
                           with: .color(.secondary.opacity(0.7)), lineWidth: 1)
            }
        }
    }

    // MARK: Startup — a product assembling itself

    private func product(scale s: CGFloat) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cw = min(w * 0.46, h * 1.1), ch = h * 0.68
            let x = (w - cw) / 2, y = (h - ch) / 2

            // Discovery — the frame of the thing, sketched.
            let d = progress.ink("discovery")
            let screen = Path(roundedRect: .init(x: x, y: y, width: cw, height: ch), cornerRadius: 10)
            ctx.stroke(screen, with: .color(.accentColor.opacity(d)),
                       style: .init(lineWidth: 1 + d, dash: progress["discovery"] >= 1 ? [] : [5, 4]))

            // Core platform — the substrate, drawn as a stack at the base.
            let pl = progress["platform"]
            for i in 0..<3 where Double(i) / 3 < pl {
                let r = CGRect(x: x + 12, y: y + ch - 16 - CGFloat(i) * 9, width: cw - 24, height: 6)
                ctx.fill(Path(roundedRect: r, cornerRadius: 2), with: .color(.blue.opacity(0.25 + 0.4 * pl)))
            }

            // MVP — the interface fills in.
            let m = progress["mvp"]
            if m > 0.01 {
                let r = CGRect(x: x + 12, y: y + 12, width: (cw - 24) * CGFloat(m), height: 10)
                ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(.accentColor.opacity(0.7)))
            }

            // Feature depth — rows of real content.
            let f = progress["features"]
            for i in 0..<4 where Double(i) / 4 < f {
                let r = CGRect(x: x + 12, y: y + 30 + CGFloat(i) * 11, width: (cw - 34), height: 5)
                ctx.fill(Path(roundedRect: r, cornerRadius: 2), with: .color(.secondary.opacity(0.35 + 0.3 * f)))
            }

            // Payments — the card, which is when money can arrive.
            let pay = progress["payments"]
            if pay > 0.01 {
                let r = CGRect(x: x + cw - 40, y: y + ch - 34, width: 28, height: 18)
                ctx.stroke(Path(roundedRect: r, cornerRadius: 3),
                           with: .color(.green.opacity(0.4 + 0.6 * pay)), lineWidth: 1.4)
            }

            // Scale & reliability — load bars beside the product.
            let sc = progress["scale"]
            for i in 0..<4 where Double(i) / 4 < sc {
                let barH = 6 + CGFloat(i) * 5
                let r = CGRect(x: x + cw + 10, y: y + ch - barH, width: 4, height: barH)
                ctx.fill(Path(roundedRect: r, cornerRadius: 1), with: .color(.purple.opacity(0.5 + 0.5 * sc)))
            }
        }
    }

    // MARK: Import — factory, container, warehouse, storefront

    private func trade(scale s: CGFloat) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let baseline = h * 0.76

            // Supplier vetting — the factory you chose, sketched.
            let v = progress.ink("vetting")
            var factory = Path()
            factory.addRect(.init(x: w * 0.06, y: baseline - h * 0.30, width: w * 0.17, height: h * 0.30))
            for i in 0..<3 {
                let cx = w * 0.09 + CGFloat(i) * w * 0.05
                factory.addRect(.init(x: cx, y: baseline - h * 0.40, width: w * 0.022, height: h * 0.10))
            }
            ctx.stroke(factory, with: .color(.accentColor.opacity(v)), lineWidth: 1 + v)

            // First product line — the container that carries it.
            let f = progress["firstline"]
            if f > 0.01 {
                let box = CGRect(x: w * 0.31, y: baseline - h * 0.20, width: w * 0.20, height: h * 0.20)
                ctx.stroke(Path(box), with: .color(.teal.opacity(0.35 + 0.65 * f)), lineWidth: 1.6)
                var ribs = Path()
                for i in 1..<5 {
                    let rx = box.minX + box.width * CGFloat(i) / 5
                    ribs.move(to: .init(x: rx, y: box.minY)); ribs.addLine(to: .init(x: rx, y: box.maxY))
                }
                ctx.stroke(ribs, with: .color(.teal.opacity(0.2 + 0.5 * f)), lineWidth: 0.8)
            }

            // Certification — the label on the box.
            let c = progress["compliance"]
            if c > 0.01 {
                let tag = CGRect(x: w * 0.325, y: baseline - h * 0.175, width: w * 0.05, height: h * 0.055)
                ctx.fill(Path(roundedRect: tag, cornerRadius: 1.5), with: .color(.green.opacity(0.3 + 0.6 * c)))
            }

            // Warehousing — shelves, filling as the operation scales.
            let wh = progress["warehouse"]
            if wh > 0.01 {
                var shelves = Path()
                for i in 0..<3 where Double(i) / 3 < wh {
                    let y = baseline - h * 0.09 - CGFloat(i) * h * 0.085
                    shelves.move(to: .init(x: w * 0.58, y: y)); shelves.addLine(to: .init(x: w * 0.78, y: y))
                }
                ctx.stroke(shelves, with: .color(.orange.opacity(0.4 + 0.6 * wh)), lineWidth: 2)
            }

            // Range extension — more product lines on the shelves.
            let r = progress["range"]
            for i in 0..<5 where Double(i) / 5 < r {
                let bx = w * 0.585 + CGFloat(i % 5) * w * 0.038
                let by = baseline - h * 0.135 - CGFloat(i / 3) * h * 0.085
                ctx.fill(Path(roundedRect: .init(x: bx, y: by, width: w * 0.028, height: h * 0.042), cornerRadius: 1),
                         with: .color(.teal.opacity(0.45 + 0.4 * r)))
            }

            // Retail accounts — the storefront that finally sells it.
            let a = progress["accounts"]
            if a > 0.01 {
                var shop = Path()
                shop.move(to: .init(x: w * 0.84, y: baseline))
                shop.addLine(to: .init(x: w * 0.84, y: baseline - h * 0.22))
                shop.addLine(to: .init(x: w * 0.94, y: baseline - h * 0.30))
                shop.addLine(to: .init(x: w * 0.94, y: baseline))
                ctx.stroke(shop, with: .color(.purple.opacity(0.35 + 0.65 * a)), lineWidth: 1.6)
                if a > 0.5 {
                    let awn = CGRect(x: w * 0.845, y: baseline - h * 0.19, width: w * 0.09, height: h * 0.035)
                    ctx.fill(Path(awn), with: .color(.purple.opacity(0.25 + 0.4 * a)))
                }
            }

            // Ground line.
            var ground = Path()
            ground.move(to: .init(x: 0, y: baseline)); ground.addLine(to: .init(x: w, y: baseline))
            ctx.stroke(ground, with: .color(.secondary.opacity(0.35)), lineWidth: 1)
        }
    }
}

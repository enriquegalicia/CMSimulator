//
//  GaugeView.swift
//  CMSimulator
//
//  SwiftUI port of SPI.m's custom drawRect: - a semicircular indicator
//  that goes red -> yellow -> green as `value` climbs from 0.5 to 1.5.
//

import SwiftUI

struct GaugeView: View {
    let title: String
    /// Expected domain roughly 0.5...1.5, matching the engine's clamp.
    let value: Double

    private var normalized: Double {
        min(max((value - 0.5) / 1.0, 0), 1)
    }

    private var color: Color {
        switch normalized {
        case ..<0.4: return .red
        case ..<0.6: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.bold())
            ZStack {
                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let center = CGPoint(x: rect.midX, y: rect.maxY)
                    let radius = min(size.width, size.height * 2) / 2 - 4

                    var track = Path()
                    track.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    context.stroke(track, with: .color(.gray.opacity(0.25)), lineWidth: 10)

                    var fill = Path()
                    let endAngle = 180 - (180 * normalized)
                    fill.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(endAngle), clockwise: false)
                    context.stroke(fill, with: .color(color), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                    let needleAngle = Angle.degrees(180 - (180 * normalized)).radians
                    let needleEnd = CGPoint(x: center.x + (radius - 6) * cos(needleAngle), y: center.y - (radius - 6) * sin(needleAngle))
                    var needle = Path()
                    needle.move(to: center)
                    needle.addLine(to: needleEnd)
                    context.stroke(needle, with: .color(.black), lineWidth: 2)
                }
                .aspectRatio(2, contentMode: .fit)
            }
            Text(String(format: "%.2f", value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    GaugeView(title: "Risk", value: 1.1)
        .frame(width: 140, height: 100)
        .padding()
}

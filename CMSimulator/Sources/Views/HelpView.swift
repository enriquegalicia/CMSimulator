//
//  HelpView.swift
//  CMSimulator
//
//  A short legend explaining the two card types, replacing the
//  original's dense hand-positioned legend screen.
//

import SwiftUI

struct HelpView: View {
    let onExit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How to Play").font(.title.bold())

                legendSection(
                    title: "Work Packages",
                    points: [
                        "Six disciplines - Design, Structure, Engineering, Construction, IHS & IAA, IES & IEL.",
                        "Each unlocks once overall project progress passes its start threshold.",
                        "Cost accrues over time at its current rate; the bar fills as units complete."
                    ]
                )

                legendSection(
                    title: "Boosters",
                    points: [
                        "Six knowledge areas - Planning, Procurement, Risk, Communications, Training, Quality.",
                        "Hiring (+) costs money now but nudges other systems the way its \"affects\" line describes.",
                        "Selling (-) refunds and reverses that nudge."
                    ]
                )

                legendSection(
                    title: "Risk & Quality Gauges",
                    points: [
                        "Move as boosters are bought and sold - green is healthy, red needs attention."
                    ]
                )

                legendSection(
                    title: "Controls",
                    points: [
                        "Pause / Play / Fast-Forward control the simulation clock.",
                        "The run ends automatically at 100% progress and takes you to the results screen."
                    ]
                )

                Button("Close", action: onExit)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    private func legendSection(title: String, points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ForEach(points, id: \.self) { point in
                Label(point, systemImage: "circle.fill")
                    .labelStyle(BulletLabelStyle())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 8) {
            configuration.icon.font(.system(size: 4)).padding(.top, 6)
            configuration.title
        }
    }
}

//
//  HelpView.swift
//  CMSimulator
//
//  A short legend explaining the two card types, replacing the
//  original's dense hand-positioned legend screen. Two columns on
//  iPad-width screens since there's room; one stacked column on iPhone.
//

import SwiftUI

private struct Section: Identifiable {
    let title: String
    let points: [String]
    var id: String { title }
}

struct HelpView: View {
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isWide: Bool { horizontalSizeClass == .regular }

    private let sections: [Section] = [
        Section(title: "Work Packages", points: [
            "Six disciplines - Design, Structure, Engineering, Construction, IHS & IAA, IES & IEL.",
            "Each unlocks once overall project progress passes its start threshold.",
            "Hire (+) people onto a discipline to start it moving - nothing progresses, and nothing costs money, until someone is hired.",
            "Cost accrues over time at its current rate; the bar fills as units complete.",
            "Hiring quickly costs a little risk and quality; firing (-) recovers some of it back."
        ]),
        Section(title: "Boosters", points: [
            "Six knowledge areas - Planning, Procurement, Risk, Communications, Training, Quality.",
            "Hiring (+) costs money now but nudges other systems the way its \"affects\" line describes.",
            "Selling (-) refunds and reverses that nudge."
        ]),
        Section(title: "Risk & Quality Gauges", points: [
            "Move as boosters are bought and sold - green is healthy, red needs attention."
        ]),
        Section(title: "Controls", points: [
            "Pause / Play / Fast-Forward control the simulation clock.",
            "The run ends automatically at 100% progress and takes you to the results screen."
        ]),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isWide ? 32 : 20) {
                Text("How to Play").font(isWide ? .system(size: 40, weight: .bold) : .title.bold())

                if isWide {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 32), GridItem(.flexible())], alignment: .leading, spacing: 28) {
                        ForEach(sections) { legendSection($0) }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sections) { legendSection($0) }
                    }
                }

                Button("Close", action: onExit)
                    .buttonStyle(.borderedProminent)
                    .controlSize(isWide ? .large : .regular)
                    .frame(maxWidth: .infinity)
            }
            .padding(isWide ? 32 : 16)
            .frame(maxWidth: isWide ? 900 : .infinity)
            .frame(maxWidth: .infinity)
        }
    }

    private func legendSection(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title).font(isWide ? .title3.bold() : .headline)
            ForEach(section.points, id: \.self) { point in
                Label(point, systemImage: "circle.fill")
                    .labelStyle(BulletLabelStyle())
                    .font(isWide ? .body : .subheadline)
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

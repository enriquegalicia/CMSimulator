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
        Section(title: String(localized: "Work Packages", comment: "Help screen section title"), points: [
            String(localized: "Six disciplines - Design, Structure, Engineering, Construction, IHS & IAA, IES & IEL.", comment: "Help screen bullet"),
            String(localized: "Each unlocks once overall project progress passes its start threshold.", comment: "Help screen bullet"),
            String(localized: "Hire (+) people onto a discipline to start it moving - nothing progresses, and nothing costs money, until someone is hired.", comment: "Help screen bullet"),
            String(localized: "Hiring opens a choice of three named candidates, each with a real tradeoff (cost, speed, risk, quality) - the highlighted number on each row is the best of the three on that axis.", comment: "Help screen bullet"),
            String(localized: "Cost accrues over time at its current rate; the bar fills as units complete.", comment: "Help screen bullet"),
            String(localized: "Firing (-) removes one hire and recovers some risk and quality back.", comment: "Help screen bullet"),
        ]),
        Section(title: String(localized: "Boosters", comment: "Help screen section title"), points: [
            String(localized: "Six knowledge areas - Planning, Procurement, Risk, Communications, Training, Quality.", comment: "Help screen bullet"),
            String(localized: "Buying (+) costs money now but nudges other systems the way its \"affects\" line describes; selling (-) refunds and reverses it.", comment: "Help screen bullet"),
            String(localized: "Procurement is different: buying it opens a choice between three vendor bids - lowest bid saves money now, premium/reliable costs more but improves quality and future booster pricing.", comment: "Help screen bullet"),
        ]),
        Section(title: String(localized: "Risk & Quality Gauges", comment: "Help screen section title"), points: [
            String(localized: "Move as boosters are bought and sold - green is healthy, red needs attention.", comment: "Help screen bullet"),
        ]),
        Section(title: String(localized: "Controls", comment: "Help screen section title"), points: [
            String(localized: "Pause / Play / Fast-Forward control the simulation clock.", comment: "Help screen bullet"),
            String(localized: "The run ends automatically at 100% progress and takes you to the results screen.", comment: "Help screen bullet"),
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

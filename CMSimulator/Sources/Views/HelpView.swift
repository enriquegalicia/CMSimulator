//
//  HelpView.swift
//  CMSimulator
//
//  The briefing. Rewritten for the rebuilt game - the old text described
//  boosters that "nudge other systems", which is exactly the vagueness
//  the rebuild set out to remove.
//

import SwiftUI

private struct HelpSection: Identifiable {
    let title: String
    let icon: String
    let points: [String]
    var id: String { title }
}

struct HelpView: View {
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isWide: Bool { horizontalSizeClass == .regular }

    private let sections: [HelpSection] = [
        HelpSection(title: String(localized: "The contract", comment: "Help section title"), icon: "signature", points: [
            String(localized: "You are paid a fixed sum to deliver a building by a fixed date. Everything you spend comes out of that.", comment: "Help bullet"),
            String(localized: "The client pays in lumps as you hit milestones, and always behind the work — so you finance the next stretch yourself.", comment: "Help bullet"),
            String(localized: "Part of every payment is held back until handover, and released only if the work is sound.", comment: "Help bullet"),
            String(localized: "Miss payroll two days running and the run ends in insolvency. That is the only way to truly lose.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Crew", comment: "Help section title"), icon: "person.2.fill", points: [
            String(localized: "Hiring costs a signing fee today and a wage every day after — paid whether or not there is work for them to do.", comment: "Help bullet"),
            String(localized: "New hires start at a quarter speed and slow down everyone already on that crew while they learn. Adding people to a late package makes it later.", comment: "Help bullet"),
            String(localized: "Workers get faster the longer they stay on one package. A seasoned worker produces well over twice what they did on day one.", comment: "Help bullet"),
            String(localized: "Every package has an ideal crew size. Past it the site gets crowded, output per head drops, and incidents get likelier.", comment: "Help bullet"),
            String(localized: "Firing costs severance, destroys everything that worker learned, dents morale across the whole site, and makes your next applicants worse.", comment: "Help bullet"),
            String(localized: "Overtime buys speed and burns morale. People with no morale left resign on their own.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Materials", comment: "Help section title"), icon: "shippingbox.fill", points: [
            String(localized: "Work stops dead when a package runs out of materials — and the crew keeps drawing full pay while it waits.", comment: "Help bullet"),
            String(localized: "Orders take days to arrive. Watch the days of cover on each card and order before it runs out.", comment: "Help bullet"),
            String(localized: "The cheapest supplier is slow and unreliable. On a package that is about to run dry, that costs far more in idle wages than it saves.", comment: "Help bullet"),
            String(localized: "Prices move every day. Acquisitions level 2 lets you lock the index for a month.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "The six levers", comment: "Help section title"), icon: "slider.horizontal.3", points: [
            String(localized: "Planning buys information: a completion forecast and advance warning of incidents. At higher levels it lets you start a package early.", comment: "Help bullet"),
            String(localized: "Acquisitions takes a position: shorter lead times, bulk discounts, and price hedging.", comment: "Help bullet"),
            String(localized: "Quality retires a debt: every unit built hides defects, and inspecting them out now costs a fraction of what they cost at handover.", comment: "Help bullet"),
            String(localized: "Risk allocates cover: mitigations against specific kinds of incident, plus insurance on the rest.", comment: "Help bullet"),
            String(localized: "Communications controls the cash clock: client trust decides how fast you get paid and whether they will grant more time.", comment: "Help bullet"),
            String(localized: "Training trades now for later: workers earn nothing while on a course and come back permanently better. Only worth it early.", comment: "Help bullet"),
            String(localized: "Every level charges upkeep every day. A lever you cannot afford to run is one you should not have staffed.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Scoring", comment: "Help section title"), icon: "trophy.fill", points: [
            String(localized: "You are ranked on profit: what the client paid, minus everything the job cost you.", comment: "Help bullet"),
            String(localized: "Finishing late costs a penalty every day. Finishing early earns a bonus.", comment: "Help bullet"),
            String(localized: "Defects that reach handover are charged at over four times the cost of catching them during the build, and the client withholds against them.", comment: "Help bullet"),
        ]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: isWide ? 26 : 20) {
                    if isWide {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 28), GridItem(.flexible())],
                                  alignment: .leading, spacing: 24) {
                            ForEach(sections) { section($0) }
                        }
                    } else {
                        ForEach(sections) { section($0) }
                    }
                }
                .padding(isWide ? 28 : 16)
                .frame(maxWidth: isWide ? 900 : .infinity)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(String(localized: "How to play", comment: "Help screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onExit)
                }
            }
        }
    }

    private func section(_ section: HelpSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(section.title, systemImage: section.icon)
                .font(isWide ? .title3.bold() : .headline)
            ForEach(section.points, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 4, height: 4)
                        .padding(.top, 7)
                    Text(point)
                        .font(isWide ? .body : .subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

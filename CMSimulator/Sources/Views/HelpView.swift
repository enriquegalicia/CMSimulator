//
//  HelpView.swift
//  CMSimulator
//
//  The briefing. Rewritten for the rebuilt game - the old text described
//  boosters that "nudge other systems", which is exactly the vagueness
//  the rebuild set out to remove.
//
//  One briefing per scenario. Each is its own ecosystem, so a startup
//  player reading about building contracts is the same bug as a startup
//  board showing "Materials".
//

import SwiftUI

private struct HelpSection: Identifiable {
    let title: String
    let icon: String
    let points: [String]
    var id: String { title }
}

struct HelpView: View {
    let scenario: ScenarioKind
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isWide: Bool { horizontalSizeClass == .regular }

    private var sections: [HelpSection] {
        switch scenario {
        case .construction: return Self.constructionSections
        case .startup: return Self.startupSections + [leverSection, Self.startupScoring]
        case .importing: return Self.importSections + [leverSection, Self.importScoring]
        }
    }

    /// The levers are the same six systems everywhere, renamed and
    /// re-flavoured per scenario - so their briefing comes from the same
    /// place the board's lever cards do.
    private var leverSection: HelpSection {
        HelpSection(
            title: String(localized: "The six levers", comment: "Help section title"),
            icon: "slider.horizontal.3",
            points: CapabilityKind.allCases.map {
                "\($0.displayName(in: scenario)): \($0.summary(in: scenario))"
            } + [
                String(localized: "Every level charges upkeep every day. A lever you cannot afford to run is one you should not have staffed.", comment: "Help bullet"),
            ]
        )
    }

    private static let constructionSections: [HelpSection] = [
        HelpSection(title: String(localized: "The contract", comment: "Help section title"), icon: "signature", points: [
            String(localized: "You are paid a fixed sum to deliver a building by a fixed date. Everything you spend comes out of that.", comment: "Help bullet"),
            String(localized: "The client pays in lumps as you hit milestones, and always behind the work — so you finance the next stretch yourself.", comment: "Help bullet"),
            String(localized: "Part of every payment is held back until handover, and released only if the work is sound.", comment: "Help bullet"),
            String(localized: "Fall four days behind on payroll and the run ends in insolvency. That is the only way to truly lose.", comment: "Help bullet"),
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

    private static let startupSections: [HelpSection] = [
        HelpSection(title: String(localized: "The company", comment: "Help section title"), icon: "laptopcomputer", points: [
            String(localized: "You found it with your own capital, and you set the terms: how much you put in, and how long before interest starts.", comment: "Help bullet"),
            String(localized: "You start not knowing exactly what you are building. Discovery finds out — and only then do you learn which of your hires were the right ones.", comment: "Help bullet"),
            String(localized: "Nobody can buy a product that is not launched. Launch is the most important gate in the run, and every day before it is growth you never get back.", comment: "Help bullet"),
            String(localized: "Fall four days behind on payroll and the company is insolvent. That is the only way to truly lose.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Team", comment: "Help section title"), icon: "person.2.fill", points: [
            String(localized: "Every hire costs a signing fee today and a salary every day after, whether or not there is work for them.", comment: "Help bullet"),
            String(localized: "People in the roles this venture actually needs compound. Specialists it does not need are expensive generalists.", comment: "Help bullet"),
            String(localized: "When a workstream finishes, its people stay on the payroll. A company keeps its team; a project sends people home.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Customers", comment: "Help section title"), icon: "chart.line.uptrend.xyaxis", points: [
            String(localized: "Once you launch, a few customers find you on their own, and word of mouth compounds off the ones you already have.", comment: "Help bullet"),
            String(localized: "Paid acquisition speeds that up, but each new customer costs more as the obvious ones are used up.", comment: "Help bullet"),
            String(localized: "A thin product charges less and spreads slower. Tech debt makes customers leave long before any buyer sees it.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Funding", comment: "Help section title"), icon: "banknote.fill", points: [
            String(localized: "Investors add cash, never revenue. Every round you take dilutes what you own at the exit.", comment: "Help bullet"),
            String(localized: "Finding investors is a search that costs time you could spend building, and offers go cold.", comment: "Help bullet"),
        ]),
    ]

    private static let startupScoring = HelpSection(title: String(localized: "Scoring", comment: "Help section title"), icon: "trophy.fill", points: [
        String(localized: "The run ends in a sale. A buyer prices your revenue by how fast you are growing, takes off what diligence finds in tech debt, and pays you for the share you still own.", comment: "Help bullet"),
        String(localized: "You are ranked on profit. A company that never launched scores nothing, however tidy the books look.", comment: "Help bullet"),
        String(localized: "Harder difficulty and leaner founding terms score higher on the leaderboard.", comment: "Help bullet"),
    ])

    private static let importSections: [HelpSection] = [
        HelpSection(title: String(localized: "The operation", comment: "Help section title"), icon: "shippingbox.fill", points: [
            String(localized: "You fund it yourself. The binding limit is cash: it sits in deposits, in goods at sea, in stock in the warehouse and in payouts not yet released.", comment: "Help bullet"),
            String(localized: "You can sell every unit at a profit and still miss payroll. Fall four days behind and the operation is insolvent.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Sourcing", comment: "Help section title"), icon: "globe", points: [
            String(localized: "Where you buy is the decision the run turns on. A factory abroad is cheap but slow, sells in large minimum lots, and is exposed to duty, the exchange rate and tariff changes.", comment: "Help bullet"),
            String(localized: "A domestic distributor costs more per unit and arrives quickly. Buying blind from a reseller is cheap until the returns come back.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Sales", comment: "Help section title"), icon: "cart.fill", points: [
            String(localized: "The marketplace takes a cut of every sale plus a fee to pick and ship it, and pays you about two weeks later.", comment: "Help bullet"),
            String(localized: "List price trades margin against volume. Advertising buys visibility, and past a point it costs more than it sells.", comment: "Help bullet"),
            String(localized: "Returns cost the refund and the shipping again, and drag your rating down. A poor rating throttles every future sale.", comment: "Help bullet"),
            String(localized: "Demand follows a season. Demand planning tells you when it peaks; without it you are buying stock on a guess.", comment: "Help bullet"),
        ]),
        HelpSection(title: String(localized: "Stock", comment: "Help section title"), icon: "archivebox.fill", points: [
            String(localized: "Storage is charged on every unit every day, and multiplies once stock gets old.", comment: "Help bullet"),
            String(localized: "Whatever is left when the season closes is sold off for a fraction of what it cost.", comment: "Help bullet"),
        ]),
    ]

    private static let importScoring = HelpSection(title: String(localized: "Scoring", comment: "Help section title"), icon: "trophy.fill", points: [
        String(localized: "You are ranked on profit: everything you sold, minus goods, freight, duty, fees, storage, returns, advertising and wages.", comment: "Help bullet"),
        String(localized: "Harder difficulty and leaner founding terms score higher on the leaderboard.", comment: "Help bullet"),
    ])

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

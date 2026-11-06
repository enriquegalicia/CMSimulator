//
//  ScenarioPickerView.swift
//  CMSimulator
//
//  Choosing what to run. Every scenario is scored on the same metric -
//  profit - so the choice is about which set of decisions you want to
//  practise: a contract paid by milestone, a company paid by customers, or
//  a trade paid when the stock sells.
//
//  Build 3 (2026-10-15): this was a stock grouped form, the first screen a
//  new player (and App Review) saw. It is now the game's title screen, on
//  the same drafting-paper slate as the board, with the three businesses
//  as cards over the game's own art.
//

import SwiftUI

struct ScenarioPickerView: View {
    /// Nil when this is the first run of a session; otherwise the run
    /// being replaced, so the sheet can warn before discarding it.
    let current: ProjectBrief?
    let onStart: (ScenarioKind, Difficulty, VentureSetup) -> Void
    let onCancel: () -> Void

    @State private var scenario: ScenarioKind
    @State private var difficulty: Difficulty
    /// Nil until the player moves the slider, which keeps "I did not
    /// choose" distinct from "I chose the default".
    @State private var openingCapital: Double?
    @State private var graceDays: Double = 0

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    init(current: ProjectBrief?,
         onStart: @escaping (ScenarioKind, Difficulty, VentureSetup) -> Void,
         onCancel: @escaping () -> Void) {
        self.current = current
        self.onStart = onStart
        self.onCancel = onCancel
        _scenario = State(initialValue: current?.scenario ?? .construction)
        _difficulty = State(initialValue: current?.difficulty ?? .standard)
    }

    /// You found this business, so you set its terms. A contractor did not.
    private var isFounded: Bool { scenario != .construction }

    /// What the scenario starts you with before you touch anything.
    private var defaultCapital: Double {
        ProjectBrief.make(scenario: scenario, difficulty: difficulty, seed: 1).startingCash
    }
    private var chosenCapital: Double { openingCapital ?? defaultCapital }

    private var setup: VentureSetup {
        isFounded ? VentureSetup(openingCapital: openingCapital, graceDays: graceDays) : .default
    }

    private var money: MarketCurrencyFormatStyle {
        .marketCurrency(currencyCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero

                    sectionTitle(String(localized: "Scenario", comment: "Scenario picker section header"))
                    VStack(spacing: 10) {
                        ForEach(ScenarioKind.allCases) { kind in
                            scenarioCard(kind)
                        }
                    }
                    Text("Each business has its own work, its own way of making money, its own things that go wrong, and its own leaderboard.", comment: "Scenario picker explanation")
                        .font(.caption)
                        .foregroundStyle(CP.inkSoft)

                    sectionTitle(String(localized: "Difficulty", comment: "Scenario picker section header"))
                    difficultyPicker

                    if isFounded {
                        ventureSetup
                    } else {
                        Label(String(localized: "The terms come with the contract: the client sets the advance, the deadline and the penalties.", comment: "Why construction has no venture setup"),
                              systemImage: "doc.text.fill")
                            .font(.caption)
                            .foregroundStyle(CP.inkSoft)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cpPanel()
                    }

                    Button {
                        onStart(scenario, difficulty, setup)
                    } label: {
                        Text("Start", comment: "Begin a new run")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .cpProminent()
                    .controlSize(.large)
                    .accessibilityIdentifier("startRun")

                    if current != nil {
                        Text("This ends the run in progress.", comment: "Warning when replacing an active run")
                            .font(.caption)
                            .foregroundStyle(CP.amber)
                    }
                }
                .padding(16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(BlueprintBackground())
            .navigationTitle(String(localized: "New run", comment: "Scenario picker title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    // MARK: Title

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            // The art fills a fixed-height frame the width of the column,
            // never the other way round: a fill-scaled image left to size
            // itself pushed the whole screen wider than the phone.
            Color.clear
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image("TitleArt")
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityHidden(true)
            LinearGradient(colors: [.clear, CP.night.opacity(0.92)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "CRITICAL PATH")
                    .font(.system(size: 13, weight: .heavy).width(.expanded))
                    .foregroundStyle(CP.lime)
                    .tracking(1.5)
                Text("Pick a business to run", comment: "Title screen headline")
                    .font(.title2.weight(.bold).width(.condensed))
                    .foregroundStyle(CP.ink)
                Text("Three businesses, three economies. One score: profit.", comment: "Title screen subtitle")
                    .font(.subheadline)
                    .foregroundStyle(CP.inkSoft)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(CP.rule, lineWidth: 0.75))
        .accessibilityElement(children: .combine)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold).width(.expanded))
            .tracking(1)
            .foregroundStyle(CP.inkFaint)
            .padding(.top, 4)
    }

    // MARK: Scenarios

    /// How money reaches you in each business - the one line that says
    /// these are three different economies, not one game reskinned.
    private func moneyLine(_ kind: ScenarioKind) -> String {
        switch kind {
        case .construction:
            return String(localized: "Paid by milestone, days behind the work, with a retention held back", comment: "Title screen: how money arrives, construction")
        case .startup:
            return String(localized: "Paid by customers; every funding round costs you equity", comment: "Title screen: how money arrives, startup")
        case .importing:
            return String(localized: "Paid by sales, when the marketplace releases the payout", comment: "Title screen: how money arrives, import")
        }
    }

    private func scenarioCard(_ kind: ScenarioKind) -> some View {
        let selected = scenario == kind
        return Button {
            scenario = kind
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: kind.symbolName)
                    .font(.title3)
                    .foregroundStyle(selected ? CP.onLime : CP.inkSoft)
                    .frame(width: 40, height: 40)
                    .background(selected ? CP.lime : CP.panelHigh, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.name)
                        .font(.headline)
                        .foregroundStyle(CP.ink)
                    Text(kind.tagline)
                        .font(.caption)
                        .foregroundStyle(CP.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(moneyLine(kind), systemImage: "banknote")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CP.amber)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(kind.signature, systemImage: "lightbulb")
                        .font(.caption2)
                        .foregroundStyle(selected ? CP.lime : CP.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? CP.lime : CP.inkFaint)
            }
            .padding(12)
            .cpPanel()
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? CP.lime : .clear, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("scenario.\(kind.rawValue)")
    }

    // MARK: Difficulty

    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Difficulty.allCases) { level in
                    let selected = difficulty == level
                    Button {
                        difficulty = level
                    } label: {
                        Text(level.name)
                            .font(.subheadline.weight(selected ? .bold : .medium))
                            .foregroundStyle(selected ? CP.onLime : CP.ink)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(selected ? CP.lime : CP.panelHigh, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            Text(difficulty.blurb)
                .font(.caption)
                .foregroundStyle(CP.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("Harder settings score higher on the leaderboard.", comment: "Difficulty explanation")
                .font(.caption2)
                .foregroundStyle(CP.inkFaint)
        }
    }

    // MARK: Venture setup

    private var ventureSetup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Setting up", comment: "Venture setup section header")
                .font(.subheadline.bold())
                .foregroundStyle(CP.ink)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Opening capital", comment: "Venture setup control")
                        .font(.subheadline)
                    Spacer()
                    Text(chosenCapital, format: money)
                        .font(.headline.monospacedDigit())
                }
                Slider(value: Binding(get: { chosenCapital },
                                      set: { openingCapital = ($0 / 50_000).rounded() * 50_000 }),
                       in: max(100_000, defaultCapital * 0.3)...(defaultCapital * 2.0),
                       step: 50_000)
                Text(String(localized: "What you put in yourself. Start lean and every point scores higher.", comment: "Opening capital explanation"))
                    .font(.caption2).foregroundStyle(CP.inkSoft)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Grace period", comment: "Venture setup control")
                        .font(.subheadline)
                    Spacer()
                    Text(String(localized: "\(Int(graceDays)) days", comment: "Grace period in days"))
                        .font(.headline.monospacedDigit())
                }
                Slider(value: $graceDays, in: 0...90, step: 5)
                Text(String(localized: "Days before interest and late penalties start. Buys you room to set up, and costs you at scoring.", comment: "Grace period explanation"))
                    .font(.caption2).foregroundStyle(CP.inkSoft)
            }

            Text(String(localized: "Your terms are worth \(setup.scoreFactor(against: defaultCapital), format: .number.precision(.fractionLength(2)))× on the leaderboard.", comment: "Venture score factor"))
                .font(.caption)
                .foregroundStyle(setup.scoreFactor(against: defaultCapital) >= 1 ? CP.lime : CP.amber)
        }
        .foregroundStyle(CP.ink)
        .padding(12)
        .cpPanel()
    }
}

//
//  ScenarioPickerView.swift
//  CMSimulator
//
//  Choosing what to run. Every scenario plays on the same engine and is
//  scored on the same metric - profit - so the choice is about which set
//  of decisions you want to practise, not which game you want to play.
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

    private var money: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode).precision(.fractionLength(0))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ScenarioKind.allCases) { kind in
                        scenarioRow(kind)
                    }
                } header: {
                    Text("Scenario", comment: "Scenario picker section header")
                } footer: {
                    Text("Both run on the same simulation, but they are not the same game. Each has its own work, its own way of making money, its own things that go wrong — and its own leaderboard.", comment: "Scenario picker explanation")
                }

                Section {
                    ForEach(Difficulty.allCases) { level in
                        difficultyRow(level)
                    }
                } header: {
                    Text("Difficulty", comment: "Scenario picker section header")
                } footer: {
                    Text("Harder settings score higher on the leaderboard.", comment: "Difficulty explanation")
                }

                if isFounded {
                    Section {
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
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)

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
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("Setting up", comment: "Venture setup section header")
                    } footer: {
                        Text(String(localized: "Your terms are worth \(setup.scoreFactor(against: defaultCapital), format: .number.precision(.fractionLength(2)))× on the leaderboard.", comment: "Venture score factor"))
                            .font(.caption)
                            .foregroundStyle(setup.scoreFactor(against: defaultCapital) >= 1 ? .green : .orange)
                    }
                } else {
                    Section {
                        Label(String(localized: "The terms come with the contract: the client sets the advance, the deadline and the penalties.", comment: "Why construction has no venture setup"),
                              systemImage: "doc.text.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Setting up", comment: "Venture setup section header")
                    } footer: {
                        Text("Founding your own practice — choosing your capital and your runway — is the design firm scenario, which is not built yet.", comment: "Design firm teaser")
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        onStart(scenario, difficulty, setup)
                    } label: {
                        Text("Start", comment: "Begin a new run")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    if current != nil {
                        Text("This ends the run in progress.", comment: "Warning when replacing an active run")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(String(localized: "New run", comment: "Scenario picker title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func scenarioRow(_ kind: ScenarioKind) -> some View {
        Button {
            scenario = kind
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: kind.symbolName)
                    .font(.title2)
                    .foregroundStyle(scenario == kind ? Color.accentColor : .secondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.name).font(.headline)
                    Text(kind.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(kind.signature, systemImage: "lightbulb")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                Spacer(minLength: 4)

                if scenario == kind {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func difficultyRow(_ level: Difficulty) -> some View {
        Button {
            difficulty = level
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.name).font(.subheadline.bold())
                    Text(level.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if difficulty == level {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

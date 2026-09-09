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
    let onStart: (ScenarioKind, Difficulty) -> Void
    let onCancel: () -> Void

    @State private var scenario: ScenarioKind
    @State private var difficulty: Difficulty

    init(current: ProjectBrief?,
         onStart: @escaping (ScenarioKind, Difficulty) -> Void,
         onCancel: @escaping () -> Void) {
        self.current = current
        self.onStart = onStart
        self.onCancel = onCancel
        _scenario = State(initialValue: current?.scenario ?? .construction)
        _difficulty = State(initialValue: current?.difficulty ?? .standard)
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
                    Text("Both run on the same simulation and are ranked on the same thing: profit. What changes is the work, what it consumes, and what can go wrong.", comment: "Scenario picker explanation")
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

                Section {
                    Button {
                        onStart(scenario, difficulty)
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

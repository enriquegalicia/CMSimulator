//
//  CrewView.swift
//  CMSimulator
//
//  The roster. There was nothing like this before - hiring was an integer
//  on a card, so the player never met the people whose experience they
//  were destroying when they fired someone. Showing experience and morale
//  per person is what makes severance feel like a loss rather than a
//  line item.
//

import SwiftUI

struct CrewView: View {
    let scenario: ScenarioKind
    let workers: [Worker]
    let packageTitles: [String: String]
    let trainingLevel: Int
    let courseDays: Double
    let courseCost: Double
    let spendingPower: Double
    let onFire: (Worker.ID) -> Void
    let onTrain: (Worker.ID) -> Void
    /// Streams a person can be moved onto right now. Empty in scenarios
    /// where finishing a stream sends people home instead.
    let reassignableTo: [(id: String, title: String)]
    let onReassign: (Worker.ID, String) -> Void
    let onRaise: (Worker.ID) -> Void
    let onExit: () -> Void

    @State private var showByPerformance = false

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
    @State private var confirmingFire: Worker?

    private var grouped: [(title: String, workers: [Worker])] {
        Dictionary(grouping: workers, by: \.packageID)
            .map { (title: $0.key == Worker.benchPackageID
                        ? String(localized: "Unassigned", comment: "Roster group for benched staff")
                        : packageTitles[$0.key] ?? $0.key,
                    workers: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.title < $1.title }
    }

    /// Everyone, best value first. Ranked on what they have actually been
    /// producing per peso, not on the skill they were hired at.
    private var byPerformance: [Worker] {
        workers.sorted { $0.valueForMoney > $1.valueForMoney }
    }

    private var bench: [Worker] { workers.filter(\.isOnBench) }
    private var benchCost: Double { bench.reduce(0) { $0 + $1.dailyWage } }

    var body: some View {
        NavigationStack {
            Group {
                if workers.isEmpty {
                    ContentUnavailableView(
                        String(localized: "Nobody hired yet", comment: "Empty crew state title"),
                        systemImage: "person.slash",
                        description: Text("Hire onto a work package to get started.", comment: "Empty crew state description")
                    )
                } else {
                    List {
                        Section {
                            payrollSummary
                        }

                        if !bench.isEmpty {
                            Section {
                                Label(String(localized: "\(bench.count) people with nothing to work on, costing \(benchCost, format: .currency(code: currencyCode).precision(.fractionLength(0))) a day.", comment: "Bench warning"),
                                      systemImage: "person.badge.clock")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                            } footer: {
                                Text("Move them onto open work or let them go. Doing neither is the most expensive option.", comment: "Bench explanation")
                                    .font(.caption)
                            }
                        }

                        Section {
                            Picker(String(localized: "Sort", comment: "Roster sort control"), selection: $showByPerformance) {
                                Text("By stream", comment: "Roster grouping").tag(false)
                                Text("By performance", comment: "Roster grouping").tag(true)
                            }
                            .pickerStyle(.segmented)
                        }

                        if showByPerformance {
                            Section {
                                ForEach(byPerformance) { worker in
                                    workerRow(worker)
                                }
                            } header: {
                                Text("Best value first", comment: "Performance list header")
                            } footer: {
                                Text("Output per day against what they cost per day. An apprentice at 260 a day can outrank a specialist at 940.", comment: "Performance explanation")
                                    .font(.caption)
                            }
                        } else {
                            ForEach(grouped, id: \.title) { group in
                                Section(group.title) {
                                    ForEach(group.workers) { worker in
                                        workerRow(worker)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(scenario.staffName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onExit)
                }
            }
            .confirmationDialog(
                confirmingFire.map { String(localized: "Let \($0.name) go?", comment: "Fire confirmation title") } ?? "",
                isPresented: Binding(get: { confirmingFire != nil }, set: { if !$0 { confirmingFire = nil } }),
                titleVisibility: .visible
            ) {
                if let worker = confirmingFire {
                    Button(String(localized: "Pay \(worker.severanceCost, format: .currency(code: currencyCode).precision(.fractionLength(0))) severance", comment: "Fire confirmation action"), role: .destructive) {
                        onFire(worker.id)
                        confirmingFire = nil
                    }
                }
                Button("Cancel", role: .cancel) { confirmingFire = nil }
            } message: {
                Text("Their experience is lost for good, morale drops across everyone else, and your next applicants will be worse.", comment: "Fire confirmation message")
            }
        }
    }

    private var payrollSummary: some View {
        let daily = workers.reduce(0) { $0 + $1.dailyWage }
        let veterans = workers.filter { $0.experience > 0.6 }.count
        let green = workers.filter(\.isOnboarding).count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Daily payroll", comment: "Crew summary label")
                    .font(.subheadline)
                Spacer()
                Text(daily, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit())
            }
            HStack(spacing: 14) {
                Label("\(workers.count)", systemImage: "person.2.fill")
                if veterans > 0 {
                    Label("\(veterans)", systemImage: "star.fill").foregroundStyle(.yellow)
                }
                if green > 0 {
                    Label("\(green)", systemImage: "hourglass").foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func workerRow(_ worker: Worker) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(worker.name).font(.subheadline.bold())
                if worker.coursesCompleted > 0 {
                    Image(systemName: "graduationcap.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
                Spacer()
                Text(worker.dailyWage, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                if worker.role != .generalist {
                    Text(worker.role.name)
                        .font(.caption2.bold())
                }
                Text(worker.archetype.traitName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(verbatim: "·").font(.caption2).foregroundStyle(.secondary)
                Text(String(localized: "\(worker.education.name(in: scenario)), \(worker.yearsOfExperience) yrs", comment: "Roster education and years"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if worker.isOnBench {
                    Text("Unassigned", comment: "Worker status: on the bench")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                } else if showByPerformance, let title = packageTitles[worker.packageID] {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if worker.reassignments > 0 {
                    Label("\(worker.reassignments)", systemImage: "arrow.triangle.swap")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 4) {
                Text("Delivering", comment: "Worker performance label")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(String(format: "%.2f", worker.recentOutput))
                    .font(.caption2.monospacedDigit().bold())
                Text("units/day", comment: "Units per day suffix")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .foregroundStyle(worker.recentOutput < 0.15 ? Color.orange : Color.primary)

            if worker.isInTraining {
                Label(String(localized: "In training, \(String(format: "%.1f", worker.trainingDaysRemaining)) days left — producing nothing", comment: "Worker status: in training"),
                      systemImage: "graduationcap")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            } else if worker.isOnboarding {
                Label(String(localized: "Onboarding — at \(Int(worker.rampMultiplier * 100))% and slowing the others", comment: "Worker status: onboarding"),
                      systemImage: "hourglass")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
                miniBar(String(localized: "Experience", comment: "Worker stat"), worker.experience, .yellow)
                miniBar(String(localized: "Morale", comment: "Worker stat"), worker.morale,
                        worker.morale < WorkerTuning.unhappyMoraleThreshold ? .red : .green)
                miniBar(String(localized: "Output", comment: "Worker stat"), worker.effectiveOutput / 2.5, .blue)
            }

            if worker.morale < WorkerTuning.unhappyMoraleThreshold {
                Label(String(localized: "At risk of quitting", comment: "Worker status: may quit"),
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
            }

            HStack(spacing: 8) {
                if trainingLevel > 0 {
                    Button {
                        onTrain(worker.id)
                    } label: {
                        Label(String(localized: "Train (\(Int(courseDays))d)", comment: "Train worker button"), systemImage: "graduationcap")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .disabled(worker.isInTraining || courseCost > spendingPower)
                }
                Button {
                    onRaise(worker.id)
                } label: {
                    Label(String(localized: "Raise", comment: "Give a pay rise button"), systemImage: "arrow.up.forward")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)

                if !reassignableTo.isEmpty {
                    Menu {
                        ForEach(reassignableTo, id: \.id) { target in
                            Button(target.title) { onReassign(worker.id, target.id) }
                                .disabled(target.id == worker.packageID)
                        }
                    } label: {
                        Label(String(localized: "Move", comment: "Reassign worker button"), systemImage: "arrow.triangle.swap")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .disabled(worker.isInTraining)
                }
                Spacer()
                Button(role: .destructive) {
                    confirmingFire = worker
                } label: {
                    Label(String(localized: "Let go", comment: "Fire worker button"), systemImage: "person.badge.minus")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.mini)
        }
        .padding(.vertical, 3)
    }

    private func miniBar(_ label: String, _ value: Double, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(tint)
                        .frame(width: max(2, geo.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

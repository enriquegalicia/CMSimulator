//
//  GameView.swift
//  CMSimulator
//
//  The main board.
//
//  The header is the important change. The rebuild added a real economy,
//  and depth the player cannot see reads as clutter rather than tension -
//  so cash, runway, the deadline and progress are now a permanent top
//  line, with morale, client trust and the materials index right under
//  them. Everything else moved behind three tabs so the board stays
//  legible on a phone.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var engine: SimulationEngine
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    let onShowHelp: () -> Void
    let onShowScores: () -> Void
    let onShowSettings: () -> Void
    let onGameCenter: () -> Void
    let onComplete: () -> Void

    enum Board: String, CaseIterable, Identifiable {
        case site, levers, log
        var id: String { rawValue }
        var title: String {
            switch self {
            case .site: return String(localized: "Site", comment: "Board tab")
            case .levers: return String(localized: "Levers", comment: "Board tab")
            case .log: return String(localized: "Log", comment: "Board tab")
            }
        }
    }

    @State private var board: Board = .site
    @State private var showRestartConfirm = false
    @State private var showCrew = false
    @State private var showRisk = false

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, isWide ? 20 : 14).padding(.top, 10).padding(.bottom, 8)

            Picker("Board", selection: $board) {
                ForEach(Board.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, isWide ? 20 : 14)

            ScrollView {
                Group {
                    switch board {
                    case .site: siteBoard
                    case .levers: leversBoard
                    case .log: logBoard
                    }
                }
                .padding(.horizontal, isWide ? 20 : 14)
                .padding(.vertical, 12)
                .frame(maxWidth: isWide ? 1100 : .infinity)
                .frame(maxWidth: .infinity)
            }

            transportControls.padding(.horizontal, 16).padding(.vertical, 10)
        }
        .onChange(of: engine.outcome) { _, outcome in
            if outcome != nil { onComplete() }
        }
        .overlay(alignment: .top) { eventOverlay }
        .animation(.spring(duration: 0.3), value: engine.activeEvent?.id)
        .confirmationDialog(String(localized: "Restart the simulation?", comment: "Restart confirmation title"),
                            isPresented: $showRestartConfirm, titleVisibility: .visible) {
            Button(String(localized: "Restart", comment: "Restart confirmation action"), role: .destructive) { engine.restart() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This ends the current contract and draws a fresh project.", comment: "Restart confirmation message")
        }
        .sheet(item: Binding(get: { engine.hiringRequest }, set: { if $0 == nil { engine.cancelHiring() } })) { request in
            CandidatePickerView(request: request,
                                spendingPower: engine.ledger.spendingPower,
                                onSelect: { engine.confirmHire($0) },
                                onCancel: { engine.cancelHiring() })
        }
        .sheet(item: Binding(get: { engine.orderRequest }, set: { if $0 == nil { engine.cancelMaterialOrder() } })) { request in
            MaterialOrderView(request: request,
                              spendingPower: engine.ledger.spendingPower,
                              onOrder: { engine.placeOrder(vendor: $0, quantity: $1) },
                              onCancel: { engine.cancelMaterialOrder() })
        }
        .sheet(isPresented: $showCrew) {
            CrewView(workers: engine.workers,
                     packageTitles: Dictionary(uniqueKeysWithValues: engine.workPackages.map { ($0.id, $0.title) }),
                     trainingLevel: engine.level(of: .training),
                     courseDays: CapabilityEffects.courseDays(level: engine.level(of: .training)),
                     courseCost: CapabilityEffects.courseCostPerWorker,
                     spendingPower: engine.ledger.spendingPower,
                     onFire: { engine.fire(workerID: $0) },
                     onTrain: { engine.enrollInTraining($0) },
                     onExit: { showCrew = false })
        }
        .sheet(isPresented: $showRisk) {
            RiskPortfolioView(held: engine.mitigationsHeld,
                              riskLevel: engine.level(of: .risk),
                              insuranceCoverage: CapabilityEffects.insuranceCoverage(level: engine.level(of: .risk)),
                              spendingPower: engine.ledger.spendingPower,
                              exposure: engine.siteExposure,
                              forecast: engine.forecast,
                              onBuy: { engine.buyMitigation($0) },
                              onExit: { showRisk = false })
        }
    }

    // MARK: Header

    private var cashTint: Color {
        let runway = engine.runwayDays
        if engine.ledger.daysInArrears > 0 { return .red }
        if runway < 6 { return .red }
        if runway < 14 { return .orange }
        return .primary
    }

    private var deadlineTint: Color {
        let left = engine.daysRemaining
        if left < 0 { return .red }
        if left < 15 { return .orange }
        return .primary
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                StatTile(label: String(localized: "Cash", comment: "HUD label"),
                         value: engine.ledger.cash.formatted(.currency(code: currencyCode).precision(.fractionLength(0))),
                         tint: cashTint,
                         caption: engine.ledger.debt > 1
                            ? String(localized: "debt \(engine.ledger.debt, format: .currency(code: currencyCode).precision(.fractionLength(0)))", comment: "HUD debt caption")
                            : String(localized: "credit \(engine.ledger.availableCredit, format: .currency(code: currencyCode).precision(.fractionLength(0)))", comment: "HUD available credit caption"))

                StatTile(label: String(localized: "Runway", comment: "HUD label"),
                         value: engine.runwayDays.isFinite
                            ? String(localized: "\(Int(engine.runwayDays))d", comment: "HUD runway in days")
                            : "—",
                         tint: cashTint,
                         caption: String(localized: "\(engine.dailyBurn, format: .currency(code: currencyCode).precision(.fractionLength(0)))/day", comment: "HUD daily burn caption"),
                         alignment: .center)

                StatTile(label: String(localized: "Day", comment: "HUD label"),
                         value: "\(Int(engine.elapsedDays))",
                         tint: deadlineTint,
                         caption: engine.daysRemaining >= 0
                            ? String(localized: "\(Int(engine.daysRemaining)) left", comment: "HUD days remaining caption")
                            : String(localized: "\(Int(-engine.daysRemaining)) late", comment: "HUD days late caption"),
                         alignment: .center)

                StatTile(label: String(localized: "Built", comment: "HUD label"),
                         value: engine.totalProgress.formatted(.number.precision(.fractionLength(1))) + "%",
                         caption: engine.completionEstimate.map {
                            String(localized: "ETA day \(Int($0.day))", comment: "HUD completion estimate caption")
                         } ?? String(localized: "no forecast", comment: "HUD caption when Planning is not staffed"),
                         alignment: .trailing)
            }

            ProgressView(value: engine.totalProgress, total: 100)
                .tint(.accentColor)

            HStack(spacing: 14) {
                MeterView(title: String(localized: "Morale", comment: "Meter label"),
                          value: engine.averageMorale, icon: "figure.2")
                MeterView(title: String(localized: "Trust", comment: "Meter label"),
                          value: engine.clientTrust, icon: "person.crop.circle.badge.checkmark")
                MarketSparkline(history: engine.market.history,
                                current: engine.market.effectiveIndex,
                                isLocked: engine.market.isLocked)
            }

            HStack(spacing: isWide ? 22 : 14) {
                headerButton("person.2.fill", String(localized: "Crew", comment: "Header button")) { showCrew = true }
                    .badge(engine.workers.count)
                headerButton("shield.lefthalf.filled", String(localized: "Risk", comment: "Header button")) { showRisk = true }
                Spacer()
                if engine.canRequestExtension {
                    Button(action: engine.requestExtension) {
                        Label(String(localized: "Ask for time", comment: "Request deadline extension button"), systemImage: "calendar.badge.plus")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.green)
                }
                headerButton("arrow.counterclockwise", String(localized: "Restart", comment: "Header button")) { showRestartConfirm = true }
                headerButton("questionmark.circle", String(localized: "Help", comment: "Header button"), action: onShowHelp)
                headerButton("trophy", String(localized: "Scores", comment: "Header button"), action: onShowScores)
                headerButton("gearshape", String(localized: "Settings", comment: "Header button"), action: onShowSettings)
            }
            .font(isWide ? .title3 : .body)
        }
        .frame(maxWidth: isWide ? 1100 : .infinity)
    }

    private func headerButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Boards

    private var siteBoard: some View {
        VStack(spacing: 10) {
            if !engine.fastTrackablePackages.isEmpty {
                fastTrackBanner
            }
            LazyVGrid(columns: isWide ? [GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible())],
                      spacing: 10) {
                ForEach(engine.workPackages) { package in
                    WorkPackageCardView(
                        package: package,
                        crew: engine.crew(for: package.id),
                        ordersInFlight: engine.orders,
                        currentDay: engine.elapsedDays,
                        onHire: { engine.requestHire(for: package.id) },
                        onOrder: { engine.requestMaterialOrder(for: package.id) },
                        onOpenCrew: { showCrew = true },
                        onOvertime: { engine.setOvertime($0, for: package.id) }
                    )
                }
            }
        }
    }

    /// Planning's fast-track offers sit in the flow above the cards rather
    /// than floating over them, so they can never cover the first package.
    private var fastTrackBanner: some View {
        VStack(spacing: 6) {
            ForEach(engine.fastTrackablePackages) { package in
                Button {
                    engine.fastTrack(package.id)
                } label: {
                    Label(String(localized: "Fast-track \(package.title) now — expect rework", comment: "Fast-track offer"),
                          systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)
            }
        }
    }

    private var leversBoard: some View {
        VStack(spacing: 10) {
            if engine.level(of: .procurement) >= 2 && !engine.market.isLocked {
                Button(action: engine.hedgeMaterialPrice) {
                    Label(String(localized: "Lock the materials price for 30 days", comment: "Hedge button"),
                          systemImage: "lock.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.blue)
            }

            LazyVGrid(columns: isWide ? [GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible())],
                      spacing: 10) {
                ForEach(engine.capabilities) { capability in
                    CapabilityCardView(
                        capability: capability,
                        spendingPower: engine.ledger.spendingPower,
                        currentEffect: effectSummary(for: capability),
                        onUpgrade: { engine.upgrade(capability.kind) },
                        onStandDown: { engine.standDown(capability.kind) }
                    )
                }
            }
        }
    }

    /// What each capability is doing right now, in the player's terms.
    /// Without this the levers are just prices.
    private func effectSummary(for capability: Capability) -> String? {
        let level = capability.level
        guard level > 0 else { return nil }
        switch capability.kind {
        case .planning:
            return String(localized: "Seeing \(Int(CapabilityEffects.forecastHorizonDays(level: level))) days ahead", comment: "Planning effect summary")
        case .procurement:
            return String(localized: "Lead times \(Int((1 - CapabilityEffects.leadTimeMultiplier(level: level)) * 100))% shorter", comment: "Acquisitions effect summary")
        case .quality:
            let open = engine.visibleDefectDebt ?? 0
            return String(localized: "\(Int(open)) defects outstanding, fixing \(String(format: "%.1f", CapabilityEffects.inspectionRatePerDay(level: level)))/day", comment: "Quality effect summary")
        case .risk:
            return String(localized: "\(engine.mitigationsHeld.count) mitigations, \(Int(CapabilityEffects.insuranceCoverage(level: level) * 100))% insured", comment: "Risk effect summary")
        case .communications:
            return String(localized: "Paid \(Int(CapabilityEffects.paymentSpeedUpDays(level: level))) days sooner", comment: "Communications effect summary")
        case .training:
            return String(localized: "Courses run \(Int(CapabilityEffects.courseDays(level: level))) days", comment: "Training effect summary")
        }
    }

    private var logBoard: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if engine.siteLog.isEmpty {
                Text("Nothing has happened yet.", comment: "Empty site log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            ForEach(engine.siteLog) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: entry.symbol)
                        .font(.caption)
                        .frame(width: 18)
                        .foregroundStyle(tint(for: entry.tone))
                    Text(entry.text)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(localized: "d\(entry.day)", comment: "Site log day marker"))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 7)
                Divider()
            }
        }
    }

    private func tint(for tone: SiteLogEntry.Tone) -> Color {
        switch tone {
        case .neutral: return .secondary
        case .good: return .green
        case .bad: return .red
        }
    }

    // MARK: Event banner

    @ViewBuilder
    private var eventOverlay: some View {
        if let event = engine.activeEvent {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: event.kind.symbolName)
                        .font(.title2)
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.kind.title).font(.headline).foregroundStyle(.white)
                        Text(event.message).font(.caption).foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer(minLength: 4)
                    Button(action: engine.dismissEvent) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Dismiss", comment: "Dismiss incident banner"))
                }
                if event.netCost > 0 {
                    Text(String(localized: "\(event.netCost, format: .currency(code: currencyCode).precision(.fractionLength(0))) out of pocket", comment: "Incident net cost"))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                ForEach(event.consequences, id: \.self) { line in
                    Label(line, systemImage: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .padding(12)
            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, isWide ? 40 : 12)
            .frame(maxWidth: isWide ? 700 : .infinity)
            .shadow(radius: 8, y: 4)
            .padding(.top, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(1)
        }
    }

    // MARK: Transport

    private var transportControls: some View {
        HStack(spacing: isWide ? 30 : 22) {
            transportButton("pause.circle.fill", String(localized: "Pause", comment: "Transport control"),
                            isActive: engine.speed == .paused, action: engine.pause)
            transportButton("play.circle.fill", String(localized: "Play", comment: "Transport control"),
                            isActive: engine.speed == .normal, action: engine.play)
            transportButton("forward.circle.fill", String(localized: "Fast-forward", comment: "Transport control"),
                            isActive: engine.speed == .fast, action: engine.fastForward)
            transportButton("forward.end.circle.fill", String(localized: "Super fast-forward", comment: "Transport control"),
                            isActive: engine.speed == .superFast, action: engine.superFastForward)
        }
        .font(.system(size: isWide ? 46 : 38))
    }

    private func transportButton(_ symbol: String, _ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

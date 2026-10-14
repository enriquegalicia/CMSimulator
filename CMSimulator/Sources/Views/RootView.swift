//
//  RootView.swift
//  CMSimulator
//
//  Navigation coordinator. Launches straight into the board and presents
//  the debrief as a full-screen cover when the run ends - either handed
//  over or insolvent, since the rebuild added a way to actually lose.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @StateObject private var engine = SimulationEngine()
    @StateObject private var gameCenter = GameCenterManager()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var showHelp = false
    @State private var showScores = false
    @State private var showResult = false
    @State private var showSettings = false
    @State private var showScenarioPicker = false
    @State private var pendingEntry: ScoreEntry?
    @AppStorage(AppSettings.hasSeenScenarioPickerKey) private var hasSeenScenarioPicker = false
    @AppStorage(AppSettings.lastPlayerNameKey) private var lastPlayerName = ""
    @AppStorage(AppSettings.briefedScenariosKey) private var briefedScenarios = ""
    /// Set when a run starts in a scenario the player has never been
    /// briefed on; the briefing opens once the picker has finished
    /// dismissing, since two sheets cannot present at once.
    @State private var briefAfterPicker = false

    private var isPresentingOwnSheet: Bool {
        showScenarioPicker || briefAfterPicker || showHelp || showResult || showScores || showSettings
    }

    var body: some View {
        GameView(
            engine: engine,
            onShowHelp: { showHelp = true },
            onShowScores: { showScores = true },
            onShowSettings: { showSettings = true },
            onGameCenter: { gameCenter.showDashboard() },
            // One picker for the whole app, so every way of starting a run
            // gets the same first-time briefing.
            onChangeScenario: { showScenarioPicker = true },
            // Record the run the moment it ends, win or lose - waiting on
            // the debrief's "Save score" button meant a run tapped past
            // (or one that went insolvent, which never showed that button
            // at all) left no trace anywhere, local or Game Center.
            onComplete: {
                let result = engine.result
                let entry = ScoreEntry(playerName: lastPlayerName.isEmpty
                                        ? String(localized: "Player", comment: "Default score entry name")
                                        : lastPlayerName,
                                       result: result,
                                       scenarioName: engine.brief.scenarioName,
                                       log: engine.siteLog)
                modelContext.insert(entry)
                pendingEntry = entry
                gameCenter.report(result)
                showResult = true
            }
        )
        .sheet(isPresented: $showHelp) {
            HelpView(scenario: engine.brief.scenario, onExit: { showHelp = false })
        }
        .sheet(isPresented: $showScores) {
            ScoresView(onExit: { showScores = false })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onExit: { showSettings = false }, gameCenter: gameCenter)
        }
        .fullScreenCover(isPresented: $showResult) {
            ResultView(
                result: engine.result,
                onSave: { name in
                    // The run was already saved and reported the instant it
                    // ended (see onComplete above) - this just attaches the
                    // name the player typed to that same entry.
                    let finalName = name.isEmpty
                        ? String(localized: "Player", comment: "Default score entry name when the player leaves the name field blank")
                        : name
                    pendingEntry?.playerName = finalName
                    lastPlayerName = finalName
                    showResult = false
                    showScores = true
                },
                onRestart: {
                    showResult = false
                    showScenarioPicker = true
                }
            )
        }
        .sheet(isPresented: $showScenarioPicker, onDismiss: {
            if briefAfterPicker {
                briefAfterPicker = false
                showHelp = true
            }
        }) {
            ScenarioPickerView(
                current: engine.brief,
                onStart: { kind, level, setup in
                    engine.restart(with: .make(scenario: kind, difficulty: level, setup: setup))
                    var briefed = Set(briefedScenarios.split(separator: ",").map(String.init))
                    if briefed.insert(kind.rawValue).inserted {
                        briefedScenarios = briefed.sorted().joined(separator: ",")
                        briefAfterPicker = true
                    }
                    showScenarioPicker = false
                },
                onCancel: { showScenarioPicker = false }
            )
        }
        // A score queued while offline should land when the app comes
        // back, not wait for the next cold launch.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await gameCenter.flushPending() }
            }
        }
        .task {
            if let shot = StoreScreenshots.requested {
                stage(shot)
                return
            }
            gameCenter.authenticate()
            // First ever launch: show what is on offer rather than
            // dropping straight into whichever scenario is the default.
            if !hasSeenScenarioPicker {
                hasSeenScenarioPicker = true
                showScenarioPicker = true
            }
        }
        .sheet(item: Binding(
            // Held back while one of our own sheets is up. Where GameKit
            // hands us its sign-in controller rather than presenting it
            // itself, it raced the scenario picker and the briefing - two
            // sheets cannot present at once, and the loser is silently
            // never shown.
            get: { isPresentingOwnSheet ? nil : gameCenter.authViewController.map(GameCenterControllerWrapper.init) },
            set: { _ in gameCenter.authViewController = nil }
        )) { wrapper in
            GameCenterControllerHost(viewController: wrapper.viewController)
        }
        .sheet(item: Binding(
            get: { gameCenter.dashboardViewController.map(GameCenterControllerWrapper.init) },
            set: { _ in gameCenter.dashboardViewController = nil }
        )) { wrapper in
            GameCenterControllerHost(viewController: wrapper.viewController)
        }
    }
}

extension RootView {
    /// Sets up a staged App Store screenshot: a real run, played to the
    /// moment the shot needs, with first-run sheets marked as seen.
    private func stage(_ shot: StoreScreenshots.Shot) {
        hasSeenScenarioPicker = true
        briefedScenarios = ScenarioKind.allCases.map(\.rawValue).joined(separator: ",")
        lastPlayerName = String(localized: "Player", comment: "Default score entry name")
        engine.restart(with: .make(scenario: shot.scenario, difficulty: .standard, seed: StoreScreenshots.seed))
        StoreScreenshots.play(shot, on: engine)
        switch shot.opens {
        case .picker: showScenarioPicker = true
        case .help: showHelp = true
        default: break
        }
    }
}

private struct GameCenterControllerWrapper: Identifiable {
    let viewController: UIViewController
    var id: ObjectIdentifier { ObjectIdentifier(viewController) }
}

private struct GameCenterControllerHost: UIViewControllerRepresentable {
    let viewController: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

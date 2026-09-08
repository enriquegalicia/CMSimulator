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
    @Environment(\.modelContext) private var modelContext

    @State private var showHelp = false
    @State private var showScores = false
    @State private var showResult = false
    @State private var showSettings = false

    var body: some View {
        GameView(
            engine: engine,
            onShowHelp: { showHelp = true },
            onShowScores: { showScores = true },
            onShowSettings: { showSettings = true },
            onGameCenter: { gameCenter.showDashboard() },
            onComplete: { showResult = true }
        )
        .sheet(isPresented: $showHelp) {
            HelpView(onExit: { showHelp = false })
        }
        .sheet(isPresented: $showScores) {
            ScoresView(onExit: { showScores = false })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onExit: { showSettings = false })
        }
        .fullScreenCover(isPresented: $showResult) {
            ResultView(
                result: engine.result,
                onSave: { name in
                    let result = engine.result
                    let finalName = name.isEmpty
                        ? String(localized: "Player", comment: "Default score entry name when the player leaves the name field blank")
                        : name
                    modelContext.insert(ScoreEntry(playerName: finalName,
                                                   result: result,
                                                   scenarioName: engine.brief.scenarioName))
                    gameCenter.report(result)
                    showResult = false
                    showScores = true
                },
                onRestart: {
                    engine.restart()
                    showResult = false
                }
            )
        }
        .task { gameCenter.authenticate() }
        .sheet(item: Binding(
            get: { gameCenter.authViewController.map(GameCenterControllerWrapper.init) },
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

private struct GameCenterControllerWrapper: Identifiable {
    let viewController: UIViewController
    var id: ObjectIdentifier { ObjectIdentifier(viewController) }
}

private struct GameCenterControllerHost: UIViewControllerRepresentable {
    let viewController: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

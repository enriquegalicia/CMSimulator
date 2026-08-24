//
//  RootView.swift
//  CMSimulator
//
//  Navigation coordinator - launches straight into GameView (no start
//  screen to tap through) and replaces the Objective-C ViewController's
//  presentViewController: chain for everything else (Result -> Scores,
//  Help/Settings as sheets) with plain SwiftUI state.
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
            ResultView(cost: engine.finalCost, days: engine.finalDays) { name in
                let finalName = name.isEmpty ? String(localized: "Player", comment: "Default score entry name when the player leaves the name field blank") : name
                let entry = ScoreEntry(playerName: finalName, cost: engine.finalCost, days: engine.finalDays)
                modelContext.insert(entry)
                gameCenter.reportScore(
                    cost: engine.finalCost,
                    days: engine.finalDays,
                    combined: engine.finalCost + engine.finalDays * 1000
                )
                showResult = false
                showScores = true
            }
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

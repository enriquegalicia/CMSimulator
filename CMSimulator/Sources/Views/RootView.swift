//
//  RootView.swift
//  CMSimulator
//
//  Navigation coordinator - replaces the Objective-C ViewController's
//  presentViewController: chain (Intro -> Game -> Result -> Scores,
//  Help as an overlay) with plain SwiftUI state.
//

import SwiftUI
import SwiftData

private enum Screen {
    case intro, game
}

struct RootView: View {
    @StateObject private var engine = SimulationEngine()
    @StateObject private var gameCenter = GameCenterManager()
    @Environment(\.modelContext) private var modelContext

    @State private var screen: Screen = .intro
    @State private var showHelp = false
    @State private var showScores = false
    @State private var showResult = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            switch screen {
            case .intro:
                IntroView(
                    onPlay: { screen = .game },
                    onHelp: { showHelp = true },
                    onScores: { showScores = true },
                    onSettings: { showSettings = true }
                )
            case .game:
                GameView(
                    engine: engine,
                    onShowHelp: { showHelp = true },
                    onShowScores: { showScores = true },
                    onGameCenter: { gameCenter.showDashboard() },
                    onComplete: { showResult = true }
                )
            }
        }
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
                let finalName = name.isEmpty ? "Player" : name
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

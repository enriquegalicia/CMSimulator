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

    var body: some View {
        ZStack {
            switch screen {
            case .intro:
                IntroView(
                    onPlay: { screen = .game },
                    onHelp: { showHelp = true },
                    onScores: { showScores = true }
                )
            case .game:
                GameView(
                    engine: engine,
                    onShowHelp: { showHelp = true },
                    onShowScores: { showScores = true },
                    onGameCenter: { gameCenter.authenticate() },
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
        .fullScreenCover(isPresented: $showResult) {
            ResultView(cost: engine.finalCost, days: engine.finalDays) { name in
                let finalName = name.isEmpty ? "Player" : name
                let entry = ScoreEntry(playerName: finalName, cost: engine.finalCost, days: engine.finalDays)
                modelContext.insert(entry)
                gameCenter.reportScore(cost: engine.finalCost)
                showResult = false
                showScores = true
            }
        }
        .task { gameCenter.authenticate() }
        .sheet(item: Binding(
            get: { gameCenter.authViewController.map(GameCenterAuthWrapper.init) },
            set: { _ in gameCenter.authViewController = nil }
        )) { wrapper in
            GameCenterAuthView(viewController: wrapper.viewController)
        }
    }
}

private struct GameCenterAuthWrapper: Identifiable {
    let viewController: UIViewController
    var id: ObjectIdentifier { ObjectIdentifier(viewController) }
}

private struct GameCenterAuthView: UIViewControllerRepresentable {
    let viewController: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

//
//  GameView.swift
//  CMSimulator
//
//  The main simulator board - adaptive replacement for ViewController's
//  fixed 1024x768 storyboard. Two columns on wide/regular screens
//  (iPad), a single scrollable column on compact screens (iPhone).
//

import SwiftUI

struct GameView: View {
    @ObservedObject var engine: SimulationEngine
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let onShowHelp: () -> Void
    let onShowScores: () -> Void
    let onGameCenter: () -> Void
    let onComplete: () -> Void

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding()

            ScrollView {
                if isWide {
                    HStack(alignment: .top, spacing: 16) {
                        packagesColumn
                        boostersColumn
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        packagesColumn
                        boostersColumn
                    }
                    .padding(.horizontal)
                }
            }

            transportControls
                .padding()
        }
        .onChange(of: engine.isComplete) { _, complete in
            if complete { onComplete() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Cost").font(.caption).foregroundStyle(.secondary)
                    Text(engine.totalCost, format: .currency(code: "USD")).font(.headline.monospacedDigit())
                }
                Spacer()
                VStack {
                    Text("Time").font(.caption).foregroundStyle(.secondary)
                    Text("\(engine.totalDays)d \(engine.totalHours)h").font(.headline.monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Progress").font(.caption).foregroundStyle(.secondary)
                    Text(engine.totalProgress, format: .number.precision(.fractionLength(1))) .font(.headline.monospacedDigit())
                        + Text("%").font(.headline)
                }
            }
            HStack(spacing: 24) {
                GaugeView(title: "Risk", value: engine.riskGauge).frame(height: 70)
                GaugeView(title: "Quality", value: engine.qualityGauge).frame(height: 70)
                Spacer()
                Button(action: onShowHelp) { Label("Help", systemImage: "questionmark.circle") }
                Button(action: onShowScores) { Label("Scores", systemImage: "trophy") }
                Button(action: onGameCenter) { Label("Game Center", systemImage: "gamecontroller") }
            }
            .labelStyle(.iconOnly)
            .font(.title3)
        }
    }

    private var packagesColumn: some View {
        VStack(spacing: 8) {
            Text("Work Packages").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(engine.workPackages) { WorkPackageCardView(package: $0) }
        }
    }

    private var boostersColumn: some View {
        VStack(spacing: 8) {
            Text("Boosters").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(engine.boosters) { booster in
                BoosterCardView(
                    booster: booster,
                    onBuy: { engine.buyBooster(booster.id) },
                    onSell: { engine.sellBooster(booster.id) }
                )
            }
        }
    }

    private var transportControls: some View {
        HStack(spacing: 32) {
            Button(action: engine.pause) {
                Image(systemName: "pause.circle.fill")
            }
            Button(action: engine.play) {
                Image(systemName: "play.circle.fill")
            }
            Button(action: engine.fastForward) {
                Image(systemName: "forward.circle.fill")
            }
        }
        .font(.system(size: 44))
        .buttonStyle(.plain)
    }
}

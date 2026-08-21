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
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
    let onShowHelp: () -> Void
    let onShowScores: () -> Void
    let onGameCenter: () -> Void
    let onComplete: () -> Void

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(isWide ? 20 : 16)

            ScrollView {
                Group {
                    if isWide {
                        HStack(alignment: .top, spacing: 24) {
                            packagesColumn
                            boostersColumn
                        }
                    } else {
                        VStack(spacing: 16) {
                            packagesColumn
                            boostersColumn
                        }
                    }
                }
                .padding(.horizontal, isWide ? 24 : 16)
                .frame(maxWidth: isWide ? 1100 : .infinity)
                .frame(maxWidth: .infinity)
            }

            transportControls
                .padding(isWide ? 24 : 16)
        }
        .onChange(of: engine.isComplete) { _, complete in
            if complete { onComplete() }
        }
        .overlay(alignment: .top) {
            if let event = engine.activeEvent {
                eventBanner(event)
                    .padding(.top, isWide ? 12 : 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(duration: 0.35), value: engine.activeEvent?.id)
    }

    private func eventBanner(_ event: SimEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.kind.symbolName)
                .font(isWide ? .largeTitle : .title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.kind.title).font(isWide ? .title3.bold() : .headline).foregroundStyle(.white)
                Text(event.message).font(isWide ? .body : .caption).foregroundStyle(.white.opacity(0.9))
                Text("+\(event.extraCost, format: .currency(code: currencyCode)) to the project")
                    .font(isWide ? .body.bold() : .caption.bold())
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 8)

            Button(action: engine.dismissEvent) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(isWide ? 20 : 12)
        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, isWide ? 40 : 12)
        .frame(maxWidth: isWide ? 700 : .infinity)
        .shadow(radius: 8, y: 4)
    }

    private var header: some View {
        VStack(spacing: isWide ? 12 : 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Cost").font(.caption).foregroundStyle(.secondary)
                    Text(engine.totalCost, format: .currency(code: currencyCode)).font(isWide ? .title.bold() : .headline.monospacedDigit())
                }
                Spacer()
                VStack {
                    Text("Time").font(.caption).foregroundStyle(.secondary)
                    Text("\(engine.totalDays)d \(engine.totalHours)h").font(isWide ? .title.bold() : .headline.monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Progress").font(.caption).foregroundStyle(.secondary)
                    Text(engine.totalProgress, format: .number.precision(.fractionLength(1))) .font(isWide ? .title.bold() : .headline.monospacedDigit())
                        + Text("%").font(isWide ? .title.bold() : .headline)
                }
            }
            HStack(spacing: isWide ? 32 : 24) {
                GaugeView(title: "Risk", value: engine.riskGauge).frame(height: isWide ? 90 : 70)
                GaugeView(title: "Quality", value: engine.qualityGauge).frame(height: isWide ? 90 : 70)
                Spacer()
                Button(action: onShowHelp) { Label("Help", systemImage: "questionmark.circle") }
                Button(action: onShowScores) { Label("Scores", systemImage: "trophy") }
                Button(action: onGameCenter) { Label("Game Center", systemImage: "gamecontroller") }
            }
            .labelStyle(.iconOnly)
            .font(isWide ? .title : .title3)
        }
        .frame(maxWidth: isWide ? 1100 : .infinity)
    }

    private var packagesColumn: some View {
        VStack(spacing: isWide ? 12 : 8) {
            Text("Work Packages").font(isWide ? .headline : .caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(engine.workPackages) { package in
                WorkPackageCardView(
                    package: package,
                    onHire: { engine.hireWorker(for: package.id) },
                    onFire: { engine.fireWorker(for: package.id) }
                )
            }
        }
    }

    private var boostersColumn: some View {
        VStack(spacing: isWide ? 12 : 8) {
            Text("Boosters").font(isWide ? .headline : .caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(spacing: isWide ? 32 : 24) {
            Button(action: engine.pause) {
                Image(systemName: "pause.circle.fill")
            }
            Button(action: engine.play) {
                Image(systemName: "play.circle.fill")
            }
            Button(action: engine.fastForward) {
                Image(systemName: "forward.circle.fill")
            }
            Button(action: engine.superFastForward) {
                Image(systemName: "forward.end.circle.fill")
            }
        }
        .font(.system(size: isWide ? 50 : 40))
        .buttonStyle(.plain)
    }
}

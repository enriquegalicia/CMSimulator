//
//  IntroView.swift
//  CMSimulator
//

import SwiftUI

struct IntroView: View {
    let onPlay: () -> Void
    let onHelp: () -> Void
    let onScores: () -> Void
    let onSettings: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isWide: Bool { horizontalSizeClass == .regular }

    private var iconSize: CGFloat { isWide ? 340 : 220 }
    private var titleFont: Font { isWide ? .system(size: 40, weight: .bold) : .title2.bold() }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: isWide ? 40 : 28) {
                    Spacer(minLength: 20)

                    Image(bundleResource: "AppIcon-Source.png")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: iconSize, maxHeight: iconSize)

                    Text("Construction Management Simulator")
                        .font(titleFont)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(maxWidth: isWide ? 700 : nil)

                    Spacer(minLength: 20)

                    if isWide {
                        HStack(spacing: 24) {
                            Button(action: onPlay) {
                                Label("Play", systemImage: "play.fill").frame(maxWidth: 200)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.extraLarge)

                            Button(action: onHelp) {
                                Label("Help", systemImage: "questionmark.circle").frame(maxWidth: 160)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.extraLarge)

                            Button(action: onScores) {
                                Label("Scores", systemImage: "trophy").frame(maxWidth: 160)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.extraLarge)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Button(action: onPlay) {
                                Label("Play", systemImage: "play.fill")
                                    .frame(maxWidth: 260)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            HStack(spacing: 16) {
                                Button(action: onHelp) {
                                    Label("Help", systemImage: "questionmark.circle")
                                }
                                Button(action: onScores) {
                                    Label("Scores", systemImage: "trophy")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(isWide ? .title : .title2)
                    .padding()
            }
        }
    }
}

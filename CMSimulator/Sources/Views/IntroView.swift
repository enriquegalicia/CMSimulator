//
//  IntroView.swift
//  CMSimulator
//

import SwiftUI

struct IntroView: View {
    let onPlay: () -> Void
    let onHelp: () -> Void
    let onScores: () -> Void

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    Image(bundleResource: "AppIcon-Source.png")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 220)

                    Text("Construction Management Simulator")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer(minLength: 20)

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

                    Spacer(minLength: 20)
                }
                .padding()
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
        }
    }
}

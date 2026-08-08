//
//  CMSimulatorApp.swift
//  CMSimulator
//
//  SwiftUI app entry point - replaces AppDelegate.h/.m, main.m, and
//  Main.storyboard's UIMainStoryboardFile wiring.
//

import SwiftUI
import SwiftData

@main
struct CMSimulatorApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: ScoreEntry.self)
    }
}

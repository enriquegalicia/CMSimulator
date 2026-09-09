//
//  CMSimulatorApp.swift
//  CMSimulator
//
//  SwiftUI app entry point.
//

import SwiftUI
import SwiftData

@main
struct CriticalPathSimApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer

    init() {
        // Before anything else, so a crash during setup is still captured.
        Diagnostics.shared.install()
        container = ScoreStore.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            // Reaching the background is the signal that this run ended
            // cleanly; anything else on next launch means we died.
            switch phase {
            case .background, .inactive: Diagnostics.shared.markCleanExit()
            case .active: Diagnostics.shared.markRunning()
            @unknown default: break
            }
        }
    }
}

/// Opens the leaderboard store, and survives the case where it cannot be
/// opened at all.
///
/// `.modelContainer(for:)` traps on failure, which meant the rebuild
/// crashed on launch for anyone upgrading: `ScoreEntry` changed shape
/// completely when scoring moved from a cost+days sum to profit, so an
/// existing store on disk no longer matched the model.
enum ScoreStore {
    /// Main-actor isolated because it reports failures through Diagnostics.
    /// SwiftUI's `App.init()` already runs on the main actor, so this costs
    /// nothing at the only call site.
    @MainActor
    static func makeContainer() -> ModelContainer {
        let schema = Schema([ScoreEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // Old saved runs were scored on a metric that no longer exists,
            // so they cannot be carried forward or compared against new
            // ones. Rebuilding the store loses only those old rows, which
            // is a far better outcome than an app that will not start.
            Diagnostics.shared.recordError(
                String(localized: "Saved scores could not be opened", comment: "Diagnostic summary"),
                detail: """
                The leaderboard store did not match the current model and was rebuilt. \
                Previous saved runs were lost. This is expected once, on the first \
                launch after scoring changed from cost and time to profit.

                \(error)
                """
            )
            destroyStore()
            if let fresh = try? ModelContainer(for: schema, configurations: configuration) {
                return fresh
            }
            // Last resort: run without persistence rather than not at all.
            Diagnostics.shared.recordError(
                String(localized: "Scores cannot be saved on this device", comment: "Diagnostic summary"),
                detail: "The store could not be recreated. Running in memory; scores will not persist."
            )
            let memoryOnly = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // If even an in-memory store fails there is nothing left to try.
            return try! ModelContainer(for: schema, configurations: memoryOnly)
        }
    }

    private static func destroyStore() {
        guard let support = try? FileManager.default.url(for: .applicationSupportDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: nil,
                                                         create: false) else { return }
        // SwiftData's default store, plus the SQLite sidecars that must go
        // with it or the rebuilt store inherits the old journal.
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: support.appendingPathComponent(name))
        }
    }
}

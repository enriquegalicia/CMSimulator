//
//  Diagnostics.swift
//  CMSimulator
//
//  Local crash and error reporting.
//
//  There is no backend to send reports to - this is a paid app with no
//  server - so reports are written to the app's container, survive
//  relaunch, and can be exported from Settings ▸ Diagnostics and sent on
//  to be fixed.
//
//  Crash capture has one hard constraint: a signal handler may only call
//  async-signal-safe functions. Allocating, taking locks, or touching
//  Swift collections inside one can deadlock or corrupt the very report
//  it is trying to write. So the breadcrumb trail is mirrored into a
//  fixed C buffer as it is recorded, and the handler does nothing but
//  `write(2)` that buffer plus a backtrace to a file descriptor opened
//  ahead of time. Turning that raw marker into a readable report happens
//  on the *next* launch, where normal code is safe again.
//

import Foundation
import Darwin
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Report

struct DiagnosticReport: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case crash
        case error
        case unexpectedExit

        var title: String {
            switch self {
            case .crash: return String(localized: "Crash", comment: "Diagnostic report kind")
            case .error: return String(localized: "Error", comment: "Diagnostic report kind")
            case .unexpectedExit: return String(localized: "Unexpected exit", comment: "Diagnostic report kind")
            }
        }

        var symbolName: String {
            switch self {
            case .crash: return "exclamationmark.octagon.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .unexpectedExit: return "bolt.slash.fill"
            }
        }
    }

    let id: UUID
    let date: Date
    let kind: Kind
    /// Short headline, e.g. "SIGSEGV" or "Score store unreadable".
    let summary: String
    /// Anything else worth knowing - error text, stack, breadcrumbs.
    let detail: String
    let appVersion: String
    let osVersion: String
    let deviceModel: String

    /// One self-contained block of text, which is what actually gets
    /// shared out of the app.
    var exportText: String {
        """
        ── \(kind.title): \(summary)
        Time      \(ISO8601DateFormatter().string(from: date))
        App       \(appVersion)
        OS        \(osVersion)
        Device    \(deviceModel)

        \(detail)
        """
    }
}

// MARK: - Signal-handler scratch space
//
// Everything in this section is touched from a signal handler, so it is
// deliberately plain C storage with no allocation, no locking and no
// Swift runtime involvement.

private let breadcrumbCapacity = 8_192
private let breadcrumbBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: breadcrumbCapacity)
private var breadcrumbLength = 0
/// Opened before any crash can happen, so the handler never has to.
private var crashMarkerFD: Int32 = -1

/// Appends to the C breadcrumb buffer, dropping the oldest half when it
/// fills so a long session still leaves the most recent context behind.
private func appendBreadcrumb(_ text: String) {
    let bytes = Array(text.utf8CString.dropLast()) + [CChar(10)]  // newline
    if breadcrumbLength + bytes.count >= breadcrumbCapacity {
        let keep = breadcrumbLength / 2
        memmove(breadcrumbBuffer, breadcrumbBuffer + (breadcrumbLength - keep), keep)
        breadcrumbLength = keep
    }
    guard breadcrumbLength + bytes.count < breadcrumbCapacity else { return }
    bytes.withUnsafeBufferPointer { src in
        guard let base = src.baseAddress else { return }
        memcpy(breadcrumbBuffer + breadcrumbLength, base, src.count)
    }
    breadcrumbLength += bytes.count
}

/// Async-signal-safe. Writes the marker and lets the default handler
/// finish the job so the OS still sees a real crash.
private func handleFatalSignal(_ signal: Int32) {
    guard crashMarkerFD >= 0 else {
        Darwin.signal(signal, SIG_DFL)
        raise(signal)
        return
    }
    let name: StaticString
    switch signal {
    case SIGABRT: name = "SIGABRT\n"
    case SIGSEGV: name = "SIGSEGV\n"
    case SIGBUS:  name = "SIGBUS\n"
    case SIGILL:  name = "SIGILL\n"
    case SIGFPE:  name = "SIGFPE\n"
    case SIGTRAP: name = "SIGTRAP\n"
    default:      name = "SIGNAL\n"
    }
    name.withUTF8Buffer { buf in
        if let base = buf.baseAddress { _ = write(crashMarkerFD, base, buf.count) }
    }

    let header: StaticString = "--- breadcrumbs ---\n"
    header.withUTF8Buffer { buf in
        if let base = buf.baseAddress { _ = write(crashMarkerFD, base, buf.count) }
    }
    _ = write(crashMarkerFD, breadcrumbBuffer, breadcrumbLength)

    let stackHeader: StaticString = "--- stack ---\n"
    stackHeader.withUTF8Buffer { buf in
        if let base = buf.baseAddress { _ = write(crashMarkerFD, base, buf.count) }
    }
    var frames = [UnsafeMutableRawPointer?](repeating: nil, count: 64)
    let count = backtrace(&frames, Int32(frames.count))
    backtrace_symbols_fd(&frames, count, crashMarkerFD)

    fsync(crashMarkerFD)
    Darwin.signal(signal, SIG_DFL)
    raise(signal)
}

// MARK: - Diagnostics

@MainActor
final class Diagnostics: ObservableObject {
    static let shared = Diagnostics()

    @Published private(set) var reports: [DiagnosticReport] = []

    private let directory: URL
    private let markerURL: URL
    private let runningFlagURL: URL
    private var isInstalled = false

    private init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = base.appendingPathComponent("Diagnostics", isDirectory: true)
        markerURL = directory.appendingPathComponent("pending-crash.txt")
        runningFlagURL = directory.appendingPathComponent("running.flag")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: Install

    /// Call once, as early as possible. Converts anything left behind by a
    /// previous run into a report, then arms the handlers for this run.
    func install() {
        guard !isInstalled else { return }
        isInstalled = true

        // Order matters: existing reports have to be in memory before
        // anything new is saved, or the first save persists a one-entry
        // array over the top of the file and destroys the history.
        loadReports()
        harvestPendingCrash()
        detectUnexpectedExit()

        crashMarkerFD = open(markerURL.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        // Truncated to empty, so an ordinary run leaves a zero-length file
        // that harvest correctly ignores.
        FileManager.default.createFile(atPath: runningFlagURL.path, contents: Data())

        NSSetUncaughtExceptionHandler { exception in
            // Not signal context - Foundation is safe here.
            let stack = exception.callStackSymbols.joined(separator: "\n")
            let text = """
            \(exception.name.rawValue)
            \(exception.reason ?? "")
            --- stack ---
            \(stack)
            """
            Diagnostics.writeMarkerFromExceptionHandler(text)
        }

        for sig in [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGTRAP] {
            Darwin.signal(sig, handleFatalSignal)
        }

        breadcrumb("Launched")
    }

    /// The exception handler runs on a doomed thread but not in signal
    /// context, so it may allocate - it just cannot touch the actor.
    nonisolated private static func writeMarkerFromExceptionHandler(_ text: String) {
        guard crashMarkerFD >= 0 else { return }
        var payload = Array(text.utf8)
        payload.append(10)
        payload.withUnsafeBufferPointer { buf in
            if let base = buf.baseAddress { _ = write(crashMarkerFD, base, buf.count) }
        }
        _ = write(crashMarkerFD, breadcrumbBuffer, breadcrumbLength)
        fsync(crashMarkerFD)
    }

    /// Records a step in the session. Kept short - these are the trail a
    /// crash report is read backwards from.
    func breadcrumb(_ text: String) {
        let stamped = "\(Self.clock.string(from: Date())) \(text)"
        appendBreadcrumb(stamped)
    }

    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// A non-fatal problem worth reporting - something was caught and
    /// handled, but the user still lost something.
    func recordError(_ summary: String, detail: String) {
        breadcrumb("ERROR \(summary)")
        save(makeReport(kind: .error, summary: summary, detail: detail))
    }

    // MARK: Lifecycle

    /// Called when the app goes to the background or terminates cleanly.
    func markCleanExit() {
        try? FileManager.default.removeItem(at: runningFlagURL)
    }

    func markRunning() {
        FileManager.default.createFile(atPath: runningFlagURL.path, contents: Data())
    }

    // MARK: Harvest

    private func harvestPendingCrash() {
        guard let data = try? Data(contentsOf: markerURL), !data.isEmpty,
              let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            try? FileManager.default.removeItem(at: markerURL)
            return
        }
        let summary = text.split(separator: "\n").first.map(String.init) ?? "Crash"
        save(makeReport(kind: .crash, summary: summary, detail: text))
        try? FileManager.default.removeItem(at: markerURL)
    }

    /// If the running flag survived, the previous run ended without ever
    /// reaching the background - and without leaving a crash marker. That
    /// is the signature of a watchdog kill or an out-of-memory jetsam,
    /// neither of which raises a signal we can catch.
    private func detectUnexpectedExit() {
        guard FileManager.default.fileExists(atPath: runningFlagURL.path) else { return }
        try? FileManager.default.removeItem(at: runningFlagURL)
        // Only report it when no crash marker explained the exit already.
        guard reports.first?.kind != .crash else { return }
        save(makeReport(
            kind: .unexpectedExit,
            summary: String(localized: "App closed without shutting down", comment: "Diagnostic summary"),
            detail: String(localized: "The previous session ended without reaching the background and without a crash signal. This usually means the system terminated the app for using too much memory, or it stopped responding.", comment: "Diagnostic detail")
        ))
    }

    // MARK: Storage

    private func makeReport(kind: DiagnosticReport.Kind, summary: String, detail: String) -> DiagnosticReport {
        DiagnosticReport(
            id: UUID(),
            date: Date(),
            kind: kind,
            summary: summary,
            detail: detail,
            appVersion: Self.appVersion,
            osVersion: Self.osVersion,
            deviceModel: Self.deviceModel
        )
    }

    private var reportsFileURL: URL { directory.appendingPathComponent("reports.json") }

    private func loadReports() {
        guard let data = try? Data(contentsOf: reportsFileURL),
              let decoded = try? JSONDecoder().decode([DiagnosticReport].self, from: data) else { return }
        reports = decoded.sorted { $0.date > $1.date }
    }

    private func save(_ report: DiagnosticReport) {
        reports.insert(report, at: 0)
        // Keep the file small enough that it can be pasted into an issue.
        if reports.count > 25 { reports.removeLast(reports.count - 25) }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        try? data.write(to: reportsFileURL, options: .atomic)
    }

    func clear() {
        reports = []
        persist()
    }

    func delete(_ report: DiagnosticReport) {
        reports.removeAll { $0.id == report.id }
        persist()
    }

    // MARK: Export

    /// Everything recorded, as one plain-text file ready to share.
    var exportText: String {
        guard !reports.isEmpty else {
            return String(localized: "No problems have been recorded.", comment: "Diagnostics export when empty")
        }
        let header = """
        Critical Path diagnostics
        Generated \(ISO8601DateFormatter().string(from: Date()))
        \(reports.count) report(s)

        """
        return header + reports.map(\.exportText).joined(separator: "\n\n")
    }

    /// Writes the export to a temporary file so it can go through a share
    /// sheet as a real attachment rather than a wall of pasted text.
    func writeExportFile() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("critical-path-diagnostics.txt")
        guard let data = exportText.data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: Environment

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    static var osVersion: String {
        #if canImport(UIKit)
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    /// The marketing name is not exposed, but the machine identifier is
    /// what actually matters when reproducing a layout or memory problem.
    static var deviceModel: String {
        var info = utsname()
        uname(&info)
        let identifier = withUnsafePointer(to: &info.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return identifier.isEmpty ? "unknown" : identifier
    }
}

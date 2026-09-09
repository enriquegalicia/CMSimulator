//
//  DiagnosticsView.swift
//  CMSimulator
//
//  Reads out whatever Diagnostics has captured and gets it off the device.
//  There is no server to upload to, so the route back to a fix is the
//  share sheet: mail it, AirDrop it, or drop it into Files.
//

import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject private var diagnostics = Diagnostics.shared
    @State private var exportURL: URL?
    @State private var showClearConfirm = false

    var body: some View {
        List {
            if diagnostics.reports.isEmpty {
                Section {
                    Label(String(localized: "Nothing has gone wrong yet.", comment: "Diagnostics empty state"),
                          systemImage: "checkmark.seal")
                        .foregroundStyle(.green)
                } footer: {
                    Text("If the app crashes or hits a problem, it gets recorded here automatically — including what you were doing just before.", comment: "Diagnostics empty state explanation")
                }
            } else {
                Section {
                    ForEach(diagnostics.reports) { report in
                        NavigationLink {
                            DiagnosticDetailView(report: report)
                        } label: {
                            row(report)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            diagnostics.delete(diagnostics.reports[index])
                        }
                    }
                } header: {
                    Text("Recorded problems", comment: "Diagnostics section header")
                } footer: {
                    Text("Send these on so they can be fixed. Nothing is uploaded on its own — reports stay on this device until you share them.", comment: "Diagnostics privacy note")
                }

                Section {
                    Button {
                        exportURL = diagnostics.writeExportFile()
                    } label: {
                        Label(String(localized: "Export all reports", comment: "Diagnostics export button"),
                              systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label(String(localized: "Delete all reports", comment: "Diagnostics clear button"),
                              systemImage: "trash")
                    }
                }
            }

            Section {
                LabeledContent(String(localized: "App version", comment: "Diagnostics environment row"),
                               value: Diagnostics.appVersion)
                LabeledContent(String(localized: "System", comment: "Diagnostics environment row"),
                               value: Diagnostics.osVersion)
                LabeledContent(String(localized: "Device", comment: "Diagnostics environment row"),
                               value: Diagnostics.deviceModel)
            } header: {
                Text("This device", comment: "Diagnostics section header")
            }
        }
        .navigationTitle(String(localized: "Diagnostics", comment: "Diagnostics screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { exportURL.map(ShareableFile.init) },
            set: { _ in exportURL = nil }
        )) { file in
            ShareSheet(items: [file.url])
        }
        .confirmationDialog(String(localized: "Delete every report?", comment: "Diagnostics clear confirmation"),
                            isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button(String(localized: "Delete all", comment: "Diagnostics clear confirmation action"), role: .destructive) {
                diagnostics.clear()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. Export them first if they have not been sent on yet.", comment: "Diagnostics clear confirmation message")
        }
    }

    private func row(_ report: DiagnosticReport) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: report.kind.symbolName)
                .foregroundStyle(report.kind == .error ? .orange : .red)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.summary)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text(report.date, format: .dateTime.day().month().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct DiagnosticDetailView: View {
    let report: DiagnosticReport
    @State private var exportURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(report.summary)
                    .font(.headline)
                    .textSelection(.enabled)

                Text(report.detail)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle(report.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportURL = write()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(String(localized: "Share this report", comment: "Diagnostics share button"))
            }
        }
        .sheet(item: Binding(
            get: { exportURL.map(ShareableFile.init) },
            set: { _ in exportURL = nil }
        )) { file in
            ShareSheet(items: [file.url])
        }
    }

    private func write() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("critical-path-report.txt")
        guard let data = report.exportText.data(using: .utf8) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }
}

private struct ShareableFile: Identifiable {
    let url: URL
    var id: String { url.path }
}

/// UIActivityViewController wrapper - ShareLink cannot present a file URL
/// that is created on demand from a button the way this screen needs.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

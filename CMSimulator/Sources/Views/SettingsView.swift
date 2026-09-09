//
//  SettingsView.swift
//  CMSimulator
//

import SwiftUI

struct SettingsView: View {
    let onExit: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(AppSettings.availableCurrencyCodes, id: \.self) { code in
                            Text("\(AppSettings.displayName(for: code)) (\(code))").tag(code)
                        }
                    }
                } header: {
                    Text("Currency", comment: "Settings section header")
                } footer: {
                    Text("Costs throughout the simulator display in this currency. Defaults to your device's own currency.", comment: "Settings currency footer")
                }

                Section {
                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        HStack {
                            Label(String(localized: "Diagnostics", comment: "Settings row"), systemImage: "stethoscope")
                            Spacer()
                            if !Diagnostics.shared.reports.isEmpty {
                                Text("\(Diagnostics.shared.reports.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } footer: {
                    Text("Crashes and errors are recorded on this device so they can be sent on and fixed. Nothing is uploaded automatically.", comment: "Settings diagnostics footer")
                }
            }
            .navigationTitle(String(localized: "Settings", comment: "Settings screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onExit)
                }
            }
        }
        .frame(maxWidth: isWide ? 600 : .infinity)
    }
}

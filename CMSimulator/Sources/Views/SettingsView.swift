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
                    Text("Currency")
                } footer: {
                    Text("Costs throughout the simulator display in this currency. Defaults to your device's own currency.")
                }
            }
            .navigationTitle("Settings")
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

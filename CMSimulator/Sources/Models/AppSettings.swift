//
//  AppSettings.swift
//  CMSimulator
//
//  Shared UserDefaults keys for app-wide preferences.
//

import Foundation

enum AppSettings {
    static let currencyCodeKey = "currencyCode"
    /// Set once the player has been shown the scenario list, so the
    /// picker greets a first-time player and never nags after that.
    static let hasSeenScenarioPickerKey = "hasSeenScenarioPicker"

    /// The device's own currency, used the first time the app runs before
    /// the player has ever opened Settings. Falls back to USD if the
    /// locale genuinely has none (e.g. some non-region locales).
    static var defaultCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    /// Common currencies for the settings picker, each with an
    /// ISO 4217 code and its display name via the current locale.
    static var availableCurrencyCodes: [String] {
        let common = ["USD", "EUR", "GBP", "MXN", "CAD", "AUD", "JPY", "CNY",
                       "BRL", "INR", "CHF", "SEK", "NOK", "COP", "ARS", "CLP"]
        // Always include the device's own currency even if it's not in the
        // hand-picked common list above.
        var codes = common
        if !codes.contains(defaultCurrencyCode) {
            codes.insert(defaultCurrencyCode, at: 0)
        }
        return codes
    }

    static func displayName(for currencyCode: String) -> String {
        Locale.current.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
    }
}

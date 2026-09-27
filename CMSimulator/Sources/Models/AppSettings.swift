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
    /// The name typed on the last saved score, reused as the default so a
    /// run that ends before the player revisits the debrief still saves
    /// under a recognizable name rather than "Player" every time.
    static let lastPlayerNameKey = "lastPlayerName"

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

    /// Every number the simulation produces - wages, contract values, exit
    /// prices - is denominated in one canonical unit, USD, which is what the
    /// balance harness tunes against. The currency picker only changes how
    /// that number is displayed; without this table it was relabelling the
    /// same raw figure with a different symbol, so a peso amount looked
    /// exactly like the dollar amount instead of ~18x larger. This is a
    /// static snapshot, not a live market rate - refresh it by hand
    /// periodically, it does not need to track the market to the peso.
    /// Units of that currency per 1 USD. Last set 2026-09-24.
    private static let usdExchangeRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "MXN": 18.5,
        "CAD": 1.37,
        "AUD": 1.52,
        "JPY": 150.0,
        "CNY": 7.2,
        "BRL": 5.4,
        "INR": 83.5,
        "CHF": 0.88,
        "SEK": 10.4,
        "NOK": 10.6,
        "COP": 4100.0,
        "ARS": 1000.0,
        "CLP": 950.0,
    ]

    /// Units of `code` per 1 USD (the canonical unit every simulation number
    /// is already in). A currency outside the table falls back to 1.0 -
    /// displayed at face value rather than silently wrong, since there is no
    /// safe rate to guess.
    static func exchangeRate(for code: String) -> Double {
        usdExchangeRates[code] ?? 1.0
    }
}

/// Converts a USD-denominated simulation value to the display currency's own
/// real terms before formatting it, so switching currency in Settings shows
/// an equivalent amount rather than the same number with a different symbol.
/// Drop-in replacement for `.currency(code:)` everywhere the app shows money
/// - the simulation, the ledger and Game Center scores stay in USD always;
/// only this formatting step converts.
struct MarketCurrencyFormatStyle: FormatStyle {
    let code: String
    var fractionLength: Int = 0

    func format(_ value: Double) -> String {
        (value * AppSettings.exchangeRate(for: code))
            .formatted(.currency(code: code).precision(.fractionLength(fractionLength)))
    }
}

extension FormatStyle where Self == MarketCurrencyFormatStyle {
    static func marketCurrency(_ code: String, fractionLength: Int = 0) -> MarketCurrencyFormatStyle {
        MarketCurrencyFormatStyle(code: code, fractionLength: fractionLength)
    }
}

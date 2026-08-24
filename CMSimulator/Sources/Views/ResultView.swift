//
//  ResultView.swift
//  CMSimulator
//

import SwiftUI

struct ResultView: View {
    let cost: Double
    let days: Double
    let onSave: (String) -> Void

    @State private var name: String = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
    private var isWide: Bool { horizontalSizeClass == .regular }

    private var wholeDays: Int { Int(days) }
    private var hours: Int { Int((days - Double(wholeDays)) * 8) }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 20)

                    card

                    Spacer(minLength: 20)
                }
                .padding(32)
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
        }
    }

    private var card: some View {
        VStack(spacing: isWide ? 28 : 20) {
            Text("Simulation Over").font(isWide ? .system(size: 40, weight: .bold) : .title.bold())

            VStack(spacing: 6) {
                Text("Final Cost").font(isWide ? .body : .caption).foregroundStyle(.secondary)
                Text(cost, format: .currency(code: currencyCode)).font(isWide ? .system(size: 34, weight: .semibold) : .title2.monospacedDigit())
            }
            VStack(spacing: 6) {
                Text("Final Time").font(isWide ? .body : .caption).foregroundStyle(.secondary)
                Text(String(localized: "\(wholeDays) Days \(hours) Hours", comment: "Final elapsed time on the results screen")).font(isWide ? .system(size: 34, weight: .semibold) : .title2.monospacedDigit())
            }

            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)
                .controlSize(isWide ? .large : .regular)

            Button("Save") { onSave(name) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(isWide ? 48 : 32)
        .frame(maxWidth: isWide ? 480 : 420)
        .background(isWide ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.clear), in: RoundedRectangle(cornerRadius: 24))
    }
}

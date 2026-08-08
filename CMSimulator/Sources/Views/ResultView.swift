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

    private var wholeDays: Int { Int(days) }
    private var hours: Int { Int((days - Double(wholeDays)) * 8) }

    var body: some View {
        VStack(spacing: 20) {
            Text("Simulation Over").font(.title.bold())

            VStack(spacing: 6) {
                Text("Final Cost").font(.caption).foregroundStyle(.secondary)
                Text(cost, format: .currency(code: "USD")).font(.title2.monospacedDigit())
            }
            VStack(spacing: 6) {
                Text("Final Time").font(.caption).foregroundStyle(.secondary)
                Text("\(wholeDays) Days \(hours) Hours").font(.title2.monospacedDigit())
            }

            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)

            Button("Save") { onSave(name) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
        .frame(maxWidth: 420)
    }
}

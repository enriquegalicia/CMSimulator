//
//  CapabilityCardView.swift
//  CMSimulator
//
//  One of the six knowledge areas. The card leads with the capability's
//  *verb* - buys information, takes a position, retires a debt - because
//  the whole point of the rebuild is that these six no longer do the same
//  thing to different numbers, and the player has to be able to see that
//  before spending anything.
//
//  Levels are staffed, not bought: the daily upkeep sits right next to
//  the step-up cost, so a capability always competes with payroll.
//

import SwiftUI

struct CapabilityCardView: View {
    let capability: Capability
    let spendingPower: Double
    /// A short line of what this capability is currently doing for the
    /// player, supplied by the engine so the card can prove its worth.
    let currentEffect: String?
    let onUpgrade: () -> Void
    let onStandDown: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    private var affordable: Bool { capability.nextLevelCost <= spendingPower }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(bundleResource: capability.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(capability.title).font(.subheadline.bold())
                    Text(capability.kind.verb)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                Spacer(minLength: 4)
                levelPips
            }

            Text(capability.kind.summary)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let currentEffect, capability.level > 0 {
                Label(currentEffect, systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if capability.isUnlocked {
                controls
            } else {
                Label(String(localized: "Available at \(Int(capability.kind.unlockThreshold))% overall", comment: "Locked capability hint"),
                      systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(capability.isUnlocked ? 1 : 0.4)
    }

    private var levelPips: some View {
        HStack(spacing: 3) {
            ForEach(0..<capability.kind.maxLevel, id: \.self) { index in
                Circle()
                    .fill(index < capability.level ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel(String(localized: "Level \(capability.level) of \(capability.kind.maxLevel)", comment: "Capability level accessibility label"))
    }

    private var controls: some View {
        VStack(spacing: 5) {
            if capability.level > 0 {
                HStack {
                    Label(String(localized: "\(capability.dailyUpkeep, format: .currency(code: currencyCode).precision(.fractionLength(0)))/day upkeep", comment: "Capability daily upkeep"),
                          systemImage: "calendar")
                    Spacer()
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if capability.isMaxed {
                    Text("Fully staffed", comment: "Capability at max level")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                } else {
                    Button(action: onUpgrade) {
                        VStack(spacing: 0) {
                            Text(capability.level == 0
                                 ? String(localized: "Staff", comment: "Button to staff a capability for the first time")
                                 : String(localized: "Step up", comment: "Button to raise a capability level"))
                                .font(.caption.bold())
                            Text(capability.nextLevelCost, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                .font(.caption2.monospacedDigit())
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!affordable)
                }

                if capability.level > 0 {
                    Button(action: onStandDown) {
                        Image(systemName: "minus")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(String(localized: "Stand down \(capability.title)", comment: "Accessibility label for reducing a capability"))
                }
            }
            .controlSize(.small)
        }
    }
}

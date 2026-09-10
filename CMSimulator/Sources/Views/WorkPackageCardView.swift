//
//  WorkPackageCardView.swift
//  CMSimulator
//
//  One work package. The card now has to carry three things the old one
//  did not: how many days of material cover is left (because running dry
//  idles a crew that is still on full pay), whether the crew is over the
//  optimal size (because crowding is what stops "hire everyone" from
//  being correct), and the overtime setting.
//

import SwiftUI

struct WorkPackageCardView: View {
    let package: WorkPackage
    let scenario: ScenarioKind
    /// Software has no warehouse: with no supply chain there is nothing to
    /// order and no way to be starved, so the whole strip is omitted.
    let usesSupplyChain: Bool
    private var showsSupply: Bool { usesSupplyChain && package.consumesMaterials }
    let crew: [Worker]
    let ordersInFlight: [MaterialOrder]
    let currentDay: Double
    let onHire: () -> Void
    let onOrder: () -> Void
    let onOpenCrew: () -> Void
    let onOvertime: (Double) -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    private var activeCrew: [Worker] { crew.filter { !$0.isInTraining } }
    private var isCrowded: Bool { activeCrew.count > package.optimalCrew }
    private var greenCount: Int { activeCrew.filter(\.isOnboarding).count }

    /// Days of work the material on site can support at the current rate.
    /// The number that tells the player when to order, so it leads.
    private var daysOfCover: Double? {
        let output = activeCrew.reduce(0) { $0 + $1.effectiveOutput }
            * WorkPackage.congestionFactor(crewSize: activeCrew.count, optimalCrew: package.optimalCrew)
            * WorkPackage.overtimeFactor(package.overtime)
        guard output > 0.01 else { return nil }
        return package.materialStock / package.spec.materialUnitsPerWorkUnit / output
    }

    private var nextDelivery: MaterialOrder? {
        ordersInFlight.filter { $0.packageID == package.id }.min { $0.arrivalDay < $1.arrivalDay }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ProgressView(value: package.progress)
                .tint(package.isComplete ? .green : .accentColor)
            statusLine
            if package.isUnlocked && !package.isComplete {
                controls
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(showsSupply && package.isStarvedOfMaterials && !activeCrew.isEmpty ? Color.red : Color.clear, lineWidth: 1.5)
        )
        .opacity(package.isUnlocked ? 1 : 0.4)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(bundleResource: package.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(package.title).font(.subheadline.bold())
                    if package.isFastTracked {
                        Label(String(localized: "Fast-tracked", comment: "Badge: stream started before its dependency finished"), systemImage: "bolt.fill")
                            .labelStyle(.iconOnly)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Text(package.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Button(action: onOpenCrew) {
                VStack(spacing: 0) {
                    Text("\(activeCrew.count)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(isCrowded ? .orange : .primary)
                    Text(String(localized: "of \(package.optimalCrew)", comment: "Crew size against the optimal crew for a package"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(crew.isEmpty)
            .accessibilityLabel(String(localized: "People on \(package.title)", comment: "Accessibility label for the crew count button"))
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if !package.isUnlocked {
            Label(String(localized: "Starts at \(Int(package.spec.startThreshold))% overall", comment: "Locked work package hint"),
                  systemImage: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if package.isComplete {
            Label(String(localized: "Complete", comment: "Work stream finished"), systemImage: "checkmark.seal.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        } else {
            VStack(alignment: .leading, spacing: 3) {
                if activeCrew.isEmpty {
                    Label(String(localized: "No \(scenario.staffName.lowercased()) assigned", comment: "Work package status"), systemImage: "person.slash")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else if showsSupply, package.isStarvedOfMaterials {
                    Label(String(localized: "Out of \(scenario.supplyName.lowercased()) — still on full pay", comment: "Work package status"),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                } else if showsSupply, let cover = daysOfCover {
                    Label(String(localized: "\(inputLabel): \(Int(package.materialStock)) units — \(String(format: "%.1f", cover)) days of cover", comment: "Named input stock and days of cover"),
                          systemImage: "shippingbox")
                        .font(.caption2)
                        .foregroundStyle(cover < 3 ? .orange : .secondary)
                } else if showsSupply {
                    Label(String(localized: "\(inputLabel): \(Int(package.materialStock)) units", comment: "Named input stock with no crew working"),
                          systemImage: "shippingbox")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if showsSupply, let delivery = nextDelivery {
                    Label(String(localized: "\(Int(delivery.quantity)) units arriving in \(Int(delivery.daysOut(from: currentDay))) days", comment: "Incoming delivery"),
                          systemImage: "truck.box")
                        .font(.caption2)
                        .foregroundStyle(delivery.hasSlipped ? .orange : .secondary)
                }

                if greenCount > 0 {
                    Label(String(localized: "\(greenCount) still onboarding — slowing the others", comment: "Mentoring drag warning"),
                          systemImage: "hourglass")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                if isCrowded {
                    Label(String(localized: "Crowded — output per head falling", comment: "Congestion warning"),
                          systemImage: "person.3.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    /// A design office buys surveys, a plumbing crew buys fixtures. The
    /// generic scenario word is only a fallback.
    private var inputLabel: String { package.inputName ?? scenario.supplyName }

    private var controls: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button(action: onHire) {
                    Label(String(localized: "Hire", comment: "Button: recruit onto this work stream"), systemImage: "person.badge.plus")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if showsSupply {
                    Button(action: onOrder) {
                        Label(scenario.supplyOrderVerb, systemImage: "cart")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(package.isStarvedOfMaterials ? .red : .accentColor)
                }
            }
            .controlSize(.small)

            if !activeCrew.isEmpty {
                HStack(spacing: 6) {
                    Text("Overtime", comment: "Label for the overtime slider")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(value: Binding(get: { package.overtime }, set: onOvertime), in: 0...1)
                        .controlSize(.mini)
                    Text(package.overtime, format: .percent.precision(.fractionLength(0)))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(package.overtime > 0.5 ? .orange : .secondary)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
    }
}

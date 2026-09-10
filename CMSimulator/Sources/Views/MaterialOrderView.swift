//
//  MaterialOrderView.swift
//  CMSimulator
//
//  The ordering decision, and the clearest place in the game where the
//  cheapest option is a trap. The old vendor sheet traded a price nudge
//  against a quality nudge; here the axes are price, lead time and
//  reliability, and picking the lowest bid on a package that is about to
//  run dry idles a crew that stays on full pay the whole time.
//

import SwiftUI

struct MaterialOrderView: View {
    let request: MaterialOrderRequest
    let scenario: ScenarioKind
    let spendingPower: Double
    let onOrder: (Vendor, Double) -> Void
    let onCancel: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode
    @State private var quantity: Double

    init(request: MaterialOrderRequest, scenario: ScenarioKind, spendingPower: Double,
         onOrder: @escaping (Vendor, Double) -> Void, onCancel: @escaping () -> Void) {
        self.request = request
        self.scenario = scenario
        self.spendingPower = spendingPower
        self.onOrder = onOrder
        self.onCancel = onCancel
        // Default to exactly what is left to build - the safe order, which
        // the player then has a reason to deviate from when cash is short.
        _quantity = State(initialValue: max(1, request.suggestedQuantity.rounded()))
    }

    /// Never degenerate. A Slider whose bounds are equal divides by a
    /// zero-width range, so this always leaves room to drag even when
    /// there is nothing outstanding to order.
    private var maxQuantity: Double { max(20, (request.suggestedQuantity * 2).rounded()) }

    /// True when the package already has everything it needs on site or on
    /// the way. Ordering more is allowed - a buffer against theft or a
    /// change order - but the player should know it is not needed.
    private var isAlreadyCovered: Bool { request.suggestedQuantity < 1 }

    private func unitPrice(_ vendor: Vendor) -> Double {
        request.baseCostPerUnit * request.marketIndex * vendor.priceFactor
    }

    private func leadTime(_ vendor: Vendor) -> Double {
        request.baseLeadTimeDays * vendor.leadTimeFactor
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Quantity", comment: "Order quantity label")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(quantity))")
                                .font(.headline.monospacedDigit())
                            Text("units", comment: "Unit suffix for a material order")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $quantity, in: 1...maxQuantity, step: 1)
                        if isAlreadyCovered {
                            Label(String(localized: "Already covered — enough is on site or on the way.", comment: "Order sheet note when nothing is outstanding"),
                                  systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            HStack {
                                Text(String(localized: "Enough to finish: \(Int(request.suggestedQuantity))", comment: "Suggested order quantity"))
                                Spacer()
                                Button(String(localized: "Use", comment: "Button to apply the suggested order quantity")) {
                                    quantity = max(1, request.suggestedQuantity.rounded())
                                }
                                .font(.caption.bold())
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.accentColor)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("How much", comment: "Order sheet section header")
                } footer: {
                    HStack(spacing: 4) {
                        Image(systemName: request.isLocked ? "lock.fill" : "chart.line.uptrend.xyaxis")
                        Text(request.isLocked
                             ? String(localized: "Pricing at your locked index of \(String(format: "%.2f", request.marketIndex)).", comment: "Order sheet, price locked")
                             : String(localized: "Pricing at today's market index of \(String(format: "%.2f", request.marketIndex)).", comment: "Order sheet, spot price"))
                    }
                    .font(.caption)
                }

                Section {
                    ForEach(request.vendors) { vendor in
                        vendorRow(vendor)
                    }
                } header: {
                    Text(scenario.suppliersName)
                } footer: {
                    Text("People with nothing to work on still draw full pay. A slow supplier can cost more in idle wages than it saves on price.", comment: "Order sheet explanation")
                        .font(.caption)
                }
            }
            .navigationTitle(request.inputName ?? String(localized: "\(scenario.supplyOrderVerb) for \(request.packageTitle)", comment: "Material order sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func vendorRow(_ vendor: Vendor) -> some View {
        let total = unitPrice(vendor) * quantity
        let days = leadTime(vendor)
        let affordable = total <= spendingPower
        return Button {
            onOrder(vendor, quantity)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(vendor.name).font(.headline)
                    Spacer()
                    Text(total, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .font(.subheadline.monospacedDigit().bold())
                }
                Text(vendor.pitch)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Label(String(localized: "\(Int(days)) days", comment: "Vendor lead time"), systemImage: "clock")
                        .foregroundStyle(days > request.baseLeadTimeDays * 1.2 ? .orange : .secondary)
                    Label(vendor.reliabilityLabel, systemImage: "checkmark.shield")
                        .foregroundStyle(vendor.unreliability > 0.15 ? .orange : .secondary)
                    Label(String(localized: "\(unitPrice(vendor), format: .currency(code: currencyCode).precision(.fractionLength(0))) per unit", comment: "Vendor unit price"),
                          systemImage: "tag")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)

                if !affordable {
                    Label(String(localized: "More than you can cover", comment: "Order unaffordable warning"),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
        .opacity(affordable ? 1 : 0.55)
    }
}

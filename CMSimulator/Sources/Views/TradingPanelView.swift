//
//  TradingPanelView.swift
//  CMSimulator
//
//  The trading desk, for a business that buys goods to resell.
//
//  Its controls are its own: what to list at, what to spend on visibility,
//  and how much stock to commit to. None of that exists in the other
//  scenarios, and none of their controls exist here - a trader has no
//  crew to send on overtime and no round to raise.
//
//  The panel is deliberately blunt about where the money goes. The whole
//  reason this scenario exists is that "buy for eleven, sell for
//  thirty-four" sounds like a business until you count the referral fee,
//  the fulfilment fee, the storage, the returns and the advertising.
//

import SwiftUI

struct TradingPanelView: View {
    let trading: TradingModel
    let elapsedDays: Double
    let seasonEstimate: (peakDay: Double, confidence: Double)?
    let dailyBurn: Double
    let onSetPrice: (Double) -> Void
    let onSetAdSpend: (Double) -> Void
    let onBuyStock: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    private var money: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode).precision(.fractionLength(0))
    }
    private var cents: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode).precision(.fractionLength(2))
    }

    var body: some View {
        VStack(spacing: 12) {
            if !trading.isTrading { preTradingCard }
            stockCard
            if trading.isTrading {
                marginCard
                pricingCard
            }
        }
    }

    // MARK: Pre-trading

    private var preTradingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Not listed yet", comment: "Trading panel: pre-launch title"),
                  systemImage: "storefront")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Finish the first product line to go on sale. Stock ordered before then still has to be paid for, shipped and stored — it just cannot sell.", comment: "Trading panel: pre-launch explanation")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Stock

    private var stockCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Units on hand", comment: "Trading panel stat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(Int(trading.unitsOnHand).formatted())
                        .font(.title.bold().monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Tied up in stock", comment: "Trading panel stat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(trading.inventoryValueAtCost, format: money)
                        .font(.title3.bold().monospacedDigit())
                }
            }

            let aged = trading.agedUnits(on: elapsedDays)
            if aged > 1 {
                Label(String(localized: "\(Int(aged).formatted()) units are old enough to be charged a penalty storage rate.", comment: "Trading panel: aged stock warning"),
                      systemImage: "clock.badge.exclamationmark")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let cover = trading.daysOfCover {
                Text(String(localized: "About \(Int(cover)) days of cover at the current rate.", comment: "Trading panel: days of cover"))
                    .font(.caption2).foregroundStyle(cover < 12 ? .orange : .secondary)
            }

            if let estimate = seasonEstimate {
                Label(estimate.confidence > 0.6
                      ? String(localized: "Demand looks like it peaks around day \(Int(estimate.peakDay)).", comment: "Trading panel: sharp season forecast")
                      : String(localized: "Demand might peak somewhere near day \(Int(estimate.peakDay)) — this is a rough guess.", comment: "Trading panel: vague season forecast"),
                      systemImage: "chart.bar.xaxis")
                    .font(.caption2)
                    .foregroundStyle(estimate.confidence > 0.6 ? Color.accentColor : .orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Label(String(localized: "You have no read on the season. Staff Demand planning or buy blind.", comment: "Trading panel: no forecast"),
                      systemImage: "eye.slash")
                    .font(.caption2).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onBuyStock) {
                Label(String(localized: "Buy stock", comment: "Button: purchase inventory"), systemImage: "shippingbox")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Where the money goes

    private var marginCard: some View {
        let avgCost = trading.unitsOnHand > 0
            ? trading.inventoryValueAtCost / trading.unitsOnHand : 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("What one sale actually earns", comment: "Trading panel section")
                .font(.headline)

            row(String(localized: "You list at", comment: "Margin line"), trading.listPrice, tint: .green, bold: true)
            row(String(localized: "Marketplace referral fee", comment: "Margin line"),
                -trading.listPrice * trading.spec.referralFeeRate)
            row(String(localized: "Pick, pack and ship", comment: "Margin line"),
                -trading.spec.fulfilmentFeePerUnit)
            row(String(localized: "What the goods cost you", comment: "Margin line"), -avgCost)
            Divider()
            row(String(localized: "Left before storage, ads and returns", comment: "Margin line"),
                trading.contributionPerUnit,
                tint: trading.contributionPerUnit > 0 ? .green : .red, bold: true)

            Text(String(localized: "Returns are running at \(trading.spec.baseReturnRate + trading.averageDefectRate, format: .percent.precision(.fractionLength(0))), and each one costs the refund and the shipping again.", comment: "Trading panel: returns explanation"))
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundStyle(trading.rating > 0.6 ? .yellow : .red)
                Text(String(localized: "Rating \(trading.rating, format: .percent.precision(.fractionLength(0))) — a poor one throttles every future sale.", comment: "Trading panel: rating"))
                    .font(.caption2)
                    .foregroundStyle(trading.rating > 0.6 ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Controls

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("List price", comment: "Trading control")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(trading.listPrice, format: cents)
                        .font(.headline.monospacedDigit())
                }
                Slider(value: Binding(get: { trading.listPrice }, set: onSetPrice),
                       in: 18...52, step: 0.5)
                Text(String(localized: "Shoppers expect about \(trading.spec.referencePrice, format: money). Undercut and you shift more units on a thinner margin; charge more and volume falls away.", comment: "Trading control: price explanation"))
                    .font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Advertising", comment: "Trading control")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(trading.dailyAdSpend, format: money)
                        .font(.headline.monospacedDigit())
                    Text("/day", comment: "Per day suffix")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Slider(value: Binding(get: { trading.dailyAdSpend }, set: onSetAdSpend),
                       in: 0...25_000, step: 250)
                Text(String(localized: "Buys visibility at roughly \(trading.spec.adCostPerIncrementalUnit, format: cents) per extra unit sold. On a crowded marketplace, nobody finds you without it.", comment: "Trading control: advertising explanation"))
                    .font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func row(_ label: String, _ amount: Double, tint: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(bold ? .subheadline.bold() : .subheadline)
            Spacer()
            Text(amount, format: cents)
                .font((bold ? Font.subheadline.bold() : Font.subheadline).monospacedDigit())
                .foregroundStyle(tint == .primary && amount < 0 ? .secondary : tint)
        }
    }
}

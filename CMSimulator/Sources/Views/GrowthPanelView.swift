//
//  GrowthPanelView.swift
//  CMSimulator
//
//  The business, for scenarios that have customers.
//
//  This is where a startup run is actually won or lost, so it gets its own
//  board rather than being buried: whether you have launched, how many
//  customers you have, what they are worth against what they cost to
//  serve, how fast you are growing, and what an acquirer would pay today.
//

import SwiftUI

struct GrowthPanelView: View {
    let growth: GrowthModel
    let techDebt: Double
    let dailyBurn: Double
    let elapsedDays: Double
    let venture: VentureKind?
    let angels: [AngelProspect]
    let isSearchingForAngels: Bool
    let founderEquity: Double
    let capitalRaised: Double
    let onSetSpend: (Double) -> Void
    let onStartAngelSearch: () -> Void
    let onStopAngelSearch: () -> Void
    let onAcceptAngel: (AngelProspect.ID) -> Void
    let onDeclineAngel: (AngelProspect.ID) -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    private var money: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode).precision(.fractionLength(0))
    }

    /// Revenue against everything going out. Reaching parity is the moment
    /// a startup stops being a countdown.
    private var isDefaultAlive: Bool { growth.dailyRevenue > 0 && growth.dailyRevenue >= dailyBurn }

    var body: some View {
        VStack(spacing: 12) {
            ventureCard
            if !growth.isLaunched {
                preLaunchCard
            } else {
                tractionCard
                unitEconomicsCard
                valuationCard
            }
            spendCard
            fundingCard
        }
    }

    // MARK: What Discovery found

    @ViewBuilder
    private var ventureCard: some View {
        if let venture {
            VStack(alignment: .leading, spacing: 8) {
                Label(venture.name, systemImage: "scope")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                Text(venture.finding)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label(venture.hazard, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                Text(String(localized: "Needs: \(venture.valuedRoles.map(\.name).sorted().formatted(.list(type: .and)))", comment: "Roles the venture values"))
                    .font(.caption2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text("People in those roles work at a premium here. Everyone else you hired is a specialist doing generalist work.", comment: "Role fit explanation")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Label(String(localized: "You do not know what you are building yet", comment: "Pre-discovery title"),
                      systemImage: "questionmark.circle")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("Finish Discovery to establish what this company is. Until then every specialist you hire is a bet on an answer you have not got.", comment: "Pre-discovery explanation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: Raising

    private var fundingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Raising", comment: "Funding section header").font(.headline)
                Spacer()
                Text(String(localized: "You own \(founderEquity, format: .percent.precision(.fractionLength(0)))", comment: "Founder equity"))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(founderEquity < 0.4 ? .orange : .primary)
            }
            if capitalRaised > 0 {
                Text(String(localized: "\(capitalRaised, format: .currency(code: currencyCode).precision(.fractionLength(0))) raised so far — none of it is revenue.", comment: "Capital raised note"))
                    .font(.caption2).foregroundStyle(.secondary)
            }

            ForEach(angels) { angel in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(angel.name).font(.subheadline.bold())
                        if angel.isMarquee {
                            Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                        }
                        Spacer()
                        Text(angel.amount, format: money).font(.subheadline.monospacedDigit())
                    }
                    Text(String(localized: "\(angel.dilution, format: .percent.precision(.fractionLength(1))) of the company · \(Int(angel.daysOpen)) days to decide", comment: "Angel terms"))
                        .font(.caption2).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button(String(localized: "Take it", comment: "Accept angel button")) { onAcceptAngel(angel.id) }
                            .buttonStyle(.borderedProminent)
                        Button(String(localized: "Pass", comment: "Decline angel button")) { onDeclineAngel(angel.id) }
                            .buttonStyle(.bordered)
                    }
                    .controlSize(.small)
                }
                .padding(10)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            }

            Button(action: isSearchingForAngels ? onStopAngelSearch : onStartAngelSearch) {
                Label(isSearchingForAngels
                      ? String(localized: "Stop raising", comment: "Stop angel search")
                      : String(localized: "Go and raise", comment: "Start angel search"),
                      systemImage: isSearchingForAngels ? "stop.circle" : "magnifyingglass")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isSearchingForAngels ? .secondary : .accentColor)
            .controlSize(.small)

            Text(isSearchingForAngels
                 ? String(localized: "Out pitching. Introductions take weeks and most go nowhere — traction and a communications team both shorten it.", comment: "Angel search active")
                 : String(localized: "Angels are found, not summoned. Raising costs a retainer and the weeks you spend doing it.", comment: "Angel search idle"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Pre-launch

    private var preLaunchCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Not launched yet", comment: "Growth panel: pre-launch title"),
                  systemImage: "shippingbox.and.arrow.backward")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Finish MVP & launch to put the product in front of people. Until then you have no customers and no revenue — only burn.", comment: "Growth panel: pre-launch explanation")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Label(String(localized: "Word of mouth compounds off the customers you already have, so every day before launch is growth you never get back.", comment: "Growth panel: why launching early matters"),
                  systemImage: "lightbulb")
                .font(.caption2)
                .foregroundStyle(Color.accentColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Traction

    private var tractionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Customers", comment: "Growth panel stat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(Int(growth.customers).formatted())
                        .font(.title.bold().monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Growth, 14 days", comment: "Growth panel stat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(growth.growthRate, format: .percent.precision(.fractionLength(0)))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(growth.growthRate > 0.02 ? .green : .orange)
                }
            }

            sparkline

            if let launchDay = growth.launchDay {
                Text(String(localized: "Launched on day \(Int(launchDay)) · \(Int(elapsedDays - launchDay)) days of growth so far", comment: "Growth panel: launch summary"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var sparkline: some View {
        GeometryReader { geo in
            let samples = growth.history.suffix(60)
            let hi = max(samples.max() ?? 1, 1)
            Path { path in
                for (i, value) in samples.enumerated() {
                    let x = samples.count > 1
                        ? geo.size.width * Double(i) / Double(samples.count - 1) : 0
                    let y = geo.size.height * (1 - value / hi)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 34)
        .accessibilityHidden(true)
    }

    // MARK: Unit economics

    private var unitEconomicsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit economics", comment: "Growth panel section")
                .font(.headline)

            row(String(localized: "Revenue per customer", comment: "Unit economics line"),
                growth.revenuePerCustomerPerDay * 30, suffix: String(localized: "/mo", comment: "Per month suffix"))
            row(String(localized: "Cost to serve", comment: "Unit economics line"),
                -growth.costToServePerCustomerPerDay * 30, suffix: String(localized: "/mo", comment: "Per month suffix"))
            row(String(localized: "Margin per customer", comment: "Unit economics line"),
                growth.contributionPerCustomerPerDay * 30,
                suffix: String(localized: "/mo", comment: "Per month suffix"),
                tint: growth.contributionPerCustomerPerDay > 0 ? .green : .red, bold: true)

            Divider()

            row(String(localized: "Revenue", comment: "Unit economics line"), growth.dailyRevenue,
                suffix: String(localized: "/day", comment: "Per day suffix"), tint: .green)
            row(String(localized: "Everything going out", comment: "Unit economics line"), -dailyBurn,
                suffix: String(localized: "/day", comment: "Per day suffix"))

            HStack(spacing: 6) {
                Image(systemName: isDefaultAlive ? "checkmark.seal.fill" : "hourglass")
                    .foregroundStyle(isDefaultAlive ? .green : .orange)
                Text(isDefaultAlive
                     ? String(localized: "Default alive — revenue covers the burn.", comment: "Sustainability state")
                     : String(localized: "Default dead — still burning more than you earn.", comment: "Sustainability state"))
                    .font(.caption.bold())
                    .foregroundStyle(isDefaultAlive ? .green : .orange)
            }
            .padding(.top, 2)

            Text(String(localized: "Acquiring a customer costs \(growth.currentAcquisitionCost, format: money) today, and gets dearer as the obvious ones run out.", comment: "Acquisition cost explanation"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Valuation

    private var valuationCard: some View {
        let offer = growth.exitValuation(openTechDebt: techDebt)
        return VStack(alignment: .leading, spacing: 8) {
            Text("What you would sell for today", comment: "Growth panel section")
                .font(.headline)

            row(String(localized: "Annual recurring revenue", comment: "Valuation line"), offer.annualRecurringRevenue)
            HStack {
                Text(String(localized: "Multiple", comment: "Valuation line")).font(.subheadline)
                Spacer()
                Text(String(format: "%.1f×", offer.multiple))
                    .font(.subheadline.monospacedDigit())
            }
            row(String(localized: "Headline valuation", comment: "Valuation line"), offer.headlineValuation, bold: true)
            if offer.diligenceHaircut > 0 {
                row(String(localized: "Diligence haircut, tech debt", comment: "Valuation line"),
                    -offer.diligenceHaircut, tint: .red)
            }
            Divider()
            row(String(localized: "Company value", comment: "Valuation line"), offer.netValuation, bold: true)

            Text("Growth rate drives the multiple. Tech debt you never paid down comes off the price at the end.", comment: "Valuation explanation")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Spend

    private var spendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Acquisition spend", comment: "Growth panel section")
                    .font(.headline)
                Spacer()
                Text(growth.dailyGrowthSpend, format: money)
                    .font(.headline.monospacedDigit())
                Text("/day", comment: "Per day suffix")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Slider(value: Binding(get: { growth.dailyGrowthSpend }, set: onSetSpend),
                   in: 0...40_000, step: 500)
                .disabled(!growth.isLaunched)

            Text(growth.isLaunched
                 ? String(localized: "Buys roughly \(String(format: "%.1f", growth.currentAcquisitionCost > 0 ? growth.dailyGrowthSpend / growth.currentAcquisitionCost : 0)) customers a day at today's price.", comment: "Acquisition spend effect")
                 : String(localized: "Nothing to promote until the product is live.", comment: "Acquisition spend disabled"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Helpers

    private func row(_ label: String, _ amount: Double, suffix: String = "",
                     tint: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(bold ? .subheadline.bold() : .subheadline)
            Spacer()
            Text(amount, format: money)
                .font((bold ? Font.subheadline.bold() : Font.subheadline).monospacedDigit())
                .foregroundStyle(tint == .primary && amount < 0 ? .secondary : tint)
            if !suffix.isEmpty {
                Text(suffix).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

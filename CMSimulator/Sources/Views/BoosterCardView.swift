//
//  BoosterCardView.swift
//  CMSimulator
//

import SwiftUI

struct BoosterCardView: View {
    let booster: Booster
    let onBuy: () -> Void
    let onSell: () -> Void

    @AppStorage(AppSettings.currencyCodeKey) private var currencyCode: String = AppSettings.defaultCurrencyCode

    var body: some View {
        HStack(spacing: 10) {
            Image(bundleResource: booster.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(booster.title).font(.subheadline.bold())
                Text(booster.affects)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(booster.cost, format: .currency(code: currencyCode))
                    .font(.caption2.monospacedDigit())
            }

            Spacer(minLength: 4)

            VStack(spacing: 6) {
                Button(action: onBuy) {
                    Image(systemName: "plus.circle.fill")
                }
                Text("\(booster.purchasedCount)")
                    .font(.caption2.monospacedDigit())
                Button(action: onSell) {
                    Image(systemName: "minus.circle.fill")
                }
                .disabled(booster.purchasedCount == 0)
            }
            .font(.title3)
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .opacity(booster.isUnlocked ? 1 : 0.35)
        .disabled(!booster.isUnlocked)
    }
}

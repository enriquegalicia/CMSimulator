//
//  WorkPackageCardView.swift
//  CMSimulator
//

import SwiftUI

struct WorkPackageCardView: View {
    let package: WorkPackage

    var body: some View {
        HStack(spacing: 10) {
            Image(bundleResource: package.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(package.title).font(.subheadline.bold())
                ProgressView(value: package.progress)
                HStack {
                    Text(package.cost, format: .currency(code: "USD"))
                    Spacer()
                    Text("Rate \(package.rate, specifier: "%.2f")")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .opacity(package.isUnlocked ? 1 : 0.35)
    }
}

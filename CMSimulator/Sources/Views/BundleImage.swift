//
//  BundleImage.swift
//  CMSimulator
//
//  The art (Design.jpeg, Planning.jpeg, etc.) ships as loose bundle
//  resources rather than an asset catalog, same as the original app.
//  SwiftUI's Image(_:) only looks in asset catalogs, so this bridges
//  through UIImage(named:), which finds loose bundle files too.
//

import SwiftUI

extension Image {
    init(bundleResource name: String) {
        if let uiImage = UIImage(named: name) {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: "photo")
        }
    }
}

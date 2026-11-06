//
//  Theme.swift
//  CMSimulator
//
//  Critical Path's own look, added for build 3 (2026-10-15).
//
//  Builds 1 and 2 used stock iOS everywhere: system blue, grouped lists,
//  a segmented control, white in light mode. App Review twice read the app
//  as template output (guidelines 4.3 / 4.2.6), and the plain settings-form
//  look was part of that. The game now has the face of its own subject: a
//  night-shift planning table. Slate blueprint paper with a faint drafting
//  grid, chalk-white ink, and one signal-lime colour reserved for the
//  critical path, the same lime and slate as the icon and the App Store
//  art. Amber is money going out; red is the deadline and losses.
//

import SwiftUI

enum CP {
    /// Page background, bottom of the gradient.
    static let night = Color(rgb: 0x10161F)
    /// Page background, top. The icon's background.
    static let slate = Color(rgb: 0x16202C)
    static let panel = Color(rgb: 0x1C2734)
    static let panelHigh = Color(rgb: 0x253244)
    /// Hairlines and the drafting grid.
    static let rule = Color(rgb: 0x34465C)
    static let ink = Color(rgb: 0xEAF0F6)
    static let inkSoft = Color(rgb: 0xA3B3C6)
    static let inkFaint = Color(rgb: 0x6E8299)
    /// The critical path. Also the app's accent (AccentColor asset).
    static let lime = Color(rgb: 0x7CFF5B)
    /// Text on lime.
    static let onLime = Color(rgb: 0x0D1A08)
    /// Money going out.
    static let amber = Color(rgb: 0xFFB547)
    /// Deadline, losses.
    static let late = Color(rgb: 0xFF6B5E)
    /// Streams with float: not on the critical path.
    static let steel = Color(rgb: 0x7F9BBF)
}

extension Color {
    init(rgb: UInt32) {
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Slate drafting paper: a soft top-to-bottom gradient under a fine grid,
/// with every fourth line a little heavier, like a planning sheet.
struct BlueprintBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [CP.slate, CP.night], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                let step: CGFloat = 22
                var minor = Path()
                var major = Path()
                var index = 0
                var x: CGFloat = 0
                while x <= size.width {
                    if index % 4 == 0 { major.addRect(CGRect(x: x, y: 0, width: 0.8, height: size.height)) }
                    else { minor.addRect(CGRect(x: x, y: 0, width: 0.5, height: size.height)) }
                    x += step
                    index += 1
                }
                index = 0
                var y: CGFloat = 0
                while y <= size.height {
                    if index % 4 == 0 { major.addRect(CGRect(x: 0, y: y, width: size.width, height: 0.8)) }
                    else { minor.addRect(CGRect(x: 0, y: y, width: size.width, height: 0.5)) }
                    y += step
                    index += 1
                }
                context.fill(minor, with: .color(CP.rule.opacity(0.22)))
                context.fill(major, with: .color(CP.rule.opacity(0.42)))
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// The board's panel: slate glass with a hairline edge.
    func cpPanel(cornerRadius: CGFloat = 14) -> some View {
        background(CP.panel.opacity(0.88), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(CP.rule.opacity(0.7), lineWidth: 0.75))
    }

    /// A prominent button in the app's lime, with dark ink so it reads.
    func cpProminent() -> some View {
        buttonStyle(.borderedProminent).foregroundStyle(CP.onLime)
    }

    /// Sheets and lists sit on the same drafting paper as the board.
    func cpSheetBackground() -> some View {
        scrollContentBackground(.hidden).background(BlueprintBackground())
    }
}

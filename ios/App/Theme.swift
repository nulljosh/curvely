// Colors from src/tokens.css. Each one follows the system light/dark setting.

import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

enum Theme {
    static let graphBackground = adaptive(light: (0.984, 0.984, 0.992, 1), dark: (0.051, 0.047, 0.043, 1)) // #fbfbfd / #0d0c0b
    static let panel = adaptive(light: (0.961, 0.961, 0.969, 1), dark: (0.078, 0.075, 0.071, 1))
    static let grid = adaptive(light: (0, 0, 0, 0.07), dark: (0.910, 0.910, 0.941, 0.07))
    static let axis = adaptive(light: (0, 0, 0, 0.35), dark: (0.910, 0.910, 0.941, 0.30))
    static let axisLabel = adaptive(light: (0, 0, 0, 0.55), dark: (0.910, 0.910, 0.941, 0.50))
    static let text = adaptive(light: (0.114, 0.114, 0.122, 1), dark: (0.910, 0.910, 0.941, 1))
    static let secondary = adaptive(light: (0.114, 0.114, 0.122, 0.58), dark: (0.910, 0.910, 0.941, 0.55))
    static let border = adaptive(light: (0, 0, 0, 0.12), dark: (0.910, 0.910, 0.941, 0.14))
    static let fill = adaptive(light: (0, 0, 0, 0.05), dark: (1, 1, 1, 0.07))
    static let accent = Color(hex: "0f86c9")  // brand/tokens.css
    static let accentText = adaptive(light: (0.039, 0.435, 0.659, 1), dark: (0.310, 0.702, 0.918, 1)) // #0a6fa8 / #4fb3ea
    static let error = Color(hex: "ff453a")

    typealias RGBA = (Double, Double, Double, Double)

    private static func adaptive(light: RGBA, dark: RGBA) -> Color {
        #if canImport(UIKit)
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: dark.0, green: dark.1, blue: dark.2, alpha: dark.3)
            : UIColor(red: light.0, green: light.1, blue: light.2, alpha: light.3) })
        #else
        Color(NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: dark.0, green: dark.1, blue: dark.2, alpha: dark.3)
            : NSColor(red: light.0, green: light.1, blue: light.2, alpha: light.3) })
        #endif
    }
}

extension Theme {
    /// Curvely Sans (Inter, renamed, brand/fonts), bundled in App/Fonts. Falls back to the system face if it fails to load.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(weight == .regular ? "CurvelySans-Regular" : weight == .semibold ? "CurvelySans-Semibold" : "CurvelySans-Medium", size: size)
    }
}

extension View {
    /// Liquid Glass on iOS 26 and macOS 26, a blurred material before that. One call site for every floating pane.
    @ViewBuilder
    func curvelyGlass<S: InsettableShape>(in shape: S) -> some View {
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Theme.border, lineWidth: 1))
        }
    }
}

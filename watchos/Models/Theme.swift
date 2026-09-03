// Subset of ios/App/Theme.swift needed to draw a plot. Curvely is dark-mode only, so this
// (like the iOS original) carries just the dark palette.

import SwiftUI

enum Theme {
    static let graphBackground = Color(red: 0.051, green: 0.047, blue: 0.043) // #0d0c0b
    static let grid = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.07)
    static let axis = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.30)
    static let text = Color(red: 0.910, green: 0.910, blue: 0.941)
    static let secondary = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.55)
}

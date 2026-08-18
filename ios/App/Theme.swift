// Colors from src/components/Graph.jsx graphColors(). Curvely is dark-mode only
// (see CLAUDE.md), so only the dark branch is carried over.

import SwiftUI

enum Theme {
    static let graphBackground = Color(red: 0.051, green: 0.047, blue: 0.043) // #0d0c0b
    static let panel = Color(red: 0.078, green: 0.075, blue: 0.071)
    static let grid = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.07)
    static let axis = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.30)
    static let axisLabel = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.50)
    static let text = Color(red: 0.910, green: 0.910, blue: 0.941)
    static let secondary = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.55)
    static let border = Color(red: 0.910, green: 0.910, blue: 0.941, opacity: 0.14)
    static let accent = Color(hex: "0071e3")
    static let error = Color(hex: "ff453a")
}

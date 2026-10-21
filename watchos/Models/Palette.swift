// Curve colors, from src/utils/colors.js. Direct copy of ios/App/Palette.swift.

import SwiftUI

enum Palette {
    static let curveHex = [
        "0074D9", "FF4136", "2ECC40", "FFDC00",
        "FF851B", "3D9970", "AAAAAA", "001f3f",
    ]

    static func hex(at index: Int) -> String {
        curveHex[((index % curveHex.count) + curveHex.count) % curveHex.count]
    }

    static func color(at index: Int) -> Color {
        Color(hex: hex(at: index))
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

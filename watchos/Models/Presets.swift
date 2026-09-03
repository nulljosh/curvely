// The watch has no practical way to type an equation (see Expression.swift's header), so
// instead of a fake pairing/sync screen it pages through a fixed set of curves — the same
// ones ios/App/Equation.swift offers as "quick examples" — each compiled and plotted by the
// real parser in Expression.swift.

import SwiftUI

struct PresetCurve: Identifiable {
    let id: String
    let source: String
    let colorIndex: Int
    let compiled: CompiledExpression

    init(_ source: String, colorIndex: Int) {
        self.id = source
        self.source = source
        self.colorIndex = colorIndex
        self.compiled = compileExpression(source)
    }

    var color: Color { Palette.color(at: colorIndex) }
}

/// Mirrors ios/App/Equation.swift's `quickExamples`, trimmed to the six that read well on a
/// small screen at a fixed scale (drops `tan(x)` and `1/x`: both are dominated by asymptote
/// blowups at this zoom level and read as a near-blank plot rather than a recognizable curve).
let presetCurves: [PresetCurve] = [
    PresetCurve("x^2", colorIndex: 0),
    PresetCurve("sin(x)", colorIndex: 1),
    PresetCurve("cos(x)", colorIndex: 2),
    PresetCurve("2*x+1", colorIndex: 3),
    PresetCurve("sqrt(abs(x))", colorIndex: 4),
    PresetCurve("x^3-x", colorIndex: 5),
]

// One row of the equation list: the text the user typed, its compiled form, and its color.

import SwiftUI

struct Equation: Identifiable {
    let id: UUID
    var source: String
    var colorIndex: Int
    var hidden = false
    /// Set on the copies a list row draws, `L` -> one element. Never persisted.
    var bindings: [String: Double] = [:]
    private(set) var compiled: CompiledExpression

    init(id: UUID = UUID(), source: String, colorIndex: Int) {
        self.id = id
        self.source = source
        self.colorIndex = colorIndex
        self.compiled = compileRow(source)
    }

    var color: Color { Palette.color(at: colorIndex) }
    var error: String? { compiled.error }

    mutating func update(source newSource: String) {
        source = newSource
        compiled = compileRow(newSource)
    }
}

/// A list definition is fine as is; a row holding list literals is checked in its rewritten
/// form, which is what actually gets drawn. Mirrors evaluateRow in src/utils/lists.js.
func compileRow(_ source: String) -> CompiledExpression {
    if parseListDef(source) != nil { return CompiledExpression(function: nil, implicitFunction: nil, error: nil) }
    return compileExpression(expandRow(source, lists: [:]).source)
}

/// The two curves the web app opens with (src/App.jsx INITIAL).
let defaultEquations: [Equation] = [
    Equation(source: "x^2", colorIndex: 0),
    Equation(source: "sin(x)", colorIndex: 1),
]

let quickExamples = ["x^2", "sin(x)", "x^3-x", "x^2+y^2=4", "y > x^2", "r = 1+cos(theta)", "(cos(t), sin(t))", "(1, 2)"]

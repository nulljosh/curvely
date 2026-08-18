// One row of the equation list: the text the user typed, its compiled form, and its color.

import SwiftUI

struct Equation: Identifiable {
    let id: UUID
    var source: String
    var colorIndex: Int
    private(set) var compiled: CompiledExpression

    init(id: UUID = UUID(), source: String, colorIndex: Int) {
        self.id = id
        self.source = source
        self.colorIndex = colorIndex
        self.compiled = compileExpression(source)
    }

    var color: Color { Palette.color(at: colorIndex) }
    var error: String? { compiled.error }

    mutating func update(source newSource: String) {
        source = newSource
        compiled = compileExpression(newSource)
    }
}

/// The two curves the web app opens with (src/App.jsx INITIAL).
let defaultEquations: [Equation] = [
    Equation(source: "x^2", colorIndex: 0),
    Equation(source: "sin(x)", colorIndex: 1),
]

let quickExamples = ["x^2", "sin(x)", "cos(x)", "2*x+1", "sqrt(abs(x))", "tan(x)", "1/x", "x^3-x"]

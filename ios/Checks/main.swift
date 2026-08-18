// Expression + palette self-check. Ports src/utils/evaluate.test.js and colors.test.js,
// plus the parser cases the JS suite never needed because mathjs handled them.
//
// Run with no build system, no framework:
//   swiftc -o /tmp/curvecheck ios/App/Expression.swift ios/App/Palette.swift ios/Checks/main.swift && /tmp/curvecheck
//
// Palette.swift imports SwiftUI, so this compiles for the host platform (macOS) — fine,
// Color is only constructed, never rendered.

import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    checks += 1
    guard condition() else {
        FileHandle.standardError.write("FAIL: \(label)\n".data(using: .utf8)!)
        exit(1)
    }
}

func near(_ a: Double, _ b: Double, _ tolerance: Double = 1e-9) -> Bool {
    abs(a - b) < tolerance
}

/// Evaluate, asserting the expression compiled.
func f(_ source: String, _ x: Double) -> Double {
    guard let fn = compileExpression(source).function else {
        FileHandle.standardError.write("FAIL: \(source) did not compile\n".data(using: .utf8)!)
        exit(1)
    }
    return fn(x)
}

// MARK: - evaluate.test.js

let empty = compileExpression("")
check(empty.function == nil && empty.error == nil, "empty string is neither a function nor an error")

let blank = compileExpression("   ")
check(blank.function == nil && blank.error == nil, "whitespace-only input is not an error")

check(compileExpression("y = x").error == nil, "y = prefix compiles")
check(near(f("y = x", 3), 3), "strips the y = prefix")
check(near(f("y=x", 5), 5), "strips y= without spaces")
check(near(f("Y = x", 5), 5), "prefix strip is case-insensitive")

check(compileExpression("x^2").error == nil, "quadratic compiles")
check(near(f("x^2", 3), 9), "x^2 at 3")
check(near(f("x^2", -2), 4), "x^2 at -2")

check(near(f("2*x + 1", 0), 1), "linear at 0")
check(near(f("2*x + 1", 4), 9), "linear at 4")

check(near(f("42", 0), 42), "constant ignores x")
check(near(f("42", 999), 42), "constant is constant")

let invalid = compileExpression("!!invalid")
check(invalid.function == nil, "invalid expression has no function")
check((invalid.error?.count ?? 0) > 0, "invalid expression reports a non-empty error")

// MARK: - isAsymptoteJump

let scale = 60.0, height = 700.0

let tanBefore = f("tan(x)", Double.pi / 2 - 0.001)
let tanAfter = f("tan(x)", Double.pi / 2 + 0.001)
check(tanBefore.isFinite && tanAfter.isFinite, "tan either side of pi/2 is finite")
check(isAsymptoteJump(previous: tanBefore, current: tanAfter, scale: scale, height: height),
      "breaks the stroke across a tan(x) asymptote")
check(isAsymptoteJump(previous: f("1/x", -0.001), current: f("1/x", 0.001), scale: scale, height: height),
      "breaks the stroke across the 1/x pole")
check(!isAsymptoteJump(previous: f("x^3", 4), current: f("x^3", 4.02), scale: scale, height: height),
      "keeps a steep but continuous curve joined")
check(!isAsymptoteJump(previous: f("sin(x)", -0.01), current: f("sin(x)", 0.01), scale: scale, height: height),
      "keeps an ordinary zero crossing joined")

// MARK: - Grammar the JS suite delegated to mathjs

check(near(f("1+2*3", 0), 7), "multiplication binds tighter than addition")
check(near(f("(1+2)*3", 0), 9), "parentheses override precedence")
check(near(f("2^3^2", 0), 512), "exponentiation is right associative")
check(near(f("-x^2", 3), -9), "unary minus applies to the power, not the base")
check(near(f("-3", 0), -3), "leading unary minus")
check(near(f("10-2-3", 0), 5), "subtraction is left associative")
check(near(f("100/5/2", 0), 10), "division is left associative")
check(near(f("2x", 4), 8), "implicit multiplication: 2x")
check(near(f("2(x+1)", 3), 8), "implicit multiplication before a parenthesis")
check(near(f("3sin(0)", 0), 0), "implicit multiplication before a function")
// The one deliberate divergence from mathjs, verified against it over 3,636 sample points:
// mathjs rejects `x(x+1)` as "x is not a function", this reads it as multiplication. That is
// strictly more permissive, so nothing that graphs on the web fails here.
check(near(f("x(x+1)", 2), 6), "implicit multiplication after a variable (mathjs errors here)")

check(near(f("sqrt(abs(x))", -16), 4), "nested calls")
check(near(f("abs(-x)", 5), 5), "unary minus inside a call")
check(near(f("2.5*x", 2), 5), "decimal literals")
check(near(f(".5*x", 4), 2), "leading-dot decimal")

check(near(f("pi", 0), Double.pi), "pi constant")
check(near(f("e", 0), M_E), "e constant")
check(near(f("log(e)", 0), 1), "log is the natural logarithm, matching mathjs")
check(near(f("ln(e)", 0), 1), "ln is available too")
check(near(f("log10(100)", 0), 2), "log10 is base 10")
check(near(f("SIN(0)", 0), 0), "function names are case-insensitive")

check(!f("1/x", 0).isFinite, "1/0 is not finite, so the renderer lifts the pen")
check(f("sqrt(x)", -1).isNaN, "sqrt of a negative is NaN, not a crash")

// Malformed input must report, never trap.
for bad in ["(", ")", "x+", "*x", "sin", "sin x", "1+", "((x)", "x)", "foo(x)", "@", "3..5"] {
    let result = compileExpression(bad)
    check(result.function == nil, "rejects \(bad)")
    check((result.error?.isEmpty == false), "reports an error for \(bad)")
}

// MARK: - colors.test.js

check(Palette.curveHex.count == 8, "eight curve colors")
check(Palette.hex(at: 0) == "0071e3", "first color matches the web palette")
check(Palette.hex(at: 8) == Palette.hex(at: 0), "palette wraps")
check(Palette.hex(at: 9) == Palette.hex(at: 1), "palette wraps by modulo")
check(Palette.hex(at: -1) == Palette.hex(at: 7), "negative indices wrap instead of trapping")
check(Set(Palette.curveHex).count == 8, "colors are distinct")

print("ok — \(checks) checks passed")

// Expression + palette self-check. Ports src/utils/evaluate.test.js and colors.test.js,
// plus the parser cases the JS suite never needed because mathjs handled them.
//
// Run with no build system, no framework:
//   swiftc -o /tmp/curvecheck ios/App/Expression.swift ios/App/Palette.swift \
//     ios/App/PNG.swift ios/Checks/main.swift && /tmp/curvecheck
//
// Palette.swift imports SwiftUI, so this compiles for the host platform (macOS) — fine,
// Color is only constructed, never rendered.

import CoreGraphics
import Foundation
import ImageIO

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
    return fn(x, [:])
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

// MARK: - implicit equations

check(isImplicitEquation("x^2 + y^2 = 1"), "circle equation is implicit")
check(isImplicitEquation("x = 3"), "vertical line is implicit")
check(!isImplicitEquation("y = x^2"), "y = prefix is not implicit")
check(!isImplicitEquation("x^2"), "no equals sign is not implicit")

let circle = compileExpression("x^2 + y^2 = 1")
check(circle.error == nil, "circle equation compiles")
check(circle.function == nil, "circle equation has no explicit function")
guard let circleFn = circle.implicitFunction else {
    FileHandle.standardError.write("FAIL: circle did not compile an implicit function\n".data(using: .utf8)!)
    exit(1)
}
check(near(circleFn(0, 1, [:]), 0), "circle satisfied at (0,1)")
check(near(circleFn(0, 0, [:]), -1), "circle residual at origin")

// Points, parametric, polar and sliders, mirroring evaluate.test.js.
check(parseSlider("a = 3")?.value == 3, "a = 3 is a slider")
check(parseSlider("r = 3") == nil && parseSlider("t = 1") == nil, "r and t are never sliders")
check(compileExpression("a = 3").function == nil, "a slider row draws no curve")
if let p = compileExpression("(1, 2)").point?([:]) { check(p == (1, 2), "(1, 2) is a point") } else { check(false, "(1, 2) compiles to a point") }
if let p = compileExpression("(a, a^2)").point?(["a": 3]) { check(p == (3, 9), "a point follows a slider") } else { check(false, "(a, a^2) compiles to a point") }
if let p = compileExpression("(cos(t), sin(t))").parametric?(0, [:]) { check(near(p.0, 1) && near(p.1, 0), "unit circle starts at (1, 0)") } else { check(false, "(cos(t), sin(t)) is parametric") }
if let p = compileExpression("r = 1 + cos(theta)").parametric?(0, [:]) { check(near(p.0, 2), "cardioid starts at (2, 0)") } else { check(false, "r = ... is polar") }
check(splitPair("(x+1)*(x-1)") == nil && splitPair("(max(x, 1))") == nil && splitPair("(1, 2, 3)") == nil, "splitPair ignores products and nested commas")
check(near(f("(x+1)*(x-1)", 2), 3), "(x+1)*(x-1) still graphs as y = f(x)")
check(near(compileExpression("a*x").function?(2, ["a": 3]) ?? .nan, 6), "curves read slider values")

let badImplicit = compileExpression("x^2 =!! y")
check(badImplicit.implicitFunction == nil, "malformed implicit equation has no function")
check((badImplicit.error?.count ?? 0) > 0, "malformed implicit equation reports an error")

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
for bad in ["(", ")", "x+", "*x", "sin", "sin x", "1+", "((x)", "x)", "@", "3..5"] {
    let result = compileExpression(bad)
    check(result.function == nil, "rejects \(bad)")
    check((result.error?.isEmpty == false), "reports an error for \(bad)")
}

// MARK: - colors.test.js

check(Palette.curveHex.count == 8, "eight curve colors")
check(Palette.hex(at: 0) == "0074D9", "first color matches the web palette")
check(Palette.hex(at: 8) == Palette.hex(at: 0), "palette wraps")
check(Palette.hex(at: 9) == Palette.hex(at: 1), "palette wraps by modulo")
check(Palette.hex(at: -1) == Palette.hex(at: 7), "negative indices wrap instead of trapping")
check(Set(Palette.curveHex).count == 8, "colors are distinct")

// MARK: - PNG export
//
// The export path is the one thing that changed when the iOS-only UIActivityViewController
// was removed, so it gets a real check rather than a clean build and a hope.

func makeTestImage(width: Int, height: Int) -> CGImage? {
    let space = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil as UnsafeMutableRawPointer?, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    ctx.setFillColor(red: 0, green: 0.44, blue: 0.89, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return ctx.makeImage()
}

if let image = makeTestImage(width: 8, height: 4), let data = pngData(from: image) {
    check(data.count > 0, "export produces bytes")
    // The PNG magic number. Without this the check would pass on any non-empty Data,
    // which is exactly the kind of test that fails to notice a broken encoder.
    check(Array(data.prefix(8)) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          "export is a real PNG, not just non-empty data")
    // Round-trip it: the bytes have to be decodable back to the same dimensions.
    if let source = CGImageSourceCreateWithData(data as CFData, nil),
       let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil) {
        check(decoded.width == 8 && decoded.height == 4, "exported PNG round-trips at the right size")
    } else {
        check(false, "exported PNG could not be decoded back")
    }
} else {
    check(false, "could not build a test image to export")
}


// MARK: - keypoints.test.js

func hasPoint(_ points: [KeyPoint], _ x: Double, _ y: Double) -> Bool {
    points.contains { abs($0.x - x) < 1e-4 && abs($0.y - y) < 1e-4 }
}
let parabola = keyPoints([({ $0 * $0 - 1 }, 0)], xMin: -5, xMax: 5)
check(parabola.count == 3 && hasPoint(parabola, -1, 0) && hasPoint(parabola, 1, 0) && hasPoint(parabola, 0, -1),
      "x^2 - 1 has two roots and a vertex")
let crossing = keyPoints([({ $0 * $0 }, 0), ({ 2 * $0 }, 1)], xMin: -5, xMax: 5)
check(hasPoint(crossing, 0, 0) && hasPoint(crossing, 2, 4), "x^2 meets 2x at 0 and 2")
check(keyPoints([({ 1 / $0 }, 0)], xMin: -5, xMax: 5).isEmpty, "1/x has no key points")
let tangent = keyPoints([({ tan($0) }, 0)], xMin: -2, xMax: 2)
check(tangent.count == 1 && hasPoint(tangent, 0, 0), "tan keeps its root, drops its asymptotes")


// MARK: - inequalities

let above = compileExpression("y > x^2")
check(above.inequality?.sign == 1 && above.inequality?.strict == true, "y > x^2 is strict, shades above")
check((above.implicitFunction?(0, 1, [:]) ?? 0) > 0, "(0, 1) is inside y > x^2")
let disc = compileExpression("x^2+y^2 <= 4")
check(disc.inequality?.sign == -1 && disc.inequality?.strict == false, "<= shades inside with a solid edge")
check(compileExpression("y >= x").inequality != nil, "y >= x is not an implicit equation")
check(splitInequality("0 < x < 1") == nil, "two comparisons are not an inequality")


// MARK: - functions, derivatives, piecewise, domain limits

let defs = buildVars(["f(x) = x^3", "g(x) = f(x) + 1", "h(x) = h(x)"], values: [:])
check(near(defs.functions["f"]?(2) ?? .nan, 8), "f(x) = x^3 defines f")
check(near(defs.functions["g"]?(2) ?? .nan, 9), "g can call f")
check(defs.functions["h"]?(1).isNaN == true, "h(x) = h(x) is NaN, not a crash")
check(near(compileExpression("f(x) = x^3").function?(2, defs) ?? .nan, 8), "a definition row draws itself")
check(near(compileExpression("f(x + 1)").function?(1, defs) ?? .nan, 8), "another row calls f")
check(abs((compileExpression("f'(x)").function?(2, defs) ?? .nan) - 12) < 1e-4, "f'(x) is the derivative")
check(abs((compileExpression("f''(x)").function?(2, defs) ?? .nan) - 12) < 0.1, "f''(x) is the second derivative")
check(abs((compileExpression("d/dx(sin(x))").function?(0, [:]) ?? .nan) - 1) < 1e-6, "d/dx(sin(x)) at 0 is 1")
let absPiece = compileExpression("{x < 0: -x, x}")
check(absPiece.error == nil && near(absPiece.function?(-3, [:]) ?? .nan, 3) && near(absPiece.function?(2, [:]) ?? .nan, 2), "piecewise abs")
check(compileExpression("{x > 0: 1}").function?(-1, [:]).isNaN == true, "piecewise with no else is NaN outside")
let limited = compileExpression("x^2 {0 < x < 2}")
check(near(limited.function?(1, [:]) ?? .nan, 1) && limited.function?(3, [:]).isNaN == true, "domain limit cuts the curve")
check(!isImplicitEquation("{x <= 0: 1, 2}") && near(compileExpression("{x <= 0: 1, 2}").function?(0, [:]) ?? .nan, 1), "<= inside braces is not an equation")
check(compileExpression("foo(x)").function?(1, [:]).isNaN == true, "an undefined function draws nothing")
check(desugar("sin(x) + 1") == "sin(x) + 1", "desugar leaves plain input alone")


// MARK: - lists.test.js

check(parseListDef("L = [1, 2, 3]")?.items == [1, 2, 3], "L = [1, 2, 3] defines a list")
check(parseListDef("n = [1...5]")?.items == [1, 2, 3, 4, 5], "[1...5] is a range")
check(expandRow("L = [1, 2]", lists: [:]).binds.isEmpty, "a list definition draws nothing")
let squares = expandRow("(L, L^2)", lists: ["l": [1, 2, 3]])
check(squares.binds.count == 3, "(L, L^2) draws one copy per element")
if let point = compileExpression(squares.source).point {
    check(squares.binds.map { point(Vars().with($0)) }.map(\.1) == [1, 4, 9], "each copy is its own point")
} else { check(false, "(L, L^2) compiles to a point") }
let family = expandRow("sin(x) + [0, 1, 2]", lists: [:])
check(family.source == "sin(x) + qlist0" && family.binds.count == 3, "a literal list makes a family of curves")
let pointList = expandRow("[(1, 2), (3, 4)]", lists: [:])
check(pointList.source == "(qlist0, qlist1)" && pointList.binds.count == 2, "a list of points becomes one point row")
check(expandRow("x^2", lists: ["l": [1]]).binds.count == 1, "a row with no list is one plain copy")
check(expandRow("lx + 1", lists: ["l": [1, 2]]).binds == [[:]], "a list name inside a longer word is not a use")


// MARK: - v5 slider bounds and t ranges

check(parseSlider("a = 3")?.range == -10...10, "a = 3 has the default range")
check(parseSlider("a = 40")?.range == -10...40, "the default range widens to fit")
check(parseSlider("a = 3 {0 < a < 5}")?.range == 0...5, "{0 < a < 5} sets the range")
check(parseSlider("a = 3 {0 < a < 5}")?.bounds == "{0 < a < 5}", "the bounds text is kept for rewriting")
check(abs((parseSlider("k = 1 {-pi <= k <= pi}")?.range.upperBound ?? 0) - .pi) < 1e-9, "bounds can be expressions")
check(parseSlider("a = 3 {0 < b < 5}") == nil, "braces about another name are not slider bounds")
let halfCircle = compileExpression("(cos(t), sin(t)) {0 < t < pi}")
check(halfCircle.error == nil && abs(halfCircle.tRange.upperBound - .pi) < 1e-9, "{0 < t < pi} limits a parametric row")
let spiral = compileExpression("r = theta {0 < theta < 6pi}")
check(abs(spiral.tRange.upperBound - 6 * .pi) < 1e-9 && near(spiral.parametric?(4 * .pi, [:]).0 ?? 0, 4 * .pi), "a polar spiral runs past 2 pi")
check(compileExpression("(cos(t), sin(t))").tRange == 0...(2 * .pi), "parametric rows default to 0...2pi")


// MARK: - patterns.test.js

for pattern in patterns {
    let lists = Dictionary(pattern.rows.compactMap(parseListDef), uniquingKeysWith: { a, _ in a })
    let vars = buildVars(pattern.rows, values: Dictionary(pattern.rows.compactMap(parseSlider).map { ($0.name, $0.value) }, uniquingKeysWith: { a, _ in a }))
    var drew = false
    for row in pattern.rows {
        check(compileRow(row).error == nil, "\(pattern.name): \(row) reads")
        let (source, binds) = expandRow(row, lists: lists)
        guard let bind = binds.first else { continue }
        let c = compileExpression(source)
        let v = vars.with(bind)
        let mid = (c.tRange.lowerBound + c.tRange.upperBound) / 2 + 0.1 // same points as patterns.test.js
        let values: [Double]? = c.function.map { [$0(1.1, v)] }
            ?? c.parametric.map { let p = $0(mid, v); return [p.0, p.1] }
            ?? c.point.map { let p = $0(v); return [p.0, p.1] }
            ?? c.implicitFunction.map { [$0(1.1, 0.7, v)] }
        if let values { check(values.allSatisfy(\.isFinite), "\(pattern.name): \(row) is finite"); drew = true }
    }
    check(drew, "\(pattern.name) draws something")
}

print("ok — \(checks) checks passed")

// Row-level syntax on top of the parser in Expression.swift: what kind of row a line of text
// is (slider, function definition, point, parametric, polar, inequality, implicit, plain
// y = f(x)), the Desmos shorthands desugared into plain expressions, and compileExpression,
// the one entry point. Mirrors src/utils/evaluate.js.

import Foundation

// MARK: - Public surface, mirroring src/utils/evaluate.js

struct CompiledExpression {
    /// nil when the input was empty — an empty row is not an error, it just draws nothing.
    let function: ((Double, Vars) -> Double)?
    /// Set instead of `function` for an implicit equation (x^2+y^2=1, x=3, ...): f(x,y) = lhs-rhs,
    /// traced by marching squares rather than walked per pixel. Mirrors src/utils/evaluate.js.
    let implicitFunction: ((Double, Double, Vars) -> Double)?
    /// `(1, 2)` or `(a, a^2)`: one dot.
    var point: ((Vars) -> (Double, Double))? = nil
    /// `(cos(t), sin(t))` or `r = 1 + cos(theta)`, sampled over `tRange`.
    var parametric: ((Double, Vars) -> (Double, Double))? = nil
    /// 0 to 2 pi unless the row ends in `{0 < t < pi}` (or theta).
    var tRange: ClosedRange<Double> = 0...tMax
    /// `y > x^2`: shade where sign * implicitFunction > 0, dashed edge when strict.
    var inequality: (sign: Double, strict: Bool)? = nil
    /// `a = 3`: a slider row, draws nothing itself.
    var slider: SliderDef? = nil
    let error: String?
}

/// Parametric and polar curves run t from 0 to 2 pi, same as the web's T_MAX.
let tMax = Double.pi * 2

private let reservedNames: Set<String> = ["x", "y", "t", "r", "theta"]

struct SliderDef {
    let name: String
    let value: Double
    let range: ClosedRange<Double>
    /// The `{0 < a < 10}` the row was typed with, kept so dragging rewrites only the number.
    let bounds: String?
}

/// `0 < a < 10`, `-pi <= t <= pi`: the numeric bounds around one name, mirroring parseRange.
func parseRange(_ condition: String, name: String) -> ClosedRange<Double>? {
    guard let m = condition.wholeMatch(of: #/(.+?)(<=|<)\s*([a-zA-Z]\w*)\s*(<=|<)(.+)/#),
          String(m.3).lowercased() == name,
          let lo = compileExpression(String(m.1)).function?(0, [:]),
          let hi = compileExpression(String(m.5)).function?(0, [:]),
          lo.isFinite, hi.isFinite, lo < hi else { return nil }
    return lo...hi
}

/// `a = 3` defines a slider, mirroring parseSlider in src/utils/evaluate.js.
/// `a = 3 {0 < a < 10}` also sets its range; without one it is -10 to 10, widened to fit.
func parseSlider(_ raw: String) -> SliderDef? {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    guard let match = trimmed.wholeMatch(of: #/([a-zA-Z]\w*)\s*=\s*(-?\d+(?:\.\d+)?)\s*(?:\{([^{}]*)\})?/#),
          let value = Double(match.2) else { return nil }
    let name = String(match.1).lowercased()
    guard !reservedNames.contains(name) else { return nil }
    if let condition = match.3 {
        guard let range = parseRange(String(condition), name: name) else { return nil }
        return SliderDef(name: name, value: value, range: range, bounds: "{\(condition)}")
    }
    return SliderDef(name: name, value: value, range: min(-10, value)...max(10, value), bounds: nil)
}

/// The row text for a slider at a new value, keeping any `{0 < a < 10}` it was typed with.
func sliderSource(_ slider: SliderDef, value: Double) -> String {
    let number = String(format: "%g", (value * 100).rounded() / 100)
    return "\(slider.name) = \(number)" + (slider.bounds.map { " " + $0 } ?? "")
}

/// A parametric or polar row ending in `{0 < t < pi}` runs t over that range. Other trailing
/// braces stay for desugar(). Mirrors takeTRange.
func takeTRange(_ raw: String) -> (source: String, range: ClosedRange<Double>) {
    guard let m = raw.wholeMatch(of: #/(.+?)\s*\{([^{}:]+)\}/#),
          let range = parseRange(String(m.2), name: "t") ?? parseRange(String(m.2), name: "theta")
    else { return (raw, 0...tMax) }
    return (String(m.1).trimmingCharacters(in: .whitespaces), range)
}

/// `y > x^2`, `x^2+y^2 <= 4`: exactly one comparison, mirroring splitInequality on the web.
func splitInequality(_ raw: String) -> (lhs: String, rhs: String, sign: Double, strict: Bool)? {
    guard !raw.contains("{"), let m = raw.wholeMatch(of: #/([^<>=]+)(<=|>=|<|>)([^<>=]+)/#) else { return nil }
    let op = String(m.2)
    return (String(m.1).trimmingCharacters(in: .whitespaces), String(m.3).trimmingCharacters(in: .whitespaces),
            op.hasPrefix(">") ? 1 : -1, op.count == 1)
}

/// `(a, b)`: the outer parens wrap the whole input and hold exactly one top-level comma.
func splitPair(_ raw: String) -> (String, String)? {
    let s = Array(raw.trimmingCharacters(in: .whitespaces))
    guard s.first == "(", s.last == ")" else { return nil }
    var depth = 0
    var comma: Int?
    for (i, c) in s.enumerated() {
        if c == "(" { depth += 1 }
        else if c == ")" { depth -= 1; if depth == 0 && i != s.count - 1 { return nil } }
        else if c == ",", depth == 1 { if comma != nil { return nil }; comma = i }
    }
    guard let comma else { return nil }
    return (String(s[1..<comma]).trimmingCharacters(in: .whitespaces),
            String(s[(comma + 1)..<(s.count - 1)]).trimmingCharacters(in: .whitespaces))
}

/// Any `=` not of the form `y = ...` is an implicit equation.
func isImplicitEquation(_ raw: String) -> Bool {
    let cleaned = raw.trimmingCharacters(in: .whitespaces)
    // Piecewise and domain-limit braces hold their own < and =, which say nothing about the row.
    let outside = cleaned.replacing(#/\{[^{}]*\}/#, with: "")
    guard outside.contains("="), parseSlider(cleaned) == nil else { return false }
    return cleaned.range(of: #"^[yr]\s*=\s*"#, options: [.regularExpression, .caseInsensitive]) == nil
}

// MARK: - Desmos syntax, mirroring desugar() in src/utils/evaluate.js

/// Split on commas at bracket depth 0.
private func splitTop(_ s: String) -> [String] {
    var parts: [String] = []
    var depth = 0
    var current = ""
    for c in s {
        if "([{".contains(c) { depth += 1 } else if ")]}".contains(c) { depth -= 1 }
        if c == ",", depth == 0 { parts.append(current); current = "" } else { current.append(c) }
    }
    parts.append(current)
    return parts.map { $0.trimmingCharacters(in: .whitespaces) }
}

/// Rewrites what the parser does not read into what it does:
///   x^2 {0 < x < 2}  ->  ((0 < x < 2) ? (x^2) : nan)    domain limit
///   {x < 0: -x, x}    ->  ((x < 0) ? (-x) : (x))          piecewise
///   f'(x), f''(x)     ->  f__d1(x), f__d2(x)               derivative of a defined function
///   d/dx(sin(x))      ->  ddx(sin(x))                      numeric derivative
func desugar(_ raw: String) -> String {
    var s = raw.trimmingCharacters(in: .whitespaces)
    if let m = s.wholeMatch(of: #/(.+?)\s*\{([^{}:]+)\}/#),
       !m.1.trimmingCharacters(in: .whitespaces).hasSuffix(",") {
        s = "((\(m.2)) ? (\(m.1)) : nan)"
    }
    for _ in 0..<20 {
        guard let match = s.firstMatch(of: #/\{[^{}]*:[^{}]*\}/#) else { break }
        var out = "nan"
        for part in splitTop(String(s[match.range].dropFirst().dropLast())).reversed() {
            if let colon = part.firstIndex(of: ":") {
                out = "((\(part[..<colon])) ? (\(part[part.index(after: colon)...])) : \(out))"
            } else {
                out = "(\(part))"
            }
        }
        s.replaceSubrange(match.range, with: "(\(out))")
    }
    s = s.replacing(#/([a-zA-Z]\w*)''\(/#) { "\($0.1)__d2(" }
    s = s.replacing(#/([a-zA-Z]\w*)'\(/#) { "\($0.1)__d1(" }
    return s.replacingOccurrences(of: "d/dx(", with: "ddx(")
}

/// `f(x) = x^2`: defines f for every other row, and draws itself as y = f(x).
func parseFunctionDef(_ raw: String) -> (name: String, param: String, body: String)? {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    guard let m = trimmed.wholeMatch(of: #/([a-zA-Z]\w*)\(\s*([a-zA-Z]\w*)\s*\)\s*=\s*(.+)/#) else { return nil }
    let name = String(m.1).lowercased()
    guard name != "y", name != "r", functions[name] == nil else { return nil }
    return (name, String(m.2).lowercased(), String(m.3))
}

/// The scope every row evaluates in: slider values plus the functions `f(x) = ...` rows define.
func buildVars(_ sources: [String], values: [String: Double]) -> Vars {
    // The closures need the finished table so f can call g; a box hands it to them after.
    final class Box { var vars = Vars(); var depth = 0 }
    let box = Box()
    var vars = Vars(values: values)
    for source in sources {
        guard let def = parseFunctionDef(source), let body = try? compileSide(def.body) else { continue }
        vars.functions[def.name] = { v in
            // f(x) = f(x) would recurse forever and crash; mathjs throws, this gives NaN.
            guard box.depth < 64 else { return .nan }
            box.depth += 1
            defer { box.depth -= 1 }
            var scope = Scope(vars: box.vars)
            switch def.param {
            case "x": scope.x = v
            case "y": scope.y = v
            case "t", "theta": scope.t = v
            default: scope.vars.values[def.param] = v
            }
            return evaluate(body, scope)
        }
    }
    box.vars = vars
    return vars
}

func compileExpression(_ raw: String) -> CompiledExpression {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else {
        return CompiledExpression(function: nil, implicitFunction: nil, error: nil)
    }

    if let slider = parseSlider(trimmed) {
        return CompiledExpression(function: nil, implicitFunction: nil, slider: slider, error: nil)
    }

    if let def = parseFunctionDef(trimmed) {
        do {
            _ = try compileSide(def.body)
            return CompiledExpression(function: { x, vars in vars.functions[def.name]?(x) ?? .nan },
                                      implicitFunction: nil, error: nil)
        } catch let error as ExpressionError {
            return CompiledExpression(function: nil, implicitFunction: nil, error: error.text)
        } catch {
            return CompiledExpression(function: nil, implicitFunction: nil, error: "Could not read that expression")
        }
    }

    do {
        if let ineq = splitInequality(trimmed) {
            let lhs = try compileSide(ineq.lhs)
            let rhs = try compileSide(ineq.rhs)
            let g: (Double, Double, Vars) -> Double = { x, y, vars in
                let scope = Scope(x: x, y: y, vars: vars)
                return evaluate(lhs, scope) - evaluate(rhs, scope)
            }
            return CompiledExpression(function: nil, implicitFunction: g,
                                      inequality: (ineq.sign, ineq.strict), error: nil)
        }
        let ranged = takeTRange(trimmed)
        if let match = ranged.source.range(of: #"^r\s*=\s*"#, options: [.regularExpression, .caseInsensitive]) {
            let r = try compileSide(String(ranged.source[match.upperBound...]))
            let polar: (Double, Vars) -> (Double, Double) = { t, vars in
                let radius = evaluate(r, Scope(t: t, vars: vars))
                return (radius * cos(t), radius * sin(t))
            }
            return CompiledExpression(function: nil, implicitFunction: nil, parametric: polar,
                                      tRange: ranged.range, error: nil)
        }
        if let (xs, ys) = splitPair(ranged.source) {
            let xn = try compileSide(xs)
            let yn = try compileSide(ys)
            if uses("t", xn) || uses("t", yn) {
                let curve: (Double, Vars) -> (Double, Double) = { t, vars in
                    let scope = Scope(t: t, vars: vars)
                    return (evaluate(xn, scope), evaluate(yn, scope))
                }
                return CompiledExpression(function: nil, implicitFunction: nil, parametric: curve,
                                          tRange: ranged.range, error: nil)
            }
            let point: (Vars) -> (Double, Double) = { vars in
                let scope = Scope(vars: vars)
                return (evaluate(xn, scope), evaluate(yn, scope))
            }
            return CompiledExpression(function: nil, implicitFunction: nil, point: point, error: nil)
        }
    } catch let error as ExpressionError {
        return CompiledExpression(function: nil, implicitFunction: nil, error: error.text)
    } catch {
        return CompiledExpression(function: nil, implicitFunction: nil, error: "Could not read that expression")
    }

    if isImplicitEquation(trimmed) {
        let parts = trimmed.split(separator: "=", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        do {
            let lhs = try compileSide(parts[0])
            let rhs = try compileSide(parts.count > 1 ? parts[1] : "")
            let implicitFn: (Double, Double, Vars) -> Double = { x, y, vars in
                let scope = Scope(x: x, y: y, vars: vars)
                return evaluate(lhs, scope) - evaluate(rhs, scope)
            }
            return CompiledExpression(function: nil, implicitFunction: implicitFn, error: nil)
        } catch let error as ExpressionError {
            return CompiledExpression(function: nil, implicitFunction: nil, error: error.text)
        } catch {
            return CompiledExpression(function: nil, implicitFunction: nil, error: "Could not read that expression")
        }
    }

    // Strip a leading `y =`, same as the web version's /^y\s*=\s*/i.
    var cleaned = trimmed
    if let match = cleaned.range(of: #"^y\s*=\s*"#, options: [.regularExpression, .caseInsensitive]) {
        cleaned = String(cleaned[match.upperBound...])
    }
    cleaned = cleaned.trimmingCharacters(in: .whitespaces)
    guard !cleaned.isEmpty else {
        return CompiledExpression(function: nil, implicitFunction: nil, error: nil)
    }

    do {
        let tree = try compileSide(cleaned)
        return CompiledExpression(function: { evaluate(tree, Scope(x: $0, vars: $1)) }, implicitFunction: nil, error: nil)
    } catch let error as ExpressionError {
        return CompiledExpression(function: nil, implicitFunction: nil, error: error.text)
    } catch {
        return CompiledExpression(function: nil, implicitFunction: nil, error: "Could not read that expression")
    }
}

/// A vertical asymptote (tan(x), 1/x) yields two finite but huge values of opposite sign on
/// adjacent pixels. Joining them draws a false vertical line, so the stroke has to break.
func isAsymptoteJump(previous: Double, current: Double, scale: Double, height: Double) -> Bool {
    // Mirrors Math.sign() exactly, zero included, so the Swift and JS versions break in the
    // same places.
    func sign(_ value: Double) -> Double { value > 0 ? 1 : (value < 0 ? -1 : 0) }
    return sign(current) != sign(previous) && abs(current - previous) * scale > height * 2
}

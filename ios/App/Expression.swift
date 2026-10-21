// Expression parsing and evaluation — the Swift replacement for mathjs.
//
// The web app calls mathjs `parse(expr).compile()` and evaluates it per pixel with one
// variable, x (see src/utils/evaluate.js). That is all it ever asks of mathjs, so this is a
// recursive-descent parser for exactly that grammar rather than a general CAS.
//
// Grammar (lowest to highest precedence):
//   expression := term (('+' | '-') term)*
//   term       := unary (('*' | '/') unary | implicit-multiplication)*
//   unary      := ('-' | '+')* power
//   power      := primary ('^' unary)?          -- right associative
//   primary    := number | variable | constant | function '(' expression ')' | '(' expression ')'
//
// Variables are x, y, t (theta is t) and any other bare name, which reads its value from a
// slider row like `a = 3`. A name nothing defines evaluates to NaN and draws nothing.

import Foundation

enum ExpressionError: Error {
    case message(String)

    var text: String {
        switch self {
        case .message(let m): return m
        }
    }
}

// MARK: - Tokens

private enum Token: Equatable {
    case number(Double)
    case identifier(String)
    case op(Character)
    case lparen
    case rparen
    case comma
}

private func tokenize(_ input: String) throws -> [Token] {
    var tokens: [Token] = []
    let chars = Array(input)
    var i = 0

    while i < chars.count {
        let c = chars[i]

        if c.isWhitespace { i += 1; continue }

        if c.isNumber || c == "." {
            var literal = ""
            while i < chars.count, chars[i].isNumber || chars[i] == "." {
                literal.append(chars[i]); i += 1
            }
            guard let value = Double(literal) else {
                throw ExpressionError.message("Not a number: \(literal)")
            }
            tokens.append(.number(value))
            continue
        }

        if c.isLetter {
            var name = ""
            while i < chars.count, chars[i].isLetter || chars[i].isNumber || chars[i] == "_" {
                name.append(chars[i]); i += 1
            }
            tokens.append(.identifier(name.lowercased()))
            continue
        }

        switch c {
        case "+", "-", "*", "/", "^", "?", ":":
            tokens.append(.op(c)); i += 1
        case "<", ">":
            // `<=` and `>=` become one op, spelled with the Unicode symbol so it stays a Character.
            if i + 1 < chars.count, chars[i + 1] == "=" {
                tokens.append(.op(c == "<" ? "≤" : "≥")); i += 2
            } else {
                tokens.append(.op(c)); i += 1
            }
        case "(":
            tokens.append(.lparen); i += 1
        case ")":
            tokens.append(.rparen); i += 1
        case ",":
            tokens.append(.comma); i += 1
        default:
            throw ExpressionError.message("Unexpected character: \(c)")
        }
    }
    return tokens
}

// MARK: - Syntax tree

indirect enum Node {
    case constant(Double)
    case variable(String) // x, y, t, or a slider name
    case unaryMinus(Node)
    case binary(Character, Node, Node)
    case call(String, Node)
    /// `f(x)`, `f'(x)`, `f''(x)` for a function another row defines. Order is the derivative.
    case userCall(String, order: Int, Node)
    /// `d/dx(...)`, taken numerically.
    case derivative(Node)
    /// `0 < x < 2`: every link must hold, like mathjs chained comparisons. 1 or 0.
    case comparison([Node], [Character])
    /// `c ? a : b`, what piecewise and domain-limit braces desugar into.
    case conditional(Node, Node, Node)
}

let functions: [String: (Double) -> Double] = [
    "sin": sin, "cos": cos, "tan": tan,
    "asin": asin, "acos": acos, "atan": atan,
    "sinh": sinh, "cosh": cosh, "tanh": tanh,
    "sqrt": sqrt, "cbrt": cbrt, "abs": abs,
    // mathjs `log` is the natural logarithm — keep that, or every log() plot shifts.
    "log": Foundation.log, "ln": Foundation.log,
    "log10": log10, "log2": log2, "exp": exp,
    "floor": floor, "ceil": ceil, "round": { $0.rounded() },
    "sign": { $0 > 0 ? 1 : ($0 < 0 ? -1 : 0) },
]

private let constants: [String: Double] = [
    "pi": .pi, "e": M_E, "tau": 2 * .pi, "nan": .nan,
    "phi": (1 + 5.squareRoot()) / 2, // the golden ratio, mathjs has it too
]

private struct Parser {
    let tokens: [Token]
    var position = 0

    var current: Token? { position < tokens.count ? tokens[position] : nil }

    mutating func parse() throws -> Node {
        let node = try ternary()
        if position < tokens.count {
            throw ExpressionError.message("Unexpected trailing input")
        }
        return node
    }

    mutating func ternary() throws -> Node {
        let condition = try comparison()
        guard case .op("?") = current else { return condition }
        position += 1
        let whenTrue = try ternary()
        guard case .op(":") = current else { throw ExpressionError.message("Missing : in a ? b : c") }
        position += 1
        return .conditional(condition, whenTrue, try ternary())
    }

    mutating func comparison() throws -> Node {
        var operands = [try expression()]
        var ops: [Character] = []
        while case .op(let c) = current, "<>≤≥".contains(c) {
            position += 1
            ops.append(c)
            operands.append(try expression())
        }
        return ops.isEmpty ? operands[0] : .comparison(operands, ops)
    }

    mutating func expression() throws -> Node {
        var left = try term()
        while case .op(let c) = current, c == "+" || c == "-" {
            position += 1
            left = .binary(c, left, try term())
        }
        return left
    }

    mutating func term() throws -> Node {
        var left = try unary()
        while true {
            if case .op(let c) = current, c == "*" || c == "/" {
                position += 1
                left = .binary(c, left, try unary())
                continue
            }
            // Implicit multiplication: mathjs accepts `2x` and `2sin(x)`, and people type them.
            if startsPrimary(current) {
                left = .binary("*", left, try unary())
                continue
            }
            return left
        }
    }

    private func startsPrimary(_ token: Token?) -> Bool {
        switch token {
        case .number, .identifier, .lparen: return true
        default: return false
        }
    }

    mutating func unary() throws -> Node {
        if case .op(let c) = current, c == "-" || c == "+" {
            position += 1
            let operand = try unary()
            return c == "-" ? .unaryMinus(operand) : operand
        }
        return try power()
    }

    mutating func power() throws -> Node {
        let base = try primary()
        if case .op(let c) = current, c == "^" {
            position += 1
            return .binary("^", base, try unary()) // right associative: 2^3^2 == 2^9
        }
        return base
    }

    mutating func primary() throws -> Node {
        guard let token = current else {
            throw ExpressionError.message("Unexpected end of expression")
        }

        switch token {
        case .number(let value):
            position += 1
            return .constant(value)

        case .lparen:
            position += 1
            let inner = try ternary()
            guard case .rparen = current else {
                throw ExpressionError.message("Missing closing parenthesis")
            }
            position += 1
            return inner

        case .identifier(let name):
            position += 1
            if let value = constants[name] { return .constant(value) }
            let builtIn = functions[name] != nil || name == "ddx"
            if !builtIn {
                // `x(x+1)` multiplies. Any other name before a paren calls a function another
                // row defines (`f(x) = ...`); one nobody defines evaluates to NaN.
                guard case .lparen = current, !["x", "y", "t", "theta"].contains(name) else {
                    return .variable(name == "theta" ? "t" : name)
                }
            }
            guard case .lparen = current else {
                throw ExpressionError.message("\(name) needs parentheses, like \(name)(x)")
            }
            position += 1
            let argument = try ternary()
            guard case .rparen = current else {
                throw ExpressionError.message("Missing closing parenthesis after \(name)(")
            }
            position += 1
            if name == "ddx" { return .derivative(argument) }
            if builtIn { return .call(name, argument) }
            // desugar() spells f'(x) as f__d1(x)
            for order in [2, 1] where name.hasSuffix("__d\(order)") {
                return .userCall(String(name.dropLast(4)), order: order, argument)
            }
            return .userCall(name, order: 0, argument)

        case .rparen:
            throw ExpressionError.message("Unmatched closing parenthesis")

        case .comma:
            throw ExpressionError.message("Unexpected comma")

        case .op(let c):
            throw ExpressionError.message("Unexpected operator: \(c)")
        }
    }
}

/// What every row evaluates in: slider values (`a = 3`) and the functions `f(x) = ...` rows define.
struct Vars: ExpressibleByDictionaryLiteral {
    var values: [String: Double] = [:]
    var functions: [String: (Double) -> Double] = [:]

    init(values: [String: Double] = [:]) { self.values = values }

    /// These values with a list copy's bindings on top.
    func with(_ bindings: [String: Double]) -> Vars {
        guard !bindings.isEmpty else { return self }
        var copy = self
        copy.values.merge(bindings) { _, new in new }
        return copy
    }
    init(dictionaryLiteral elements: (String, Double)...) {
        values = Dictionary(elements, uniquingKeysWith: { first, _ in first })
    }
}

struct Scope {
    var x = Double.nan, y = Double.nan, t = Double.nan
    var vars: Vars
}

func evaluate(_ node: Node, _ scope: Scope) -> Double {
    switch node {
    case .constant(let value):
        return value
    case .variable(let name):
        switch name {
        case "x": return scope.x
        case "y": return scope.y
        case "t": return scope.t
        default: return scope.vars.values[name] ?? .nan
        }
    case .unaryMinus(let operand):
        return -evaluate(operand, scope)
    case .call(let name, let argument):
        return functions[name]?(evaluate(argument, scope)) ?? .nan
    case .userCall(let name, let order, let argument):
        guard let f = scope.vars.functions[name] else { return .nan }
        let v = evaluate(argument, scope)
        let h = 1e-4
        switch order {
        case 1: return (f(v + h) - f(v - h)) / (2 * h)
        case 2: return (f(v + h) - 2 * f(v) + f(v - h)) / (h * h)
        default: return f(v)
        }
    case .derivative(let inner):
        let h = 1e-5 * max(1, abs(scope.x))
        var ahead = scope, behind = scope
        ahead.x += h
        behind.x -= h
        return (evaluate(inner, ahead) - evaluate(inner, behind)) / (2 * h)
    case .comparison(let operands, let ops):
        let values = operands.map { evaluate($0, scope) }
        for (i, op) in ops.enumerated() {
            let a = values[i], b = values[i + 1]
            let holds = switch op {
            case "<": a < b
            case ">": a > b
            case "≤": a <= b
            default: a >= b
            }
            if !holds { return 0 }
        }
        return 1
    case .conditional(let condition, let whenTrue, let whenFalse):
        let c = evaluate(condition, scope)
        return c.isNaN ? .nan : (c != 0 ? evaluate(whenTrue, scope) : evaluate(whenFalse, scope))
    case .binary(let op, let lhs, let rhs):
        let a = evaluate(lhs, scope)
        let b = evaluate(rhs, scope)
        switch op {
        case "+": return a + b
        case "-": return a - b
        case "*": return a * b
        case "/": return a / b
        case "^": return pow(a, b)
        default: return .nan
        }
    }
}

func uses(_ name: String, _ node: Node) -> Bool {
    switch node {
    case .constant: return false
    case .variable(let v): return v == name
    case .unaryMinus(let operand): return uses(name, operand)
    case .call(_, let argument), .userCall(_, _, let argument), .derivative(let argument):
        return uses(name, argument)
    case .comparison(let operands, _): return operands.contains { uses(name, $0) }
    case .conditional(let a, let b, let c): return uses(name, a) || uses(name, b) || uses(name, c)
    case .binary(_, let lhs, let rhs): return uses(name, lhs) || uses(name, rhs)
    }
}

func compileSide(_ raw: String) throws -> Node {
    var parser = Parser(tokens: try tokenize(desugar(raw)))
    return try parser.parse()
}

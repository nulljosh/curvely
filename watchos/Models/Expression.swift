// Expression parsing and evaluation — the Swift replacement for mathjs.
//
// Direct copy of ios/App/Expression.swift. The watch app has no equation input (no
// practical keyboard for `sin(x)` on a 40mm screen), so it only ever compiles the fixed
// preset list in Presets.swift, but it needs the real evaluator to plot them rather than
// faking curve shapes. Keep this file byte-for-byte in sync with the iOS original.
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
//   primary    := number | 'x' | constant | function '(' expression ')' | '(' expression ')'

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
            while i < chars.count, chars[i].isLetter || chars[i].isNumber {
                name.append(chars[i]); i += 1
            }
            tokens.append(.identifier(name.lowercased()))
            continue
        }

        switch c {
        case "+", "-", "*", "/", "^":
            tokens.append(.op(c)); i += 1
        case "(":
            tokens.append(.lparen); i += 1
        case ")":
            tokens.append(.rparen); i += 1
        default:
            throw ExpressionError.message("Unexpected character: \(c)")
        }
    }
    return tokens
}

// MARK: - Syntax tree

private indirect enum Node {
    case constant(Double)
    case variable
    case unaryMinus(Node)
    case binary(Character, Node, Node)
    case call(String, Node)
}

private nonisolated(unsafe) let functions: [String: (Double) -> Double] = [
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
    "pi": .pi, "e": M_E, "tau": 2 * .pi,
]

private struct Parser {
    let tokens: [Token]
    var position = 0

    var current: Token? { position < tokens.count ? tokens[position] : nil }

    mutating func parse() throws -> Node {
        let node = try expression()
        if position < tokens.count {
            throw ExpressionError.message("Unexpected trailing input")
        }
        return node
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
            let inner = try expression()
            guard case .rparen = current else {
                throw ExpressionError.message("Missing closing parenthesis")
            }
            position += 1
            return inner

        case .identifier(let name):
            position += 1
            if name == "x" { return .variable }
            if let value = constants[name] { return .constant(value) }
            guard functions[name] != nil else {
                throw ExpressionError.message("Unknown name: \(name)")
            }
            guard case .lparen = current else {
                throw ExpressionError.message("\(name) needs parentheses, like \(name)(x)")
            }
            position += 1
            let argument = try expression()
            guard case .rparen = current else {
                throw ExpressionError.message("Missing closing parenthesis after \(name)(")
            }
            position += 1
            return .call(name, argument)

        case .rparen:
            throw ExpressionError.message("Unmatched closing parenthesis")

        case .op(let c):
            throw ExpressionError.message("Unexpected operator: \(c)")
        }
    }
}

private func evaluate(_ node: Node, x: Double) -> Double {
    switch node {
    case .constant(let value):
        return value
    case .variable:
        return x
    case .unaryMinus(let operand):
        return -evaluate(operand, x: x)
    case .call(let name, let argument):
        return functions[name]?(evaluate(argument, x: x)) ?? .nan
    case .binary(let op, let lhs, let rhs):
        let a = evaluate(lhs, x: x)
        let b = evaluate(rhs, x: x)
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

// MARK: - Public surface, mirroring src/utils/evaluate.js

struct CompiledExpression {
    /// nil when the input was empty — an empty row is not an error, it just draws nothing.
    let function: ((Double) -> Double)?
    let error: String?
}

func compileExpression(_ raw: String) -> CompiledExpression {
    // Strip a leading `y =`, same as the web version's /^y\s*=\s*/i.
    var cleaned = raw.trimmingCharacters(in: .whitespaces)
    if let match = cleaned.range(of: #"^y\s*=\s*"#, options: [.regularExpression, .caseInsensitive]) {
        cleaned = String(cleaned[match.upperBound...])
    }
    cleaned = cleaned.trimmingCharacters(in: .whitespaces)

    guard !cleaned.isEmpty else { return CompiledExpression(function: nil, error: nil) }

    do {
        let tokens = try tokenize(cleaned)
        var parser = Parser(tokens: tokens)
        let tree = try parser.parse()
        return CompiledExpression(function: { evaluate(tree, x: $0) }, error: nil)
    } catch let error as ExpressionError {
        return CompiledExpression(function: nil, error: error.text)
    } catch {
        return CompiledExpression(function: nil, error: "Could not read that expression")
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

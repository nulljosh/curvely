package com.nulljosh.curvely

import kotlin.math.*

// Ported from ios/App/Expression.swift (itself the Swift replacement for
// mathjs). Keep the three in lockstep: src/utils/evaluate.js (web),
// ios/App/Expression.swift (Swift), this file (Kotlin).

class ExpressionException(message: String) : Exception(message)

private sealed class Tok {
    data class Number(val value: Double) : Tok()
    data class Ident(val name: String) : Tok()
    data class Op(val c: Char) : Tok()
    object LParen : Tok(); object RParen : Tok()
}

private fun tokenize(input: String): List<Tok> {
    val tokens = mutableListOf<Tok>()
    val chars = input.toCharArray()
    var i = 0
    while (i < chars.size) {
        val c = chars[i]
        if (c.isWhitespace()) { i++; continue }
        if (c.isDigit() || c == '.') {
            val start = i
            while (i < chars.size && (chars[i].isDigit() || chars[i] == '.')) i++
            val literal = String(chars, start, i - start)
            val value = literal.toDoubleOrNull() ?: throw ExpressionException("Not a number: $literal")
            tokens.add(Tok.Number(value)); continue
        }
        if (c.isLetter()) {
            val start = i
            while (i < chars.size && (chars[i].isLetterOrDigit())) i++
            tokens.add(Tok.Ident(String(chars, start, i - start).lowercase())); continue
        }
        when (c) {
            '+', '-', '*', '/', '^' -> tokens.add(Tok.Op(c))
            '(' -> tokens.add(Tok.LParen)
            ')' -> tokens.add(Tok.RParen)
            else -> throw ExpressionException("Unexpected character: $c")
        }
        i++
    }
    return tokens
}

private sealed class Node {
    data class Const(val value: Double) : Node()
    object Variable : Node()
    data class UnaryMinus(val operand: Node) : Node()
    data class Binary(val op: Char, val lhs: Node, val rhs: Node) : Node()
    data class Call(val name: String, val arg: Node) : Node()
}

private val FUNCTIONS: Map<String, (Double) -> Double> = mapOf(
    "sin" to ::sin, "cos" to ::cos, "tan" to ::tan,
    "asin" to ::asin, "acos" to ::acos, "atan" to ::atan,
    "sinh" to ::sinh, "cosh" to ::cosh, "tanh" to ::tanh,
    "sqrt" to ::sqrt, "cbrt" to ::cbrt, "abs" to ::abs,
    "log" to ::ln, "ln" to ::ln,
    "log10" to ::log10, "log2" to { x: Double -> log2(x) }, "exp" to ::exp,
    "floor" to ::floor, "ceil" to ::ceil, "round" to { x: Double -> round(x) },
    "sign" to { x: Double -> sign(x) },
)

private val CONSTANTS: Map<String, Double> = mapOf("pi" to PI, "e" to E, "tau" to 2 * PI)

private class Parser(private val tokens: List<Tok>) {
    var position = 0
    private fun current(): Tok? = tokens.getOrNull(position)

    fun parse(): Node {
        val node = expression()
        if (position < tokens.size) throw ExpressionException("Unexpected trailing input")
        return node
    }

    private fun startsPrimary(t: Tok?) = t is Tok.Number || t is Tok.Ident || t is Tok.LParen

    fun expression(): Node {
        var left = term()
        while (true) {
            val t = current()
            if (t is Tok.Op && (t.c == '+' || t.c == '-')) { position++; left = Node.Binary(t.c, left, term()) }
            else return left
        }
    }

    private fun term(): Node {
        var left = unary()
        while (true) {
            val t = current()
            if (t is Tok.Op && (t.c == '*' || t.c == '/')) { position++; left = Node.Binary(t.c, left, unary()); continue }
            if (startsPrimary(t)) { left = Node.Binary('*', left, unary()); continue }
            return left
        }
    }

    private fun unary(): Node {
        val t = current()
        if (t is Tok.Op && (t.c == '-' || t.c == '+')) {
            position++
            val operand = unary()
            return if (t.c == '-') Node.UnaryMinus(operand) else operand
        }
        return power()
    }

    private fun power(): Node {
        val base = primary()
        val t = current()
        if (t is Tok.Op && t.c == '^') { position++; return Node.Binary('^', base, unary()) }
        return base
    }

    private fun primary(): Node {
        val t = current() ?: throw ExpressionException("Unexpected end of expression")
        return when (t) {
            is Tok.Number -> { position++; Node.Const(t.value) }
            is Tok.LParen -> {
                position++
                val inner = expression()
                if (current() !is Tok.RParen) throw ExpressionException("Missing closing parenthesis")
                position++
                inner
            }
            is Tok.Ident -> {
                position++
                when {
                    t.name == "x" -> Node.Variable
                    t.name in CONSTANTS -> Node.Const(CONSTANTS.getValue(t.name))
                    t.name in FUNCTIONS -> {
                        if (current() !is Tok.LParen) throw ExpressionException("${t.name} needs parentheses, like ${t.name}(x)")
                        position++
                        val arg = expression()
                        if (current() !is Tok.RParen) throw ExpressionException("Missing closing parenthesis after ${t.name}(")
                        position++
                        Node.Call(t.name, arg)
                    }
                    else -> throw ExpressionException("Unknown name: ${t.name}")
                }
            }
            is Tok.RParen -> throw ExpressionException("Unmatched closing parenthesis")
            is Tok.Op -> throw ExpressionException("Unexpected operator: ${t.c}")
        }
    }
}

private fun evaluate(node: Node, x: Double): Double = when (node) {
    is Node.Const -> node.value
    is Node.Variable -> x
    is Node.UnaryMinus -> -evaluate(node.operand, x)
    is Node.Call -> FUNCTIONS[node.name]?.invoke(evaluate(node.arg, x)) ?: Double.NaN
    is Node.Binary -> {
        val a = evaluate(node.lhs, x)
        val b = evaluate(node.rhs, x)
        when (node.op) {
            '+' -> a + b; '-' -> a - b; '*' -> a * b; '/' -> a / b; '^' -> a.pow(b)
            else -> Double.NaN
        }
    }
}

data class CompiledExpression(val function: ((Double) -> Double)?, val error: String?)

private val Y_PREFIX = Regex("^y\\s*=\\s*", RegexOption.IGNORE_CASE)

fun compileExpression(raw: String): CompiledExpression {
    var cleaned = raw.trim().replace(Y_PREFIX, "").trim()
    if (cleaned.isEmpty()) return CompiledExpression(null, null)
    return try {
        val tokens = tokenize(cleaned)
        val tree = Parser(tokens).parse()
        CompiledExpression({ x -> evaluate(tree, x) }, null)
    } catch (e: ExpressionException) {
        CompiledExpression(null, e.message)
    } catch (e: Exception) {
        CompiledExpression(null, "Could not read that expression")
    }
}

/** A vertical asymptote (tan(x), 1/x) yields two finite but huge values of opposite sign on
 *  adjacent pixels. Joining them draws a false vertical line, so the stroke has to break. */
fun isAsymptoteJump(previous: Double, current: Double, scale: Double, height: Double): Boolean {
    fun s(v: Double) = if (v > 0) 1.0 else if (v < 0) -1.0 else 0.0
    return s(current) != s(previous) && abs(current - previous) * scale > height * 2
}

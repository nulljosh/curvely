package com.nulljosh.curvely

import kotlin.math.PI
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ExpressionTest {
    private fun eval(expr: String, x: Double) = compileExpression(expr).function!!(x)

    @Test fun arithmetic() {
        assertEquals(7.0, eval("1+2*3", 0.0))
        assertEquals(9.0, eval("(1+2)*3", 0.0))
    }

    @Test fun variableAndImplicitMultiplication() {
        assertEquals(6.0, eval("2x", 3.0))
    }

    @Test fun functionsAndConstants() {
        assertTrue(abs(eval("sin(pi/2)", 0.0) - 1.0) < 1e-9)
        assertEquals(PI, eval("pi", 0.0))
    }

    @Test fun yPrefixStripped() {
        assertEquals(4.0, eval("y = x^2", 2.0))
    }

    @Test fun emptyIsNotAnError() {
        val c = compileExpression("")
        assertNull(c.function)
        assertNull(c.error)
    }

    @Test fun errorsAreReported() {
        assertTrue(compileExpression("sqrt").error != null)
        assertTrue(compileExpression("(1+2").error != null)
        assertTrue(compileExpression("unknownfn(1)").error != null)
    }
}

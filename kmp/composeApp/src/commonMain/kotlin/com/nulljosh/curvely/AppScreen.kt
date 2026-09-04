package com.nulljosh.curvely

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.unit.dp

@Composable
fun CurvelyTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = lightColorScheme(), content = content)

// ponytail: fixed [-10, 10] domain/range, no pan/zoom. The web/iOS apps let
// you drag and pinch; wiring that up is separate work from porting the math.
@Composable
fun AppScreen() {
    var input by remember { mutableStateOf("sin(x)") }
    val compiled = remember(input) { compileExpression(input) }

    Surface {
        Column(Modifier.fillMaxSize().padding(24.dp)) {
            Text("Curvely", style = MaterialTheme.typography.headlineMedium)
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                label = { Text("y =") },
                modifier = Modifier.fillMaxWidth().padding(top = 16.dp),
            )
            compiled.error?.let { Text(it, modifier = Modifier.padding(top = 8.dp)) }
            Canvas(Modifier.fillMaxWidth().weight(1f).padding(top = 16.dp)) {
                val w = size.width
                val h = size.height
                val domain = 10.0
                val range = 10.0
                val scaleX = w / (2 * domain)
                val scaleY = h / (2 * range)

                // axes
                drawLine(Color.Gray, Offset(0f, h / 2), Offset(w, h / 2))
                drawLine(Color.Gray, Offset(w / 2, 0f), Offset(w / 2, h))

                val fn = compiled.function ?: return@Canvas
                var previous: Double? = null
                var px = 0f
                var py = 0f
                for (i in 0..w.toInt()) {
                    val x = (i - w / 2) / scaleX
                    val y = fn(x)
                    val screenX = (x * scaleX + w / 2).toFloat()
                    val screenY = (h / 2 - y * scaleY).toFloat()
                    if (previous != null && !y.isNaN() && !previous!!.isNaN() &&
                        !isAsymptoteJump(previous!!, y, scaleY, h.toDouble())
                    ) {
                        drawLine(
                            Color(0xFF5B9BD5),
                            Offset(px, py),
                            Offset(screenX, screenY),
                            strokeWidth = 4f,
                            cap = StrokeCap.Round,
                        )
                    }
                    previous = y; px = screenX; py = screenY
                }
            }
        }
    }
}

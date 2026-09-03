// A single curve, drawn full-screen. Cut down from ios/App/GraphView.swift: no pan/zoom
// gestures (there's no room for a sidebar or a zoom cluster on a watch face, and the
// Digital Crown is better spent scrolling than reserved for this), fixed centered scale,
// same grid/axis/curve/asymptote-break drawing math as the phone.

import SwiftUI

struct PlotView: View {
    let curve: PresetCurve

    /// Smaller than the iOS default (60): watch screens are ~180-220pt wide, so a lower
    /// scale keeps a couple of x-axis periods on screen instead of one steep sliver.
    private let scale: Double = 18

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            drawGrid(&context, size: size, center: center)
            drawAxes(&context, size: size, center: center)
            drawCurve(&context, size: size, center: center)
        }
        .background(Theme.graphBackground)
    }

    private func drawGrid(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        var path = Path()
        var x = center.x.truncatingRemainder(dividingBy: scale)
        while x < size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += scale
        }
        var y = center.y.truncatingRemainder(dividingBy: scale)
        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += scale
        }
        context.stroke(path, with: .color(Theme.grid), lineWidth: 0.5)
    }

    private func drawAxes(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: center.y))
        path.addLine(to: CGPoint(x: size.width, y: center.y))
        path.move(to: CGPoint(x: center.x, y: 0))
        path.addLine(to: CGPoint(x: center.x, y: size.height))
        context.stroke(path, with: .color(Theme.axis), lineWidth: 1)
    }

    private func drawCurve(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        guard let fn = curve.compiled.function else { return }
        var path = Path()
        var penDown = false
        var previousY = 0.0

        var px = 0.0
        while px < size.width {
            let x = (px - center.x) / scale
            let y = fn(x)
            guard y.isFinite else { penDown = false; px += 1; continue }

            let point = CGPoint(x: px, y: center.y - y * scale)
            if penDown, isAsymptoteJump(previous: previousY, current: y, scale: scale, height: size.height) {
                penDown = false
            }
            if penDown { path.addLine(to: point) } else { path.move(to: point); penDown = true }
            previousY = y
            px += 1
        }

        context.stroke(
            path,
            with: .color(curve.color),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
}

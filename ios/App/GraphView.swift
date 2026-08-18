// The plot: grid, axes, labels, curves. Ported from src/components/Graph.jsx.

import SwiftUI

struct GraphTransform: Equatable {
    static let defaultScale: Double = 60
    static let minScale: Double = 10
    static let maxScale: Double = 400

    var scale: Double = defaultScale
    var offset: CGSize = .zero

    var zoomPercent: Int { Int((scale / Self.defaultScale * 100).rounded()) }

    func center(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2 + offset.width, y: size.height / 2 + offset.height)
    }

    /// Zoom while keeping the graph point under `anchor` pinned to the same pixel.
    mutating func zoom(by factor: Double, about anchor: CGPoint, in size: CGSize) {
        let newScale = min(Self.maxScale, max(Self.minScale, scale * factor))
        let ratio = newScale / scale
        guard ratio != 1 else { return }
        let c = center(in: size)
        offset.width = anchor.x - size.width / 2 - (anchor.x - c.x) * ratio
        offset.height = anchor.y - size.height / 2 - (anchor.y - c.y) * ratio
        scale = newScale
    }
}

struct GraphView: View {
    let equations: [Equation]
    @Binding var transform: GraphTransform

    @State private var panStart: CGSize?
    @State private var pinchStart: Double?

    var body: some View {
        GeometryReader { geometry in
            Canvas(rendersAsynchronously: false) { context, size in
                let center = transform.center(in: size)
                drawGrid(&context, size: size, center: center)
                drawAxes(&context, size: size, center: center)
                drawLabels(&context, size: size, center: center)
                drawCurves(&context, size: size, center: center)
            }
            .background(Theme.graphBackground)
            .contentShape(Rectangle())
            .gesture(panGesture(in: geometry.size))
            .gesture(pinchGesture(in: geometry.size))
            .onTapGesture(count: 2) { transform = GraphTransform() }
        }
    }

    // MARK: - Drawing

    private func drawGrid(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        let step = transform.scale
        var path = Path()
        var x = (center.x.truncatingRemainder(dividingBy: step) - step)
            .truncatingRemainder(dividingBy: step)
        while x < size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += step
        }
        var y = (center.y.truncatingRemainder(dividingBy: step) - step)
            .truncatingRemainder(dividingBy: step)
        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += step
        }
        context.stroke(path, with: .color(Theme.grid), lineWidth: 1)
    }

    private func drawAxes(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: center.y))
        path.addLine(to: CGPoint(x: size.width, y: center.y))
        path.move(to: CGPoint(x: center.x, y: 0))
        path.addLine(to: CGPoint(x: center.x, y: size.height))
        context.stroke(path, with: .color(Theme.axis), lineWidth: 1.5)
    }

    private func drawLabels(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        let step = transform.scale
        let labelStep = max(1.0, (80 / step).rounded())

        var x = (center.x.truncatingRemainder(dividingBy: step) - step)
            .truncatingRemainder(dividingBy: step)
        while x < size.width {
            let value = ((x - center.x) / step / labelStep).rounded() * labelStep
            if value != 0 {
                draw(&context, number: value, at: CGPoint(x: x, y: center.y + 14), anchor: .center)
            }
            x += step
        }

        var y = (center.y.truncatingRemainder(dividingBy: step) - step)
            .truncatingRemainder(dividingBy: step)
        while y < size.height {
            let value = -((y - center.y) / step / labelStep).rounded() * labelStep
            if value != 0 {
                draw(&context, number: value, at: CGPoint(x: center.x - 6, y: y), anchor: .trailing)
            }
            y += step
        }
    }

    private func draw(_ context: inout GraphicsContext, number: Double, at point: CGPoint, anchor: UnitPoint) {
        let text = Text(formatted(number)).font(.system(size: 11)).foregroundStyle(Theme.axisLabel)
        context.draw(text, at: point, anchor: anchor)
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%g", value)
    }

    private func drawCurves(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        for equation in equations {
            guard let fn = equation.compiled.function else { continue }
            var path = Path()
            var penDown = false
            var previousY = 0.0

            var px = 0.0
            while px < size.width {
                let x = (px - center.x) / transform.scale
                let y = fn(x)
                guard y.isFinite else { penDown = false; px += 1; continue }

                let point = CGPoint(x: px, y: center.y - y * transform.scale)
                if penDown, isAsymptoteJump(previous: previousY, current: y,
                                            scale: transform.scale, height: size.height) {
                    penDown = false
                }
                if penDown { path.addLine(to: point) } else { path.move(to: point); penDown = true }
                previousY = y
                px += 1
            }

            context.stroke(
                path,
                with: .color(equation.color),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            )
        }
    }

    // MARK: - Gestures

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = panStart ?? transform.offset
                if panStart == nil { panStart = start }
                transform.offset = CGSize(
                    width: start.width + value.translation.width,
                    height: start.height + value.translation.height
                )
            }
            .onEnded { _ in panStart = nil }
    }

    private func pinchGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let previous = pinchStart ?? 1
                if pinchStart == nil { pinchStart = 1 }
                let factor = value.magnification / previous
                let anchor = CGPoint(
                    x: value.startLocation.x, y: value.startLocation.y
                )
                transform.zoom(by: factor, about: anchor, in: size)
                pinchStart = value.magnification
            }
            .onEnded { _ in pinchStart = nil }
    }
}

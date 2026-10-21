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

// Marching squares over a coarse pixel grid, ported from Graph.jsx's traceImplicit. Same
// 4-crossing saddle-ambiguity tradeoff: pairing crossings in encounter order is visually fine
// at this grid resolution.
private let implicitGridStep: Double = 5

private func traceImplicit(
    _ fn: (Double, Double) -> Double, size: CGSize, center: CGPoint, scale: Double
) -> [(CGPoint, CGPoint)] {
    let cols = Int((size.width / implicitGridStep).rounded(.up)) + 1
    let rows = Int((size.height / implicitGridStep).rounded(.up)) + 1
    var values = [[Double]](repeating: [Double](repeating: .nan, count: cols), count: rows)
    for r in 0..<rows {
        let y = (center.y - Double(r) * implicitGridStep) / scale
        for c in 0..<cols {
            let x = (Double(c) * implicitGridStep - center.x) / scale
            values[r][c] = fn(x, y)
        }
    }

    func lerp(_ a: Double, _ va: Double, _ b: Double, _ vb: Double) -> Double {
        a + (b - a) * (va / (va - vb))
    }

    var segments: [(CGPoint, CGPoint)] = []
    for r in 0..<(rows - 1) {
        for c in 0..<(cols - 1) {
            let v00 = values[r][c], v10 = values[r][c + 1]
            let v01 = values[r + 1][c], v11 = values[r + 1][c + 1]
            guard v00.isFinite, v10.isFinite, v01.isFinite, v11.isFinite else { continue }

            let x0 = Double(c) * implicitGridStep, x1 = x0 + implicitGridStep
            let y0 = Double(r) * implicitGridStep, y1 = y0 + implicitGridStep
            var pts: [CGPoint] = []
            if (v00 < 0) != (v10 < 0) { pts.append(CGPoint(x: lerp(x0, v00, x1, v10), y: y0)) }
            if (v10 < 0) != (v11 < 0) { pts.append(CGPoint(x: x1, y: lerp(y0, v10, y1, v11))) }
            if (v01 < 0) != (v11 < 0) { pts.append(CGPoint(x: lerp(x0, v01, x1, v11), y: y1)) }
            if (v00 < 0) != (v01 < 0) { pts.append(CGPoint(x: x0, y: lerp(y0, v00, y1, v01))) }

            if pts.count == 2 { segments.append((pts[0], pts[1])) }
            else if pts.count == 4 {
                segments.append((pts[0], pts[1]))
                segments.append((pts[2], pts[3]))
            }
        }
    }
    return segments
}

struct GraphView: View {
    let equations: [Equation]
    var vars: Vars = [:]
    @Binding var transform: GraphTransform

    /// Where the user last tapped (iOS) or is hovering (Mac): a key point near it shows its coordinates.
    @State private var probe: CGPoint?
    @State private var panStart: CGSize?
    @State private var pinchStart: Double?
    #if os(macOS)
    @State private var hoverPoint: CGPoint?
    @State private var scrollMonitor: Any?
    #endif

    var body: some View {
        GeometryReader { geometry in
            Canvas(rendersAsynchronously: false) { context, size in
                let center = transform.center(in: size)
                drawGrid(&context, size: size, center: center)
                drawAxes(&context, size: size, center: center)
                drawLabels(&context, size: size, center: center)
                drawCurves(&context, size: size, center: center)
                drawKeyPoints(&context, size: size, center: center)
            }
            .background(Theme.graphBackground)
            .contentShape(Rectangle())
            .gesture(panGesture(in: geometry.size))
            .gesture(pinchGesture(in: geometry.size))
            .onTapGesture(count: 2) { transform = GraphTransform() }
            .onTapGesture { probe = $0 }
            #if os(macOS)
            .onContinuousHover { phase in
                if case .active(let point) = phase { hoverPoint = point } else { hoverPoint = nil }
                probe = hoverPoint
            }
            .onAppear { installScrollZoom(in: geometry.size) }
            .onChange(of: geometry.size) { _, size in installScrollZoom(in: size) }
            .onDisappear(perform: removeScrollZoom)
            #endif
        }
    }

    #if os(macOS)
    // ponytail: SwiftUI has no scroll-wheel modifier, and a plain mouse cannot pinch, so
    // the wheel zooms about the cursor like the web app. Only while hovering the plot,
    // so the equation list still scrolls normally.
    private func installScrollZoom(in size: CGSize) {
        removeScrollZoom()
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard let anchor = hoverPoint, event.scrollingDeltaY != 0 else { return event }
            transform.zoom(by: exp(event.scrollingDeltaY * 0.01), about: anchor, in: size)
            return nil
        }
    }

    private func removeScrollZoom() {
        if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
        scrollMonitor = nil
    }
    #endif

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
        let text = Text(formatted(number)).font(Theme.font(11)).foregroundStyle(Theme.axisLabel)
        context.draw(text, at: point, anchor: anchor)
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%g", value)
    }

    private func drawCurves(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        for equation in equations {
            let vars = self.vars.with(equation.bindings)
            if let point = equation.compiled.point {
                let (x, y) = point(vars)
                guard x.isFinite, y.isFinite else { continue }
                let p = CGPoint(x: center.x + x * transform.scale, y: center.y - y * transform.scale)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)),
                             with: .color(equation.color))
            } else if let curve = equation.compiled.parametric {
                var path = Path()
                var last: CGPoint?
                let steps = 2000
                for i in 0...steps {
                    let range = equation.compiled.tRange
                    let (x, y) = curve(range.lowerBound + Double(i) / Double(steps) * (range.upperBound - range.lowerBound), vars)
                    guard x.isFinite, y.isFinite else { last = nil; continue }
                    let p = CGPoint(x: center.x + x * transform.scale, y: center.y - y * transform.scale)
                    // a huge jump between neighbouring samples is an asymptote, not a line to draw
                    if let last, hypot(p.x - last.x, p.y - last.y) <= size.height {
                        path.addLine(to: p)
                    } else {
                        path.move(to: p)
                    }
                    last = p
                }
                context.stroke(
                    path,
                    with: .color(equation.color),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                )
            } else if let fn = equation.compiled.function {
                var path = Path()
                var penDown = false
                var previousY = 0.0

                var px = 0.0
                while px < size.width {
                    let x = (px - center.x) / transform.scale
                    let y = fn(x, vars)
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
            } else if let implicitFn = equation.compiled.implicitFunction {
                let inequality = equation.compiled.inequality
                if let inequality {
                    // ponytail: shade on a coarse grid, cheap enough to redraw while panning
                    let cell = 6.0
                    var region = Path()
                    var py = 0.0
                    while py < size.height {
                        var px = 0.0
                        while px < size.width {
                            let x = (px + cell / 2 - center.x) / transform.scale
                            let y = (center.y - py - cell / 2) / transform.scale
                            if inequality.sign * implicitFn(x, y, vars) > 0 {
                                region.addRect(CGRect(x: px, y: py, width: cell, height: cell))
                            }
                            px += cell
                        }
                        py += cell
                    }
                    context.fill(region, with: .color(equation.color.opacity(0.18)))
                }
                var path = Path()
                for segment in traceImplicit({ implicitFn($0, $1, vars) }, size: size, center: center, scale: transform.scale) {
                    path.move(to: segment.0)
                    path.addLine(to: segment.1)
                }
                // The edge is many tiny segments, so a dash would restart on each and never show.
                // A strict edge (not part of the region) is drawn thin and faded instead.
                let strict = inequality?.strict == true
                context.stroke(
                    path,
                    with: .color(equation.color.opacity(strict ? 0.55 : 1)),
                    style: StrokeStyle(lineWidth: strict ? 1.5 : 2.2, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }

    /// Roots, extrema and intersections of the y = f(x) curves as small dots. A dot near the
    /// probe gets its coordinates, like the web app's hover readout.
    private func drawKeyPoints(_ context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        let curves = equations.compactMap { equation in
            equation.compiled.function.map { fn in
                let vars = self.vars.with(equation.bindings)
                return (fn: { fn($0, vars) }, colorIndex: equation.colorIndex)
            }
        }
        guard !curves.isEmpty else { return }
        let points = keyPoints(
            curves,
            xMin: -center.x / transform.scale,
            xMax: (size.width - center.x) / transform.scale
        )
        var nearest: (point: KeyPoint, at: CGPoint, distance: Double)?
        for point in points {
            let at = CGPoint(x: center.x + point.x * transform.scale, y: center.y - point.y * transform.scale)
            let dot = Path(ellipseIn: CGRect(x: at.x - 3.5, y: at.y - 3.5, width: 7, height: 7))
            context.fill(dot, with: .color(Theme.graphBackground))
            context.stroke(dot, with: .color(Theme.axis), lineWidth: 2)
            if let probe {
                let distance = hypot(at.x - probe.x, at.y - probe.y)
                if distance < 22, distance < (nearest?.distance ?? .infinity) { nearest = (point, at, distance) }
            }
        }
        guard let nearest else { return }
        let color = Palette.color(at: nearest.point.colorIndex)
        context.fill(Path(ellipseIn: CGRect(x: nearest.at.x - 5, y: nearest.at.y - 5, width: 10, height: 10)), with: .color(color))
        let label = Text(String(format: "(%.2f, %.2f)", nearest.point.x, nearest.point.y))
            .font(Theme.font(12, .medium))
            .foregroundStyle(color)
        context.draw(label, at: CGPoint(x: nearest.at.x + 10, y: nearest.at.y - 12), anchor: .leading)
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

// Roots, extrema and intersections of y = f(x) curves, Desmos's grey dots.
// Port of src/utils/keypoints.js: sign changes between samples, bisected, and thrown out
// when the bisection lands on an asymptote instead of a real zero.

import Foundation

struct KeyPoint {
    let x: Double
    let y: Double
    let colorIndex: Int
}

private let maxKeyPoints = 100

private func bisect(_ g: (Double) -> Double, _ lo: Double, _ hi: Double) -> Double {
    var a = lo, b = hi
    var ga = g(a)
    for _ in 0..<50 {
        let m = (a + b) / 2
        let gm = g(m)
        if (gm > 0) == (ga > 0) { a = m; ga = gm } else { b = m }
    }
    return (a + b) / 2
}

private func zeros(
    _ g: (Double) -> Double, _ xMin: Double, _ xMax: Double, _ samples: Int,
    accept: (Double) -> Bool
) -> [Double] {
    var out: [Double] = []
    let dx = (xMax - xMin) / Double(samples)
    var previous = g(xMin)
    for i in 1...samples {
        let x = xMin + Double(i) * dx
        let current = g(x)
        if current == 0 {
            out.append(x) // a sample landed right on it, there is no sign change to bisect
        } else if previous.isFinite, current.isFinite, previous * current < 0 {
            let z = bisect(g, x - dx, x)
            if accept(z) { out.append(z) }
        }
        previous = current
    }
    return out
}

func keyPoints(
    _ curves: [(fn: (Double) -> Double, colorIndex: Int)], xMin: Double, xMax: Double, samples: Int = 400
) -> [KeyPoint] {
    var points: [KeyPoint] = []
    func add(_ x: Double, _ y: Double, _ colorIndex: Int) {
        guard y.isFinite, !points.contains(where: { abs($0.x - x) < 1e-7 && abs($0.y - y) < 1e-7 }) else { return }
        points.append(KeyPoint(x: x, y: abs(y) < 1e-12 ? 0 : y, colorIndex: colorIndex))
    }
    let h = (xMax - xMin) * 1e-6
    for curve in curves {
        let f = curve.fn
        for x in zeros(f, xMin, xMax, samples, accept: { abs(f($0)) < 1e-6 }) { add(x, 0, curve.colorIndex) }
        let slope = { (x: Double) in (f(x + h) - f(x - h)) / (2 * h) }
        // a real extremum has a small slope; one bisected onto an asymptote does not
        for x in zeros(slope, xMin, xMax, samples, accept: { abs(slope($0)) < 1e-2 * max(1, abs(f($0))) }) {
            add(x, f(x), curve.colorIndex)
        }
    }
    for i in curves.indices {
        for j in curves.indices where j > i {
            let g = { (x: Double) in curves[i].fn(x) - curves[j].fn(x) }
            for x in zeros(g, xMin, xMax, samples, accept: { abs(g($0)) < 1e-6 }) {
                add(x, curves[i].fn(x), curves[i].colorIndex)
            }
        }
    }
    return points.count > maxKeyPoints ? [] : points
}

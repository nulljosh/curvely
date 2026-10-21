// Roots, extrema and intersections of y = f(x) curves over [xMin, xMax], Desmos's grey dots.
// Each is found as a sign change between samples, then bisected. A sign change across an
// asymptote (tan, 1/x) bisects to a point where the value is huge, so it is thrown out.

const MAX_POINTS = 100;

function safe(f, x) {
  try {
    const y = f(x);
    return Number.isFinite(y) ? y : NaN;
  } catch {
    return NaN;
  }
}

function bisect(g, a, b) {
  let ga = g(a);
  for (let i = 0; i < 50; i++) {
    const m = (a + b) / 2;
    const gm = g(m);
    if (Math.sign(gm) === Math.sign(ga)) { a = m; ga = gm; } else b = m;
  }
  return (a + b) / 2;
}

// Every sign change of g between samples, bisected and kept only if g really is ~0 there.
function zeros(g, xMin, xMax, samples, accept) {
  const out = [];
  const dx = (xMax - xMin) / samples;
  let prev = g(xMin);
  for (let i = 1; i <= samples; i++) {
    const x = xMin + i * dx;
    const cur = g(x);
    if (cur === 0) {
      out.push(x); // a sample landed right on it, there is no sign change to bisect
    } else if (Number.isFinite(prev) && Number.isFinite(cur) && prev * cur < 0) {
      const z = bisect(g, x - dx, x);
      if (accept(z)) out.push(z);
    }
    prev = cur;
  }
  return out;
}

// fns: [{ fn: x => y, color }]. Returns [{ x, y, color }].
export function keyPoints(fns, xMin, xMax, samples = 400) {
  const pts = [];
  const add = (x, y, color) => {
    if (!Number.isFinite(y)) return;
    if (pts.some((p) => Math.abs(p.x - x) < 1e-7 && Math.abs(p.y - y) < 1e-7)) return;
    pts.push({ x, y: Math.abs(y) < 1e-12 ? 0 : y, color });
  };
  const h = (xMax - xMin) * 1e-6;
  for (const { fn, color } of fns) {
    const f = (x) => safe(fn, x);
    for (const x of zeros(f, xMin, xMax, samples, (z) => Math.abs(f(z)) < 1e-6)) add(x, 0, color);
    const slope = (x) => (f(x + h) - f(x - h)) / (2 * h);
    // a real extremum has a small slope; one bisected onto an asymptote does not
    for (const x of zeros(slope, xMin, xMax, samples, (z) => Math.abs(slope(z)) < 1e-2 * Math.max(1, Math.abs(f(z))))) add(x, f(x), color);
  }
  for (let i = 0; i < fns.length; i++) {
    for (let j = i + 1; j < fns.length; j++) {
      const a = (x) => safe(fns[i].fn, x);
      const g = (x) => a(x) - safe(fns[j].fn, x);
      for (const x of zeros(g, xMin, xMax, samples, (z) => Math.abs(g(z)) < 1e-6)) add(x, a(x), fns[i].color);
    }
  }
  return pts.length > MAX_POINTS ? [] : pts;
}

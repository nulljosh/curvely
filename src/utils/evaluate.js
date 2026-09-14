import { parse } from 'mathjs';

// A vertical asymptote (tan(x), 1/x) yields two finite but huge values of opposite sign on
// adjacent pixels. Joining them draws a false vertical line, so the stroke has to break.
export function isAsymptoteJump(prevY, y, scale, height) {
  return Math.sign(y) !== Math.sign(prevY) && Math.abs(y - prevY) * scale > height * 2;
}

// `a = 3` defines a slider instead of a curve; distinct from `y = ...` curve definitions.
const SLIDER_RE = /^([a-zA-Z]\w*)\s*=\s*(-?\d+(?:\.\d+)?)$/;

export function parseSlider(expr) {
  const m = expr.trim().match(SLIDER_RE);
  if (!m || m[1] === 'x' || m[1] === 'y') return null;
  return { name: m[1], value: Number(m[2]) };
}

export function evaluate(expr) {
  if (parseSlider(expr)) return { fn: null, error: null };
  const cleaned = expr.replace(/^y\s*=\s*/i, '').trim();
  if (!cleaned) return { fn: null, error: null };
  try {
    const compiled = parse(cleaned).compile();
    return { fn: (x, sliders) => compiled.evaluate({ x, ...sliders }), error: null };
  } catch (e) {
    return { fn: null, error: e.message };
  }
}

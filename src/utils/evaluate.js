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

// Any `=` not of the form `y = ...` is an implicit equation (x^2+y^2=1, x=3, ...):
// solved as f(x,y)=lhs-rhs=0 by marching squares instead of walking y=f(x) per pixel.
export function isImplicit(expr) {
  const cleaned = expr.trim();
  return cleaned.includes('=') && !/^y\s*=/i.test(cleaned) && !parseSlider(cleaned);
}

export function evaluate(expr) {
  if (parseSlider(expr)) return { fn: null, implicitFn: null, error: null };
  const cleaned = expr.trim();
  if (!cleaned) return { fn: null, implicitFn: null, error: null };

  if (isImplicit(cleaned)) {
    const idx = cleaned.indexOf('=');
    const lhs = cleaned.slice(0, idx).trim();
    const rhs = cleaned.slice(idx + 1).trim();
    try {
      const lc = parse(lhs).compile();
      const rc = parse(rhs).compile();
      const implicitFn = (x, y, sliders) =>
        lc.evaluate({ x, y, ...sliders }) - rc.evaluate({ x, y, ...sliders });
      return { fn: null, implicitFn, error: null };
    } catch (e) {
      return { fn: null, implicitFn: null, error: e.message };
    }
  }

  const stripped = cleaned.replace(/^y\s*=\s*/i, '').trim();
  try {
    const compiled = parse(stripped).compile();
    return { fn: (x, sliders) => compiled.evaluate({ x, ...sliders }), implicitFn: null, error: null };
  } catch (e) {
    return { fn: null, implicitFn: null, error: e.message };
  }
}

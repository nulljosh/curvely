import { parse } from 'mathjs';

// A vertical asymptote (tan(x), 1/x) yields two finite but huge values of opposite sign on
// adjacent pixels. Joining them draws a false vertical line, so the stroke has to break.
export function isAsymptoteJump(prevY, y, scale, height) {
  return Math.sign(y) !== Math.sign(prevY) && Math.abs(y - prevY) * scale > height * 2;
}

export function evaluate(expr) {
  const cleaned = expr.replace(/^y\s*=\s*/i, '').trim();
  if (!cleaned) return { fn: null, error: null };
  try {
    const compiled = parse(cleaned).compile();
    return { fn: (x) => compiled.evaluate({ x }), error: null };
  } catch (e) {
    return { fn: null, error: e.message };
  }
}

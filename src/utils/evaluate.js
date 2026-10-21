import { parse, derivative, evaluate as mathEvaluate } from 'mathjs';

// A vertical asymptote (tan(x), 1/x) yields two finite but huge values of opposite sign on
// adjacent pixels. Joining them draws a false vertical line, so the stroke has to break.
export function isAsymptoteJump(prevY, y, scale, height) {
  return Math.sign(y) !== Math.sign(prevY) && Math.abs(y - prevY) * scale > height * 2;
}

// `a = 3` defines a slider instead of a curve; distinct from `y = ...` curve definitions.
// `a = 3 {0 < a < 10}` also sets its range; without one the range is -10 to 10, widened to fit.
const SLIDER_RE = /^([a-zA-Z]\w*)\s*=\s*(-?\d+(?:\.\d+)?)\s*(?:\{([^{}]*)\})?$/;

// `0 < a < 10`, `-pi <= t <= pi`: the numeric bounds around one name, or null.
export function parseRange(cond, name) {
  const m = cond.match(/^(.+?)(<=|<)\s*([a-zA-Z]\w*)\s*(<=|<)(.+)$/);
  if (!m || m[3] !== name) return null;
  try {
    const [lo, hi] = [mathEvaluate(m[1]), mathEvaluate(m[5])];
    return Number.isFinite(lo) && Number.isFinite(hi) && lo < hi ? [lo, hi] : null;
  } catch {
    return null;
  }
}

// x, y and t are variables; r and theta belong to polar curves.
const RESERVED = new Set(['x', 'y', 't', 'r', 'theta']);

export function parseSlider(expr) {
  const m = expr.trim().match(SLIDER_RE);
  if (!m || RESERVED.has(m[1])) return null;
  const value = Number(m[2]);
  if (m[3] !== undefined) {
    const range = parseRange(m[3], m[1]);
    if (!range) return null;
    return { name: m[1], value, min: range[0], max: range[1] };
  }
  return { name: m[1], value, min: Math.min(-10, value), max: Math.max(10, value) };
}

// A parametric or polar row ending in `{0 < t < pi}` (or theta) runs t over that range
// instead of 0 to 2 pi. Any other trailing braces stay for desugar() to handle.
export function takeTRange(expr) {
  const m = expr.match(/^(.+?)\s*\{([^{}:]+)\}$/);
  const range = m && (parseRange(m[2], 't') || parseRange(m[2], 'theta'));
  return range ? { expr: m[1].trim(), tMin: range[0], tMax: range[1] } : { expr, tMin: 0, tMax: T_MAX };
}

// Any `=` not of the form `y = ...` is an implicit equation (x^2+y^2=1, x=3, ...):
// solved as f(x,y)=lhs-rhs=0 by marching squares instead of walking y=f(x) per pixel.
// Piecewise and domain-limit braces hold their own < and =, which say nothing about the row.
const outsideBraces = (s) => s.replace(/\{[^{}]*\}/g, '');

export function isImplicit(expr) {
  const cleaned = outsideBraces(expr.trim());
  return cleaned.includes('=') && !/^[yr]\s*=/i.test(cleaned) && !parseSlider(cleaned);
}

// `(a, b)`: the outer parens must wrap the whole thing and hold exactly one top-level comma.
export function splitPair(expr) {
  const s = expr.trim();
  if (s[0] !== '(' || s[s.length - 1] !== ')') return null;
  let depth = 0;
  let comma = -1;
  for (let i = 0; i < s.length; i++) {
    if (s[i] === '(') depth++;
    else if (s[i] === ')' && --depth === 0 && i !== s.length - 1) return null;
    else if (s[i] === ',' && depth === 1) {
      if (comma !== -1) return null;
      comma = i;
    }
  }
  return comma === -1 ? null : [s.slice(1, comma).trim(), s.slice(comma + 1, -1).trim()];
}

const usesT = (node) => node.filter((n) => n.isSymbolNode && n.name === 't').length > 0;

// Parametric and polar curves are sampled over t (or theta) in [0, 2 pi].
// ponytail: fixed domain, a per-row range like Desmos's can come later.
export const T_MAX = Math.PI * 2;

// `y > x^2`, `x^2+y^2 <= 4`: exactly one comparison, nothing else on either side.
export function splitInequality(expr) {
  if (expr.includes('{')) return null;
  const m = expr.match(/^([^<>=]+)(<=|>=|<|>)([^<>=]+)$/);
  if (!m) return null;
  return { lhs: m[1].trim(), rhs: m[3].trim(), sign: m[2][0] === '>' ? 1 : -1, strict: m[2].length === 1 };
}

// `f(x) = x^2` defines f for every other row, and draws itself as y = f(x).
const FUNC_RE = /^([a-zA-Z]\w*)\(\s*([a-zA-Z]\w*)\s*\)\s*=\s*(.+)$/;

// `sin(x) = cos(y)` is an equation, not a new definition of sin: ask mathjs whether the name is
// already a function (case-sensitive, like mathjs), the way Swift checks its functions table.
function isBuiltin(name) {
  if (name === 'ln') return true; // desugar() maps it to log
  try {
    return typeof parse(name).evaluate() === 'function';
  } catch {
    return false;
  }
}

export function parseFunctionDef(expr) {
  const m = expr.trim().match(FUNC_RE);
  if (!m || m[1] === 'y' || m[1] === 'r' || isBuiltin(m[1])) return null;
  return { name: m[1], param: m[2], body: m[3] };
}

// Split on commas that sit at bracket depth 0.
function splitTop(s) {
  const out = [];
  let depth = 0;
  let start = 0;
  for (let i = 0; i < s.length; i++) {
    if ('([{'.includes(s[i])) depth++;
    else if (')]}'.includes(s[i])) depth--;
    else if (s[i] === ',' && depth === 0) { out.push(s.slice(start, i)); start = i + 1; }
  }
  out.push(s.slice(start));
  return out.map((p) => p.trim());
}

// Desmos syntax mathjs does not read, rewritten into syntax it does:
//   x^2 {0 < x < 2}       ->  ((0 < x < 2) ? (x^2) : NaN)      domain limit
//   {x < 0: -x, x}         ->  ((x < 0) ? (-x) : (x))           piecewise
//   f'(x), f''(x)          ->  f__d1(x), f__d2(x)                derivative of a defined function
//   d/dx(sin(x))           ->  cos(x)                            symbolic derivative
export function desugar(expr) {
  let s = expr.trim();
  const limit = s.match(/^(.+?)\s*\{([^{}:]+)\}$/);
  if (limit && !limit[1].trim().endsWith(',')) s = `((${limit[2]}) ? (${limit[1]}) : NaN)`;
  for (let guard = 0; guard < 20; guard++) {
    const open = s.search(/\{[^{}]*:[^{}]*\}/);
    if (open === -1) break;
    const close = s.indexOf('}', open);
    const parts = splitTop(s.slice(open + 1, close));
    let out = 'NaN';
    for (let i = parts.length - 1; i >= 0; i--) {
      const colon = parts[i].indexOf(':');
      out = colon === -1 ? `(${parts[i]})` : `((${parts[i].slice(0, colon)}) ? (${parts[i].slice(colon + 1)}) : ${out})`;
    }
    s = s.slice(0, open) + `(${out})` + s.slice(close + 1);
  }
  s = s.replace(/(?<![A-Za-z_])ln\(/g, 'log('); // mathjs log is the natural log; `2ln(x)` too
  s = s.replace(/([a-zA-Z]\w*)''\(/g, '$1__d2(').replace(/([a-zA-Z]\w*)'\(/g, '$1__d1(');
  for (let guard = 0; guard < 20; guard++) {
    const at = s.indexOf('d/dx(');
    if (at === -1) break;
    let depth = 0;
    let end = at + 4;
    for (; end < s.length; end++) {
      if (s[end] === '(') depth++;
      else if (s[end] === ')' && --depth === 0) break;
    }
    const inner = s.slice(at + 5, end);
    s = s.slice(0, at) + `(${derivative(inner, 'x').toString()})` + s.slice(end + 1);
  }
  return s;
}

// The scope every row evaluates in: slider values plus the functions `f(x) = ...` rows define,
// each with numeric first and second derivatives for f'(x) and f''(x).
export function buildScope(exprs, sliderValues) {
  const scope = { ...sliderValues };
  const H = 1e-4;
  for (const expr of exprs) {
    const def = parseFunctionDef(expr);
    if (!def) continue;
    let body;
    try { body = parse(desugar(def.body)).compile(); } catch { continue; }
    const f = (v) => body.evaluate({ ...scope, [def.param]: v });
    scope[def.name] = f;
    scope[`${def.name}__d1`] = (v) => (f(v + H) - f(v - H)) / (2 * H);
    scope[`${def.name}__d2`] = (v) => (f(v + H) - 2 * f(v) + f(v - H)) / (H * H);
  }
  return scope;
}

export function evaluate(expr) {
  if (parseSlider(expr)) return { fn: null, implicitFn: null, error: null };
  const cleaned = expr.trim();
  if (!cleaned) return { fn: null, implicitFn: null, error: null };

  const def = parseFunctionDef(cleaned);
  if (def) {
    try {
      parse(desugar(def.body));
      return { fn: (x, scope) => scope[def.name](x), implicitFn: null, error: null };
    } catch (e) {
      return { fn: null, implicitFn: null, error: e.message };
    }
  }

  const ineq = splitInequality(cleaned);
  if (ineq) {
    try {
      const lc = parse(desugar(ineq.lhs)).compile();
      const rc = parse(desugar(ineq.rhs)).compile();
      // region where sign * implicitFn > 0, edge where it is 0
      const implicitFn = (x, y, sliders) =>
        lc.evaluate({ x, y, ...sliders }) - rc.evaluate({ x, y, ...sliders });
      return { fn: null, implicitFn, inequality: { sign: ineq.sign, strict: ineq.strict }, error: null };
    } catch (e) {
      return { fn: null, implicitFn: null, error: e.message };
    }
  }

  const ranged = takeTRange(cleaned);
  const polar = ranged.expr.match(/^r\s*=\s*(.+)$/i);
  if (polar) {
    try {
      const rc = parse(desugar(polar[1])).compile();
      const paramFn = (t, sliders) => {
        const r = rc.evaluate({ theta: t, t, ...sliders });
        return [r * Math.cos(t), r * Math.sin(t)];
      };
      return { fn: null, implicitFn: null, paramFn, tMin: ranged.tMin, tMax: ranged.tMax, error: null };
    } catch (e) {
      return { fn: null, implicitFn: null, error: e.message };
    }
  }

  const pair = splitPair(ranged.expr);
  if (pair) {
    try {
      const [xn, yn] = pair.map((p) => parse(desugar(p)));
      const [xc, yc] = [xn.compile(), yn.compile()];
      if (usesT(xn) || usesT(yn)) {
        const paramFn = (t, sliders) => [xc.evaluate({ t, ...sliders }), yc.evaluate({ t, ...sliders })];
        return { fn: null, implicitFn: null, paramFn, tMin: ranged.tMin, tMax: ranged.tMax, error: null };
      }
      const pointFn = (sliders) => [xc.evaluate({ ...sliders }), yc.evaluate({ ...sliders })];
      return { fn: null, implicitFn: null, pointFn, error: null };
    } catch (e) {
      return { fn: null, implicitFn: null, error: e.message };
    }
  }

  if (isImplicit(cleaned)) {
    const idx = cleaned.indexOf('=');
    const lhs = cleaned.slice(0, idx).trim();
    const rhs = cleaned.slice(idx + 1).trim();
    try {
      const lc = parse(desugar(lhs)).compile();
      const rc = parse(desugar(rhs)).compile();
      const implicitFn = (x, y, sliders) =>
        lc.evaluate({ x, y, ...sliders }) - rc.evaluate({ x, y, ...sliders });
      return { fn: null, implicitFn, error: null };
    } catch (e) {
      return { fn: null, implicitFn: null, error: e.message };
    }
  }

  const stripped = cleaned.replace(/^y\s*=\s*/i, '').trim();
  try {
    const compiled = parse(desugar(stripped)).compile();
    return { fn: (x, sliders) => compiled.evaluate({ x, ...sliders }), implicitFn: null, error: null };
  } catch (e) {
    return { fn: null, implicitFn: null, error: e.message };
  }
}

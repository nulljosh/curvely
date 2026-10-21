import { evaluate } from './evaluate.js';

// Lists, Desmos style. `L = [1, 2, 3]` defines a list. A row that uses a list, or holds a list
// literal like `sin(x) + [0, 1, 2]`, draws once per element with the list bound to that element.
// A list of points `[(1, 2), (2, 4)]` is the same thing: two lists, one point row.
//
// expandRow rewrites the row once (literals become named lists) and returns one binding per
// copy, so the row compiles once and each copy only swaps the bound values.

const MAX_ITEMS = 1000;
const NUM = '-?\\d+(?:\\.\\d+)?';

// `1, 2, 3` or `1...10` -> numbers, or null when it is not a plain list.
function parseItems(inner) {
  const range = inner.match(new RegExp(`^\\s*(${NUM})\\s*\\.\\.\\.\\s*(${NUM})\\s*$`));
  if (range) {
    const [a, b] = [Number(range[1]), Number(range[2])];
    if (b < a || b - a >= MAX_ITEMS) return null;
    return Array.from({ length: Math.floor(b - a) + 1 }, (_, i) => a + i);
  }
  const parts = inner.split(',').map((p) => p.trim());
  if (!parts.every((p) => new RegExp(`^${NUM}$`).test(p))) return null;
  return parts.map(Number);
}

const LIST_DEF_RE = /^([a-zA-Z]\w*)\s*=\s*\[([^\[\]]*)\]$/;

export function parseListDef(expr) {
  const m = expr.trim().match(LIST_DEF_RE);
  if (!m) return null;
  const items = parseItems(m[2]);
  return items ? { name: m[1], items } : null;
}

// `[(1, 2), (2, 4)]` -> { xs, ys } or null
function parsePointList(inner) {
  const pts = [...inner.matchAll(new RegExp(`\\(\\s*(${NUM})\\s*,\\s*(${NUM})\\s*\\)`, 'g'))];
  const rest = inner.replace(new RegExp(`\\(\\s*${NUM}\\s*,\\s*${NUM}\\s*\\)`, 'g'), '').replace(/[\s,]/g, '');
  if (!pts.length || rest) return null;
  return { xs: pts.map((m) => Number(m[1])), ys: pts.map((m) => Number(m[2])) };
}

// -> { source, binds: [{ name: value }] } ; binds is [{}] when the row uses no list.
export function expandRow(expr, lists) {
  const trimmed = expr.trim();
  if (parseListDef(trimmed)) return { source: trimmed, binds: [] }; // a definition draws nothing
  const local = {};
  let n = 0;
  const name = () => `qlist${n++}`;
  let source = trimmed;
  const whole = trimmed.match(/^\[(.*)\]$/);
  const pointList = whole && parsePointList(whole[1]);
  if (pointList) {
    const [xn, yn] = [name(), name()];
    local[xn] = pointList.xs;
    local[yn] = pointList.ys;
    source = `(${xn}, ${yn})`;
  } else {
    source = trimmed.replace(/\[([^\[\]]*)\]/g, (all, inner) => {
      const items = parseItems(inner);
      if (!items) return all;
      const ln = name();
      local[ln] = items;
      return ln;
    });
  }
  const all = { ...lists, ...local };
  // not \\b: `0.05shell` uses shell, and a digit-to-letter step is no word boundary
  const used = Object.keys(all).filter((ln) => new RegExp(`(?<![A-Za-z_])${ln}(?!\\w)`).test(source));
  if (!used.length) return { source, binds: [{}] };
  const len = Math.min(...used.map((ln) => all[ln].length));
  const binds = Array.from({ length: len }, (_, i) => Object.fromEntries(used.map((ln) => [ln, all[ln][i]])));
  return { source, binds };
}

// What a row's own input box shows: a list definition is fine as is, and a row holding list
// literals is checked in its rewritten form, which is what actually gets drawn.
export function evaluateRow(expr) {
  if (parseListDef(expr)) return { fn: null, implicitFn: null, error: null };
  return evaluate(expandRow(expr, {}).source);
}

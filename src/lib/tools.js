// The one definition of what Curvely can do over the network. Both surfaces — the REST
// routes in functions/api/ and the MCP server in functions/mcp.js — call `callTool` from
// here, so they cannot drift apart.
//
// Deliberately narrower than src/lib/webmcp.js: those tools mutate the live graph
// (plot_equation, update_equation, remove_equation, clear_graph). A stateless server has
// no graph to mutate, so these are transforms — an expression goes in, numbers come out.

import { parse } from 'mathjs';

export const MAX_EXPR = 512;
export const MAX_SAMPLES = 2000;
const MAX_ABS_X = 1e12;

class ToolError extends Error {}

// ---------------------------------------------------------------------------------------
// The fence.
//
// This endpoint is public and unauthenticated, and mathjs compiles arbitrary source. Its
// parser accepts far more than "a curve to plot" — assignment, function definition, object
// and index access, unit construction — and that surface is where mathjs's historical
// sandbox escapes have lived. So rather than blocklisting the dangerous forms (which fails
// open on anything new), walk the parsed AST and reject every node that is not on this
// allowlist (which fails closed).
//
// The browser build deliberately does NOT use this: there, the user is evaluating their own
// expression in their own tab, and a stricter parser would just be a worse grapher.
// ---------------------------------------------------------------------------------------

const ALLOWED_NODES = new Set([
  'ConstantNode', 'OperatorNode', 'ParenthesisNode', 'SymbolNode', 'FunctionNode',
]);

const ALLOWED_FUNCTIONS = new Set([
  'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2',
  'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
  'sqrt', 'cbrt', 'abs', 'sign', 'exp', 'log', 'log2', 'log10',
  'floor', 'ceil', 'round', 'min', 'max', 'pow', 'hypot', 'mod',
]);

// `x` is the plot variable; the rest are constants mathjs resolves itself.
const ALLOWED_SYMBOLS = new Set(['x', 'pi', 'e', 'tau', 'phi']);

function assertSafe(node) {
  const type = node.type;
  if (!ALLOWED_NODES.has(type)) {
    throw new ToolError(`Unsupported syntax (${type}). Give a plain expression in x, such as "sin(x)/x".`);
  }
  if (type === 'FunctionNode') {
    // A FunctionNode whose callee is not a bare name is an accessor in disguise.
    const name = node.fn?.name;
    if (!name || !ALLOWED_FUNCTIONS.has(name)) {
      throw new ToolError(`Unsupported function: ${name ?? 'anonymous'}.`);
    }
    // Recurse into the arguments ONLY. The callee is itself a SymbolNode and forEach would
    // visit it, so a generic walk rejects every legitimate call ("Unknown symbol: sqrt").
    node.args.forEach(assertSafe);
    return;
  }
  if (type === 'SymbolNode' && !ALLOWED_SYMBOLS.has(node.name)) {
    throw new ToolError(`Unknown symbol: ${node.name}. Only x, pi, e, tau and phi are available.`);
  }
  node.forEach(assertSafe);
}

/// Parses and fences an expression, returning a compiled f(x). Throws ToolError on anything
/// that is not a plottable expression in x.
function compileExpression(raw) {
  if (typeof raw !== 'string') throw new ToolError('expr must be a string');
  const cleaned = raw.replace(/^y\s*=\s*/i, '').trim();
  if (!cleaned) throw new ToolError('expr is empty');
  if (cleaned.length > MAX_EXPR) throw new ToolError(`expr exceeds ${MAX_EXPR} characters`);

  let node;
  try {
    node = parse(cleaned);
  } catch (err) {
    throw new ToolError(`Could not parse: ${err.message}`);
  }
  // parse() accepts `a; b` as a BlockNode, which would slip multiple statements through.
  assertSafe(node);

  const compiled = node.compile();
  return (x) => {
    const y = compiled.evaluate({ x });
    // mathjs can return a Complex, Unit, Matrix or BigNumber. Anything but a plain finite
    // number is not a point on a curve.
    return typeof y === 'number' && Number.isFinite(y) ? y : null;
  };
}

const num = (v, name, { min, max }) => {
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isFinite(n)) throw new ToolError(`${name} must be a finite number, got ${JSON.stringify(v)}`);
  if (n < min || n > max) throw new ToolError(`${name} must be between ${min} and ${max}, got ${n}`);
  return n;
};

const EXPR = {
  type: 'string',
  description: 'An expression in x, e.g. "sin(x)/x" or "x^2 - 3". A leading "y =" is ignored.',
};

export const TOOLS = [
  {
    name: 'evaluate_expression',
    description:
      'Evaluate an expression at specific x values. Returns a y for each, or null where the ' +
      'result is undefined or non-real (asymptotes, sqrt of a negative). Reports parse errors ' +
      'rather than throwing.',
    inputSchema: {
      type: 'object',
      properties: {
        expr: EXPR,
        xValues: { type: 'array', items: { type: 'number' }, description: `x values, at most ${MAX_SAMPLES}.` },
      },
      required: ['expr', 'xValues'],
    },
  },
  {
    name: 'sample_expression',
    description:
      'Sample an expression evenly across a range — the numbers behind the curve, without an ' +
      'image. Use it to find roots, turning points or asymptotes.',
    inputSchema: {
      type: 'object',
      properties: {
        expr: EXPR,
        from: { type: 'number', description: 'Start of the x range. Default -10.' },
        to: { type: 'number', description: 'End of the x range. Default 10.' },
        samples: { type: 'integer', description: `How many points. Default 200, max ${MAX_SAMPLES}.` },
      },
      required: ['expr'],
    },
  },
  {
    name: 'list_syntax',
    description: 'The functions, constants and operators an expression may use. Call this if an expression is rejected.',
    inputSchema: { type: 'object', properties: {} },
  },
];

export const TOOL_NAMES = TOOLS.map(t => t.name);

export function callTool(name, rawArgs) {
  const args = rawArgs && typeof rawArgs === 'object' && !Array.isArray(rawArgs) ? rawArgs : {};

  switch (name) {
    case 'list_syntax':
      return {
        functions: [...ALLOWED_FUNCTIONS].sort(),
        constants: [...ALLOWED_SYMBOLS].filter(s => s !== 'x').sort(),
        variable: 'x',
        operators: ['+', '-', '*', '/', '^', '%', 'unary -'],
        limits: { maxExpressionLength: MAX_EXPR, maxSamples: MAX_SAMPLES },
      };

    case 'evaluate_expression': {
      const { xValues } = args;
      if (!Array.isArray(xValues)) throw new ToolError('xValues must be an array of numbers');
      if (xValues.length === 0) throw new ToolError('xValues is empty');
      if (xValues.length > MAX_SAMPLES) throw new ToolError(`xValues exceeds ${MAX_SAMPLES} entries`);
      const fn = compileExpression(args.expr);
      return {
        expr: args.expr,
        points: xValues.map((x, i) => {
          const xn = num(x, `xValues[${i}]`, { min: -MAX_ABS_X, max: MAX_ABS_X });
          return { x: xn, y: fn(xn) };
        }),
      };
    }

    case 'sample_expression': {
      const from = num(args.from ?? -10, 'from', { min: -MAX_ABS_X, max: MAX_ABS_X });
      const to = num(args.to ?? 10, 'to', { min: -MAX_ABS_X, max: MAX_ABS_X });
      if (from === to) throw new ToolError('from and to must differ');
      const samples = num(args.samples ?? 200, 'samples', { min: 2, max: MAX_SAMPLES });
      if (!Number.isInteger(samples)) throw new ToolError('samples must be a whole number');
      const fn = compileExpression(args.expr);
      const step = (to - from) / (samples - 1);
      const points = Array.from({ length: samples }, (_, i) => {
        const x = from + step * i;
        return { x, y: fn(x) };
      });
      const defined = points.filter(p => p.y !== null);
      return {
        expr: args.expr,
        from,
        to,
        samples,
        points,
        // Cheap summary so a caller does not have to scan the array to learn the shape.
        range: defined.length
          ? { min: Math.min(...defined.map(p => p.y)), max: Math.max(...defined.map(p => p.y)) }
          : null,
        undefinedCount: points.length - defined.length,
      };
    }

    default:
      return null;
  }
}

export { ToolError, compileExpression };

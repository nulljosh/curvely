// evaluate.test.js already covers the browser evaluator. This covers what the network
// surfaces add: untrusted input reaching callTool, and above all the AST fence — this
// endpoint is public and hands caller-supplied source to mathjs.

import { describe, it, expect } from 'vitest';
import { callTool, ToolError, MAX_EXPR, MAX_SAMPLES } from './tools.js';

const bad = (name, args) => expect(() => callTool(name, args)).toThrow(ToolError);
const at = (expr, x) => callTool('evaluate_expression', { expr, xValues: [x] }).points[0].y;

describe('the mathjs fence', () => {
  // Each of these parses fine in mathjs and must NOT reach compile().
  it('rejects assignment', () => bad('evaluate_expression', { expr: 'a = 5', xValues: [1] }));
  it('rejects function definition', () => bad('evaluate_expression', { expr: 'f(y) = y^2', xValues: [1] }));
  it('rejects multiple statements', () => bad('evaluate_expression', { expr: 'x; 2', xValues: [1] }));
  it('rejects property access', () => bad('evaluate_expression', { expr: 'x.constructor', xValues: [1] }));
  it('rejects index access', () => bad('evaluate_expression', { expr: '[1,2][1]', xValues: [1] }));
  it('rejects object literals', () => bad('evaluate_expression', { expr: '{a: 1}', xValues: [1] }));
  it('rejects unknown symbols', () => bad('evaluate_expression', { expr: 'foo + x', xValues: [1] }));
  it('rejects non-allowlisted functions', () => {
    bad('evaluate_expression', { expr: 'createUnit("z")', xValues: [1] });
    bad('evaluate_expression', { expr: 'import("x")', xValues: [1] });
    bad('evaluate_expression', { expr: 'config({})', xValues: [1] });
  });
  it('rejects an over-long expression', () => {
    bad('evaluate_expression', { expr: 'x+'.repeat(MAX_EXPR) + 'x', xValues: [1] });
  });

  it('still allows ordinary curves', () => {
    expect(at('x^2', 3)).toBe(9);
    expect(at('y = 2*x + 1', 2)).toBe(5);
    expect(at('sin(x)', 0)).toBe(0);
    expect(at('sqrt(x)', 9)).toBe(3);
    expect(at('abs(-x)', 4)).toBe(4);
    expect(at('max(x, 2)', 5)).toBe(5);
    expect(Math.round(at('pi', 0) * 100) / 100).toBe(3.14);
  });

  it('returns null rather than a non-real value', () => {
    expect(at('sqrt(x)', -1)).toBeNull();   // Complex
    expect(at('1/x', 0)).toBeNull();        // Infinity
  });
});

describe('evaluate_expression', () => {
  it('requires a non-empty xValues array', () => {
    bad('evaluate_expression', { expr: 'x', xValues: [] });
    bad('evaluate_expression', { expr: 'x', xValues: 'nope' });
    bad('evaluate_expression', { expr: 'x' });
  });
  it('caps the number of points', () => {
    bad('evaluate_expression', { expr: 'x', xValues: new Array(MAX_SAMPLES + 1).fill(0) });
  });
  it('rejects a non-finite x', () => {
    bad('evaluate_expression', { expr: 'x', xValues: [Infinity] });
    bad('evaluate_expression', { expr: 'x', xValues: ['abc'] });
  });
  it('rejects an empty or non-string expr', () => {
    bad('evaluate_expression', { expr: '', xValues: [1] });
    bad('evaluate_expression', { expr: 42, xValues: [1] });
  });
});

describe('sample_expression', () => {
  it('samples the default range', () => {
    const r = callTool('sample_expression', { expr: 'x' });
    expect(r.points).toHaveLength(200);
    expect(r.points[0].x).toBe(-10);
    expect(r.points[199].x).toBeCloseTo(10);
    expect(r.range).toEqual({ min: -10, max: 10 });
    expect(r.undefinedCount).toBe(0);
  });
  it('counts undefined points instead of dropping them', () => {
    const r = callTool('sample_expression', { expr: 'sqrt(x)', from: -4, to: -1, samples: 4 });
    expect(r.undefinedCount).toBe(4);
    expect(r.range).toBeNull();
  });
  it('rejects a degenerate or oversized range', () => {
    bad('sample_expression', { expr: 'x', from: 1, to: 1 });
    bad('sample_expression', { expr: 'x', samples: 1 });
    bad('sample_expression', { expr: 'x', samples: MAX_SAMPLES + 1 });
    bad('sample_expression', { expr: 'x', samples: 10.5 });
  });
});

describe('dispatch', () => {
  it('returns null for an unknown tool so callers can 404 it', () => {
    expect(callTool('nope', {})).toBeNull();
  });
  it('survives null arguments', () => {
    expect(callTool('list_syntax', null).variable).toBe('x');
  });
});

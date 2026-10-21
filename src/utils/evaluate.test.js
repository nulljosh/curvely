import { describe, it, expect } from 'vitest';
import { evaluate, isAsymptoteJump, parseSlider, isImplicit, splitPair, splitInequality, buildScope, desugar, parseFunctionDef } from './evaluate.js';

describe('evaluate', () => {
  it('returns null fn for empty string', () => {
    const { fn, error } = evaluate('');
    expect(fn).toBeNull();
    expect(error).toBeNull();
  });

  it('strips y = prefix', () => {
    const { fn, error } = evaluate('y = x');
    expect(error).toBeNull();
    expect(fn(3)).toBe(3);
  });

  it('strips y= prefix without spaces', () => {
    const { fn } = evaluate('y=x');
    expect(fn(5)).toBe(5);
  });

  it('evaluates quadratic', () => {
    const { fn, error } = evaluate('x^2');
    expect(error).toBeNull();
    expect(fn(3)).toBe(9);
    expect(fn(-2)).toBe(4);
  });

  it('evaluates linear expression', () => {
    const { fn } = evaluate('2*x + 1');
    expect(fn(0)).toBe(1);
    expect(fn(4)).toBe(9);
  });

  it('evaluates constants', () => {
    const { fn } = evaluate('42');
    expect(fn(0)).toBe(42);
    expect(fn(999)).toBe(42);
  });

  it('returns error for invalid expression', () => {
    const { fn, error } = evaluate('!!invalid');
    expect(fn).toBeNull();
    expect(typeof error).toBe('string');
    expect(error.length).toBeGreaterThan(0);
  });

  it('handles whitespace-only input', () => {
    const { fn, error } = evaluate('   ');
    expect(fn).toBeNull();
    expect(error).toBeNull();
  });

  it('resolves a slider variable passed as scope', () => {
    const { fn, error } = evaluate('a*x');
    expect(error).toBeNull();
    expect(fn(3, { a: 2 })).toBe(6);
  });
});

describe('parseSlider', () => {
  it('recognizes a plain assignment as a slider', () => {
    expect(parseSlider('a = 3')).toMatchObject({ name: 'a', value: 3 });
  });

  it('recognizes a negative decimal value', () => {
    expect(parseSlider('k=-1.5')).toMatchObject({ name: 'k', value: -1.5 });
  });

  it('rejects y= and x= since those are reserved', () => {
    expect(parseSlider('y = 3')).toBeNull();
    expect(parseSlider('x = 3')).toBeNull();
  });

  it('rejects a curve expression', () => {
    expect(parseSlider('x^2')).toBeNull();
    expect(parseSlider('a = x + 1')).toBeNull();
  });
});

describe('isImplicit', () => {
  it('flags a circle equation', () => {
    expect(isImplicit('x^2 + y^2 = 1')).toBe(true);
  });

  it('flags a vertical line', () => {
    expect(isImplicit('x = 3')).toBe(true);
  });

  it('does not flag an explicit y= curve', () => {
    expect(isImplicit('y = x^2')).toBe(false);
  });

  it('does not flag a curve with no equals sign', () => {
    expect(isImplicit('x^2')).toBe(false);
  });

  it('does not flag a slider', () => {
    expect(isImplicit('a = 3')).toBe(false);
  });
});

describe('evaluate implicit', () => {
  it('solves a circle as lhs - rhs', () => {
    const { implicitFn, fn, error } = evaluate('x^2 + y^2 = 1');
    expect(error).toBeNull();
    expect(fn).toBeNull();
    expect(implicitFn(0, 1)).toBeCloseTo(0);
    expect(implicitFn(0, 0)).toBeCloseTo(-1);
  });

  it('honors slider scope in an implicit equation', () => {
    const { implicitFn } = evaluate('x^2 + y^2 = r');
    expect(implicitFn(1, 0, { r: 1 })).toBeCloseTo(0);
  });

  it('reports a parse error on the implicit path', () => {
    const { implicitFn, error } = evaluate('x^2 =!! y');
    expect(implicitFn).toBeNull();
    expect(typeof error).toBe('string');
  });
});

describe('isAsymptoteJump', () => {
  const scale = 60, height = 700;

  it('breaks the stroke across a tan(x) asymptote', () => {
    // adjacent pixels either side of pi/2: finite, huge, opposite sign
    const { fn } = evaluate('tan(x)');
    const a = fn(Math.PI / 2 - 0.001);
    const b = fn(Math.PI / 2 + 0.001);
    expect(isFinite(a) && isFinite(b)).toBe(true);
    expect(isAsymptoteJump(a, b, scale, height)).toBe(true);
  });

  it('breaks the stroke across the 1/x pole', () => {
    const { fn } = evaluate('1/x');
    expect(isAsymptoteJump(fn(-0.001), fn(0.001), scale, height)).toBe(true);
  });

  it('keeps a steep but continuous curve joined', () => {
    const { fn } = evaluate('x^3');
    expect(isAsymptoteJump(fn(4), fn(4.02), scale, height)).toBe(false);
  });

  it('keeps an ordinary zero crossing joined', () => {
    const { fn } = evaluate('sin(x)');
    expect(isAsymptoteJump(fn(-0.01), fn(0.01), scale, height)).toBe(false);
  });
});

describe('points, parametric and polar', () => {
  it('(1, 2) is a point', () => {
    const { pointFn, error } = evaluate('(1, 2)');
    expect(error).toBeNull();
    expect(pointFn({})).toEqual([1, 2]);
  });
  it('a point follows a slider', () => {
    expect(evaluate('(a, a^2)').pointFn({ a: 3 })).toEqual([3, 9]);
  });
  it('(cos(t), sin(t)) is parametric', () => {
    const [x, y] = evaluate('(cos(t), sin(t))').paramFn(0, {});
    expect(x).toBeCloseTo(1);
    expect(y).toBeCloseTo(0);
  });
  it('r = 2 is a polar circle', () => {
    const [x, y] = evaluate('r = 2').paramFn(Math.PI / 2, {});
    expect(x).toBeCloseTo(0);
    expect(y).toBeCloseTo(2);
  });
  it('r = 1 + cos(theta) reads theta', () => {
    expect(evaluate('r = 1 + cos(theta)').paramFn(0, {})[0]).toBeCloseTo(2);
  });
  it('r and t are never sliders', () => {
    expect(parseSlider('r = 3')).toBeNull();
    expect(parseSlider('t = 1')).toBeNull();
  });
  it('splitPair ignores products and nested commas', () => {
    expect(splitPair('(x+1)*(x-1)')).toBeNull();
    expect(splitPair('(x+1)')).toBeNull();
    expect(splitPair('(max(x, 1))')).toBeNull();
    expect(splitPair('(1, 2, 3)')).toBeNull();
    expect(splitPair('( 1 , 2 )')).toEqual(['1', '2']);
  });
  it('(x+1)*(x-1) still graphs as y = f(x)', () => {
    expect(evaluate('(x+1)*(x-1)').fn(2, {})).toBe(3);
  });
});

describe('inequalities', () => {
  it('y > x^2 is positive above the parabola', () => {
    const { implicitFn, inequality } = evaluate('y > x^2');
    expect(inequality).toEqual({ sign: 1, strict: true });
    expect(implicitFn(0, 1, {}) * inequality.sign).toBeGreaterThan(0);
    expect(implicitFn(0, -1, {}) * inequality.sign).toBeLessThan(0);
  });
  it('x^2+y^2 <= 4 is a filled disc with a solid edge', () => {
    const { implicitFn, inequality } = evaluate('x^2+y^2 <= 4');
    expect(inequality).toEqual({ sign: -1, strict: false });
    expect(implicitFn(0, 0, {}) * inequality.sign).toBeGreaterThan(0);
  });
  it('y >= x is not mistaken for an implicit equation', () => {
    expect(evaluate('y >= x').inequality).toBeTruthy();
  });
  it('two comparisons are not an inequality', () => {
    expect(splitInequality('0 < x < 1')).toBeNull();
  });
});

describe('functions, derivatives, piecewise, domain limits', () => {
  const scopeFor = (...exprs) => buildScope(exprs, {});
  it('f(x) = x^2 defines f and draws itself', () => {
    const scope = scopeFor('f(x) = x^2');
    expect(scope.f(3)).toBe(9);
    expect(evaluate('f(x) = x^2').fn(3, scope)).toBe(9);
  });
  it('another row can call f', () => {
    const scope = scopeFor('f(x) = x^2');
    expect(evaluate('f(x + 1)').fn(2, scope)).toBe(9);
  });
  it("f'(x) is the derivative", () => {
    const scope = scopeFor('f(x) = x^3');
    expect(evaluate("f'(x)").fn(2, scope)).toBeCloseTo(12, 3);
    expect(evaluate("f''(x)").fn(2, scope)).toBeCloseTo(12, 1);
  });
  it('d/dx(sin(x)) is cos(x)', () => {
    expect(evaluate('d/dx(sin(x))').fn(0, {})).toBeCloseTo(1);
  });
  it('piecewise {x < 0: -x, x} is abs', () => {
    const { fn, error } = evaluate('{x < 0: -x, x}');
    expect(error).toBeNull();
    expect(fn(-3, {})).toBe(3);
    expect(fn(2, {})).toBe(2);
  });
  it('a piecewise with no else is undefined outside', () => {
    expect(evaluate('{x > 0: 1}').fn(-1, {})).toBeNaN();
  });
  it('a domain limit cuts the curve', () => {
    const { fn } = evaluate('x^2 {0 < x < 2}');
    expect(fn(1, {})).toBe(1);
    expect(fn(3, {})).toBeNaN();
  });
  it('a piecewise with <= is not an implicit equation or inequality', () => {
    expect(isImplicit('{x <= 0: 1, 2}')).toBe(false);
    expect(evaluate('{x <= 0: 1, 2}').fn(0, {})).toBe(1);
  });
  it('desugar leaves plain input alone', () => {
    expect(desugar('sin(x) + 1')).toBe('sin(x) + 1');
  });
});

describe('v5 slider bounds and t ranges', () => {
  it('a = 3 has a default range that fits it', () => {
    expect(parseSlider('a = 3')).toEqual({ name: 'a', value: 3, min: -10, max: 10 });
    expect(parseSlider('a = 40')).toMatchObject({ min: -10, max: 40 });
  });
  it('a = 3 {0 < a < 5} sets the range', () => {
    expect(parseSlider('a = 3 {0 < a < 5}')).toEqual({ name: 'a', value: 3, min: 0, max: 5 });
  });
  it('bounds can be expressions', () => {
    expect(parseSlider('k = 1 {-pi <= k <= pi}').max).toBeCloseTo(Math.PI);
  });
  it('braces about another name are not slider bounds', () => {
    expect(parseSlider('a = 3 {0 < b < 5}')).toBeNull();
  });
  it('(cos(t), sin(t)) {0 < t < pi} runs half a circle', () => {
    const r = evaluate('(cos(t), sin(t)) {0 < t < pi}');
    expect(r.error).toBeNull();
    expect(r.tMin).toBe(0);
    expect(r.tMax).toBeCloseTo(Math.PI);
  });
  it('r = theta {0 < theta < 6pi} spirals past 2 pi', () => {
    const r = evaluate('r = theta {0 < theta < 6pi}');
    expect(r.tMax).toBeCloseTo(6 * Math.PI);
    expect(r.paramFn(4 * Math.PI, {})[0]).toBeCloseTo(4 * Math.PI);
  });
  it('parametric rows default to 0..2pi', () => {
    expect(evaluate('(cos(t), sin(t))').tMax).toBeCloseTo(2 * Math.PI);
  });
});

describe('review fixes', () => {
  it('2ln(x) is 2 log(x)', () => {
    expect(evaluate('2ln(x)').fn(Math.E, {})).toBeCloseTo(2);
  });
  it('atanh(x) = 0.5 is an equation, not a new atanh', () => {
    expect(parseFunctionDef('atanh(x) = 0.5')).toBeNull();
  });
  it('Log(x) = x^2/4 still defines Log (mathjs names are case-sensitive)', () => {
    expect(parseFunctionDef('Log(x) = x^2/4')).toMatchObject({ name: 'Log' });
  });
});

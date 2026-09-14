import { describe, it, expect } from 'vitest';
import { evaluate, isAsymptoteJump, parseSlider } from './evaluate.js';

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
    expect(parseSlider('a = 3')).toEqual({ name: 'a', value: 3 });
  });

  it('recognizes a negative decimal value', () => {
    expect(parseSlider('k=-1.5')).toEqual({ name: 'k', value: -1.5 });
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

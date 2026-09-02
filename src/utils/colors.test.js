import { describe, it, expect } from 'vitest';
import { COLORS, colorAt } from './colors.js';

describe('colorAt', () => {
  it('returns first color at index 0', () => {
    expect(colorAt(0)).toBe(COLORS[0]);
  });

  it('returns correct color within range', () => {
    for (let i = 0; i < COLORS.length; i++) {
      expect(colorAt(i)).toBe(COLORS[i]);
    }
  });

  it('wraps around at palette length', () => {
    expect(colorAt(COLORS.length)).toBe(COLORS[0]);
    expect(colorAt(COLORS.length + 1)).toBe(COLORS[1]);
    expect(colorAt(-1)).toBe(COLORS[COLORS.length - 1]);
    expect(colorAt(NaN)).toBe(COLORS[0]);
  });

  it('all colors are hex strings', () => {
    COLORS.forEach(c => expect(c).toMatch(/^#[0-9a-f]{6}$/i));
  });
});

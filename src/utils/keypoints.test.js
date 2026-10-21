import { describe, it, expect } from 'vitest';
import { keyPoints } from './keypoints.js';

const near = (pts, x, y) => pts.some((p) => Math.abs(p.x - x) < 1e-4 && Math.abs(p.y - y) < 1e-4);

describe('keyPoints', () => {
  it('finds both roots and the vertex of x^2 - 1', () => {
    const pts = keyPoints([{ fn: (x) => x * x - 1, color: 'b' }], -5, 5);
    expect(near(pts, -1, 0)).toBe(true);
    expect(near(pts, 1, 0)).toBe(true);
    expect(near(pts, 0, -1)).toBe(true);
    expect(pts).toHaveLength(3);
  });
  it('finds where x^2 meets 2x', () => {
    const pts = keyPoints([{ fn: (x) => x * x }, { fn: (x) => 2 * x }], -5, 5);
    expect(near(pts, 0, 0)).toBe(true);
    expect(near(pts, 2, 4)).toBe(true);
  });
  it('ignores the asymptote of 1/x', () => {
    expect(keyPoints([{ fn: (x) => 1 / x }], -5, 5)).toHaveLength(0);
  });
  it('ignores the asymptotes of tan(x) but keeps its roots', () => {
    const pts = keyPoints([{ fn: Math.tan }], -2, 2);
    expect(pts).toHaveLength(1);
    expect(near(pts, 0, 0)).toBe(true);
  });
  it('finds sin extrema', () => {
    const pts = keyPoints([{ fn: Math.sin }], 0, 3);
    expect(near(pts, Math.PI / 2, 1)).toBe(true);
  });
  it('survives a throwing function', () => {
    expect(keyPoints([{ fn: () => { throw new Error('x'); } }], -1, 1)).toEqual([]);
  });
});

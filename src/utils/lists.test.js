import { describe, it, expect } from 'vitest';
import { parseListDef, expandRow } from './lists.js';

describe('lists', () => {
  it('L = [1, 2, 3] defines a list', () => {
    expect(parseListDef('L = [1, 2, 3]')).toEqual({ name: 'L', items: [1, 2, 3] });
  });
  it('[1...5] is a range', () => {
    expect(parseListDef('n = [1...5]').items).toEqual([1, 2, 3, 4, 5]);
  });
  it('a list definition draws nothing', () => {
    expect(expandRow('L = [1, 2]', {}).binds).toEqual([]);
  });
  it('(L, L^2) draws one copy per element', () => {
    const { source, binds } = expandRow('(L, L^2)', { L: [1, 2, 3] });
    expect(source).toBe('(L, L^2)');
    expect(binds).toEqual([{ L: 1 }, { L: 2 }, { L: 3 }]);
  });
  it('a literal list makes a family of curves', () => {
    const { source, binds } = expandRow('sin(x) + [0, 1, 2]', {});
    expect(source).toBe('sin(x) + qlist0');
    expect(binds).toEqual([{ qlist0: 0 }, { qlist0: 1 }, { qlist0: 2 }]);
  });
  it('a list of points becomes one point row', () => {
    const { source, binds } = expandRow('[(1, 2), (3, 4)]', {});
    expect(source).toBe('(qlist0, qlist1)');
    expect(binds).toEqual([{ qlist0: 1, qlist1: 2 }, { qlist0: 3, qlist1: 4 }]);
  });
  it('a row with no list is one plain copy', () => {
    expect(expandRow('x^2', { L: [1] })).toEqual({ source: 'x^2', binds: [{}] });
  });
  it('a list name inside a longer word is not a use', () => {
    expect(expandRow('Lx + 1', { L: [1, 2] }).binds).toEqual([{}]);
  });
  it('ragged lists stop at the shortest', () => {
    expect(expandRow('(A, B)', { A: [1, 2, 3], B: [4, 5] }).binds).toHaveLength(2);
  });
});

import { evaluate } from './evaluate.js';
describe('lists through evaluate', () => {
  it('each copy of (L, L^2) is its own point', () => {
    const { source, binds } = expandRow('(L, L^2)', { L: [1, 2, 3] });
    const { pointFn } = evaluate(source);
    expect(binds.map((b) => pointFn(b))).toEqual([[1, 1], [2, 4], [3, 9]]);
  });
  it('a family of curves shifts by each element', () => {
    const { source, binds } = expandRow('x + [0, 10]', {});
    const { fn } = evaluate(source);
    expect(binds.map((b) => fn(1, b))).toEqual([1, 11]);
  });
});

import { evaluateRow } from './lists.js';
describe('evaluateRow', () => {
  it('list rows report no error', () => {
    for (const row of ['L = [-2...2]', 'sin(x) + [0, 1, 2]', '[(1, -1), (2, -2)]']) {
      expect(evaluateRow(row).error ?? null).toBeNull();
    }
  });
  it('a point row keeps its pointFn', () => {
    expect(evaluateRow('(1, 2)').pointFn({})).toEqual([1, 2]);
  });
});

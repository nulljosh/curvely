// WebMCP tool registration. Exposes curvely's plot actions to in-browser agents
// via document.modelContext.
//
// ponytail: tools call the same handlers the sidebar buttons call, so anything
// an agent plots is a real equation in the list, not a parallel state.
import { useEffect, useRef } from 'react';
import { evaluate } from '../utils/evaluate.js';

const EXPR = { type: 'string', description: 'Expression in x, e.g. "x^2", "sin(x)", "1/x"' };

function buildTools(get) {
  return [
    // ---- read-only -------------------------------------------------------
    {
      name: 'list_equations',
      description: 'List the equations currently plotted, with their ids, colours and any parse errors.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => ({
        equations: get().equations.map(({ id, expr, color, error }) => ({ id, expr, color, error })),
      }),
    },
    {
      name: 'evaluate_expression',
      description: 'Evaluate an expression at one or more x values without plotting it. Also reports parse errors.',
      inputSchema: {
        type: 'object',
        properties: {
          expr: EXPR,
          xValues: { type: 'array', items: { type: 'number' }, description: 'x values to evaluate at' },
        },
        required: ['expr', 'xValues'],
      },
      execute: async ({ expr, xValues }) => {
        const { fn, error } = evaluate(expr);
        if (error || !fn) return { expr, error: error || 'Could not parse expression' };
        return {
          expr,
          points: xValues.map((x) => {
            const y = fn(x);
            return { x, y: Number.isFinite(y) ? y : null };
          }),
        };
      },
    },

    // ---- reversible state changes ----------------------------------------
    {
      name: 'plot_equation',
      description: 'Add an equation to the graph. Returns its id.',
      inputSchema: { type: 'object', properties: { expr: EXPR }, required: ['expr'] },
      execute: async ({ expr }) => ({ id: get().addEquation(expr), expr }),
    },
    {
      name: 'update_equation',
      description: 'Replace the expression of an equation already on the graph.',
      inputSchema: {
        type: 'object',
        properties: { id: { type: 'number', description: 'Equation id from list_equations' }, expr: EXPR },
        required: ['id', 'expr'],
      },
      execute: async ({ id, expr }) => {
        get().changeEquation(id, expr);
        return { id, expr, error: evaluate(expr).error ?? null };
      },
    },
    {
      name: 'remove_equation',
      description: 'Remove an equation from the graph.',
      inputSchema: {
        type: 'object',
        properties: { id: { type: 'number', description: 'Equation id from list_equations' } },
        required: ['id'],
      },
      execute: async ({ id }) => { get().removeEquation(id); return { removed: id }; },
    },
    {
      name: 'clear_graph',
      description: 'Remove every equation from the graph.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => {
        const ids = get().equations.map((e) => e.id);
        ids.forEach((id) => get().removeEquation(id));
        return { removed: ids };
      },
    },
  ];
}

export function useWebMCP(ctx) {
  const ref = useRef(ctx);
  ref.current = ctx;

  useEffect(() => {
    const mc = document.modelContext;
    if (!mc?.registerTool) return; // browser without WebMCP support
    let cancelled = false;
    const registered = [];

    (async () => {
      for (const tool of buildTools(() => ref.current)) {
        if (cancelled) return;
        try {
          registered.push(await mc.registerTool(tool));
        } catch (err) {
          console.warn('[webmcp] failed to register', tool.name, err?.message);
        }
      }
    })();

    return () => {
      cancelled = true;
      for (const h of registered) { try { h?.unregister?.(); } catch { /* gone already */ } }
    };
  }, []);
}

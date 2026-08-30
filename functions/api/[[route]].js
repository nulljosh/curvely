// REST surface. Thin: every route is argument-shuffling around callTool() in
// src/lib/tools.js, which functions/mcp.js also calls. No expression logic lives here —
// including the mathjs AST fence, which must not be duplicated or bypassed.

import { callTool, ToolError, TOOL_NAMES } from '../../src/lib/tools.js';

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'content-type',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
};

const json = (body, status = 200) =>
  new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { 'content-type': 'application/json', ...CORS },
  });

const ENDPOINTS = {
  'GET /api/syntax': 'Functions, constants and operators an expression may use.',
  'POST /api/evaluate': '{ expr, xValues } -> { points: [{x, y}] }',
  'POST /api/sample': '{ expr, from?, to?, samples? } -> { points, range, undefinedCount }',
  'POST /mcp': 'Model Context Protocol, JSON-RPC. Same three tools.',
};

const run = (name, args) => {
  try {
    return json(callTool(name, args));
  } catch (err) {
    // A rejected expression is the caller's to fix, so name the problem rather than 500ing.
    if (err instanceof ToolError) return json({ error: err.message, tool: name }, 400);
    throw err;
  }
};

const POSTS = { '/api/evaluate': 'evaluate_expression', '/api/sample': 'sample_expression' };

export async function onRequest({ request }) {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });

  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, '');

  if (request.method === 'GET' && path === '/api/syntax') return run('list_syntax', {});

  if (request.method === 'POST' && POSTS[path]) {
    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Body must be JSON.' }, 400);
    }
    return run(POSTS[path], body);
  }

  if (path === '/api' || path === '/api/') return json({ endpoints: ENDPOINTS, tools: TOOL_NAMES });

  return json({ error: `Unknown endpoint: ${request.method} ${path}`, endpoints: ENDPOINTS }, 404);
}

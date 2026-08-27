# Curvely API

Curvely is a client-only graphing calculator — no server, no HTTP API. The
agent-facing interface is WebMCP.

## WebMCP

With the app open, curvely registers tools on `document.modelContext`.
Source: `src/lib/webmcp.js`.

### Read-only

| Tool | Does |
|---|---|
| `list_equations` | Every plotted equation with its id, colour and parse error |
| `evaluate_expression` | Evaluate `expr` at a list of `xValues` without plotting. `y` is `null` where the function is undefined |

### Reversible writes

| Tool | Does |
|---|---|
| `plot_equation` | Add an equation to the graph, returns its id |
| `update_equation` | Replace the expression of an existing equation |
| `remove_equation` | Remove one equation |
| `clear_graph` | Remove every equation |

Expressions use the same syntax as the input field: `x^2`, `sin(x)`, `sqrt(abs(x))`,
`2*x+1`, `1/x`. Invalid expressions come back with an `error` rather than throwing.

Nothing is persisted or paid for, so no tool requires confirmation.

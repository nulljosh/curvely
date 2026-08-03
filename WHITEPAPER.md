# Curvely Technical Whitepaper

**v1.1.0** | July 2026

Grapher is a Desmos-style graphing calculator: type an equation, see it
plotted instantly. Entirely client-side — no backend, no server round-trip
for evaluation.

## Equation Evaluation and Rendering

Each equation entered in `EquationRow`/`EquationList` is parsed by
`src/utils/evaluate.js`, a thin wrapper around `mathjs` that strips the
leading `y =` before handing the expression to `mathjs`'s compiled evaluator.
`Graph.jsx` then samples that function across the visible x-range on an HTML
Canvas (no charting library — raw canvas draw calls), with pan/zoom
implemented as ref-held transform state rather than re-rendering the DOM.
Colors cycle through an 8-entry palette (`src/utils/colors.js`) so each
plotted equation is visually distinct.

## Structure

- `src/components/Graph.jsx` — canvas renderer, pan/zoom via ref transforms
- `src/components/EquationList.jsx` / `EquationRow.jsx` — equation inputs
- `src/utils/evaluate.js` — mathjs wrapper
- `src/utils/colors.js` — 8-color palette

## Platforms

| Platform | Framework | Notes |
|----------|-----------|-------|
| Web | React (client-only, no backend) | Dark mode only, Apple Liquid Glass UI |
| iOS | WKWebView shell (xcodegen) | Serves the build over a custom `app://` scheme, since ES module `<script>` tags are blocked cross-origin under `file://` |

## Security / Privacy

No backend means no user data is ever transmitted or stored server-side —
every equation and graph exists only in the client's memory for that session.

## License

MIT 2026, Joshua Trommel

# Curvely Technical Whitepaper

**v1.2.2** | August 2026

Type an equation. Watch it draw.

Graphing calculators either live behind a paywall or bury the plot under a
full computer-algebra suite nobody asked for. Curvely exists to do the one
thing well: type an equation, see the curve, nothing in between. Everything
happens on the device, no backend, no round trip to evaluate anything,
because the whole point is that typing and seeing the result should feel
instant, and a network hop is the first thing that breaks that feeling.

## Equation Evaluation and Rendering

Each equation entered in `EquationRow`/`EquationList` is parsed by
`src/utils/evaluate.js`, a thin wrapper around `mathjs` that strips the
leading `y =` before handing the expression to `mathjs`'s compiled evaluator,
because writing a parser from scratch buys nothing over a well-tested one for
the web build. `Graph.jsx` then samples that function across the visible
x-range on an HTML Canvas (no charting library, raw canvas draw calls,
chosen because a charting library aims at bar/line business charts, not a
continuous mathematical curve with pan and zoom), with pan/zoom implemented
as ref-held transform state rather than re-rendering the DOM, since redrawing
a canvas is cheap and re-rendering React on every drag frame is not. Colors
cycle through an 8-entry palette (`src/utils/colors.js`) so each plotted
equation stays visually distinct without the user having to pick colors.

## Structure

- `src/components/Graph.jsx`: canvas renderer, pan/zoom via ref transforms
- `src/components/EquationList.jsx` / `EquationRow.jsx`, equation inputs
- `src/utils/evaluate.js`: mathjs wrapper
- `src/utils/colors.js`: 8-color palette

## Platforms

| Platform | Framework | Notes |
|----------|-----------|-------|
| Web | React (client-only, no backend) | Dark mode only, Apple Liquid Glass UI |
| iOS | Native SwiftUI (xcodegen) | v1.2.0 in review. Replaced the original WKWebView shell in August 2026 because a wrapped web view reads as unfinished to App Review and to users: the shell needed a custom `app://` scheme since ES module `<script>` tags are blocked cross-origin under `file://`, and that whole workaround went away with the native rewrite |

## Planned: Adaptive Sampling

`Graph.jsx` samples each function once per device pixel across the visible
width. That is a fixed cost regardless of what the curve is doing, and it is
simultaneously too much work on a flat stretch and too little on a steep one:
a feature narrower than one pixel (a spike, a root, the turn of a near-vertical
branch) falls between samples and never gets drawn, and `isAsymptoteJump` can
only guess at a discontinuity from the size of the gap between two samples it
already took.

The replacement is recursive adaptive subdivision. Sample coarsely (every 4-8
px), then split an interval only while the midpoint sits far enough off the
chord between its endpoints, the standard flatness test, capped at a
subdivision depth so a pathological function terminates. Where a split keeps
failing the test and the two sides diverge in sign, that is a pole rather than
a curve, and the pen lifts on evidence instead of on a magnitude heuristic.

Expected effect: fewer evaluations on smooth curves (most of a typical plot),
more where they matter, and correct rendering of `tan(x)`, `1/x` and friends
without the spurious vertical connectors the current jump heuristic misses.

## Security / Privacy

No backend means no user data is ever transmitted or stored server-side , 
every equation and graph exists only in the client's memory for that session.

## License

MIT 2026, Joshua Trommel

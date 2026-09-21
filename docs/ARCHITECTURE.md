# Architecture

Curvely is a Desmos-style graphing calculator. Plot implicit and explicit equations, use sliders to parameterize curves, export as PNG. Deployed as a web app (React on Cloudflare Pages), native apps (iOS, macOS, watchOS), Kotlin Multiplatform (Android, desktop), and a CLI (Swift one-liner). The network API uses an AST allowlist around mathjs to safely evaluate untrusted expressions.

## How it runs

Web app: `index.html` loads `src/main.jsx` (React bootstrap) which renders `src/App.jsx`. User types equations in the sidebar; `App.jsx` parses each with `evaluate()` (a mathjs wrapper) and tracks them in state. Rows that match the slider pattern (`a = 3`) become sliders instead of curves; their values can override the literal number. `Graph.jsx` renders the canvas: grid, axes, labels, curves. Clicking each pixel evaluates every curve at that coordinate. Implicit equations (like `x^2 + y^2 = 1`) are traced using an asymptote-detection algorithm. Curves export as PNG through the browser's download.

iOS/macOS app: built from one xcodegen project targeting both platforms. `ContentView.swift` is the sidebar, `GraphView.swift` is the canvas. `Expression.swift` (a hand-written recursive-descent parser) replaces mathjs. On save, equations persist to Application Support as JSON. The export uses `ImageRenderer` to render the same `GraphView` as PNG and shares it through the system share sheet.

watchOS app: preset curves only (no keyboard for equation input on 40mm). `Presets.swift` holds a fixed list; `PlotView.swift` renders each at fullscreen.

Network API: `functions/api/` (REST) and `functions/mcp.js` (JSON-RPC MCP). Both call `callTool()` from `src/lib/tools.js`, which enforces a strict AST allowlist around mathjs (the public endpoint compiles untrusted source, and mathjs's parser accepts assignment, function definition, and property access, which are historical sandbox escapes). The fence walks the tree and rejects every node type not on the allowlist, failing closed. Allowed: basic arithmetic, 40+ math functions, no assignments or control flow.

CLI (TUI): calls `/api/sample` and renders points as an ASCII plot.

## Files

| File | What it owns |
|---|---|
| `src/main.jsx` + `index.html` | React bootstrap and HTML entry point |
| `src/App.jsx` | Equation state, slider state, WebMCP registration |
| `src/components/Graph.jsx` | Canvas rendering: grid, axes, labels, curve tracing, asymptote detection, pan/zoom via CSS transforms |
| `src/components/EquationList.jsx` | Sidebar: list of equations, quick examples |
| `src/components/EquationRow.jsx` | Single equation input with real-time validation and parse error display |
| `src/utils/evaluate.js` | mathjs wrapper: accepts expressions, strips `y =` prefix, detects implicit equations, returns compiled functions or errors |
| `src/utils/colors.js` | 8-color palette (clrs.cc, teal/purple/fuchsia excluded per house rule) |
| `src/lib/tools.js` | Stateless server-side evaluator: AST fence, expression validation, safe compilation for `/api` and `/mcp` |
| `src/lib/tools.test.js` | AST fence test per historical mathjs sandbox escape |
| `src/lib/webmcp.js` | WebMCP tool registration for in-browser agents |
| `functions/api/[[route]].js` | REST surface: `/syntax`, `/evaluate`, `/sample` routes; argument shuffling around callTool |
| `functions/mcp.js` | JSON-RPC 2.0 MCP endpoint, no SDK, no Durable Object (stateless) |
| `landing/index.html` + `devices.css` | Marketing landing page at root; app lives at `/app/` |
| `public/sw.js` | Service worker: network-first for pages, cache-first for hashed assets |
| `ios/App/Expression.swift` | Recursive-descent parser replacing mathjs; 3,636 sample points verified against real mathjs |
| `ios/App/GraphView.swift` | SwiftUI Canvas: grid, axes, labels, curves, pen-up across asymptotes |
| `ios/App/Equation.swift` | Single equation struct: source text, compiled form, color index |
| `ios/App/EquationListView.swift` | Sidebar list with add/remove, custom layout for iPhone X notch |
| `ios/App/Store.swift` | On-device JSON persistence to Application Support |
| `ios/App/PNG.swift` | ImageIO-based PNG export (one implementation for iOS/macOS, no platform branch) |
| `ios/App/Palette.swift` | 8-color palette, mirrored from web |
| `ios/App/Theme.swift` | Dark-mode-only color tokens |
| `ios/GrapherApp.swift` | SwiftUI app entry, window size (1280x800 on macOS) |
| `ios/Checks/main.swift` | Parser self-check: ports evaluate.test.js and colors.test.js, PNG export validation |
| `watchos/ContentView.swift` | Vertical TabView over preset curves |
| `watchos/CurvelyWatchApp.swift` | watchOS app entry |
| `watchos/Models/` | Expression.swift (copy of iOS), Palette.swift, Presets.swift (fixed equation list), Theme.swift |
| `watchos/Views/` | CurvePageView (equation label + plot), PlotView (fixed-scale canvas, no gestures) |
| `kmp/shared/src/commonMain/kotlin/com/nulljosh/curvely/Expression.kt` | Kotlin parser ported from ios/App/Expression.swift; kept in lockstep |
| `kmp/composeApp/src/*/` | Android/desktop Compose UI, common AppScreen.kt |
| `tui/main.swift` | CLI: hits /api/sample endpoint, renders as ASCII sparkline |
| `vite.config.js` | Vite + React, app at `/app/` separate from landing at `/` |
| `scripts/build-site.sh` | Compose Pages site: landing at `/`, app at `/app/` |

## Expressions and parsing

Implicit equations like `x^2 + y^2 = 1` are detected by the presence of `y` on both sides. The evaluator compiles both `lhs(x, y)` and `rhs(x, y)`, then during rendering, for each pixel it finds the `y` where `lhs` and `rhs` are closest. Asymptotes (vertical breaks) occur when the sign flips between adjacent pixels; the graph pen lifts to avoid drawing false lines.

Sliders: rows matching `/^([a-z_]\w*)\s*=\s*(-?\d+)$/` become sliders instead of curves. The slider value defaults to the literal number but can be dragged; the symbol is injected into all other equations' evaluation scope.

## AST safety

`src/lib/tools.js` enforces an allowlist by walking the parsed tree after mathjs `parse()`. Rejected node types: Assignment, FunctionDef, IndexNode, PropertyAccess, anything else that isn't arithmetic, a constant, or a whitelisted function call. This is fail-closed design: a new mathjs node type discovered as a sandbox escape cannot bypass the fence without changing the allowlist explicitly.

## Network API

| Endpoint | What it does |
|---|---|
| `GET /api/syntax` | Returns the list of 40+ allowed functions and constants |
| `POST /api/evaluate` | Body: `{expr, x}`. Returns compiled function or error. Used for validation. |
| `POST /api/sample` | Body: `{expr, xMin, xMax, samples}`. Returns array of `[x, y]` pairs or error. Used by TUI and agents. |
| `POST /mcp` | JSON-RPC 2.0 wrapper around the same tools |

## Gotchas

- Implicit equation tracing is not perfect. A disconnected loop like `sin(x) = cos(y)` will trace the connected component nearest to the center, leaving gaps. This is a limitation of the pixel-by-pixel approach.
- Slider values are lost on a page reload in the web app (browser localStorage is not used). Native apps persist to disk.
- watchOS cannot display equations (no input method); it shows presets only.
- Service worker cache persists even after deploy; verify new content with a hard reload.

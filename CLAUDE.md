# Curvely

v1.1.0, Desmos-style graphing calculator. Web + iOS + macOS, with a small stateless HTTP API.

## Run

```bash
npm install && npm run dev   # port 5174
npm run build
```

## Rules

- The app itself is client-side: pure client math (mathjs on web, a hand-written parser on iOS).
  The only server code is the stateless API below; nothing is stored server-side.
- Canvas rendering only, no chart libs
- Apple Liquid Glass UI, dark mode only
- Mobile-first responsive

## HTTP API + MCP

Cloudflare Pages Functions in `functions/`, added 2026-08-30. `src/lib/tools.js` is the one
definition both surfaces call, add tools there, never in a handler.

- `GET /api/syntax`, `POST /api/evaluate`, `POST /api/sample`
- `POST /mcp`: JSON-RPC, stateless, no SDK and no Durable Object

**`src/lib/tools.js` carries an AST allowlist around mathjs and that is not optional.** The
endpoint is public and compiles caller-supplied source; mathjs `parse()` accepts assignment,
function definition, and property/index access, which is where its historical sandbox escapes
live. The fence walks the parsed tree and rejects every node type not on the allowlist, so it
fails closed. `src/lib/tools.test.js` has a test per escape route, keep them.

`src/utils/evaluate.js` (the browser path) deliberately does NOT use the fence: there the user
is evaluating their own expression in their own tab.

```bash
npx wrangler pages dev   # Pages project is "grapher", NOT "curvely" — see wrangler.toml
```

## iOS + macOS

Native SwiftUI app in `ios/` (xcodegen), both destinations from one target via
`supportedDestinations` since 2026-08-30. Rewritten from a WKWebView shell 2026-08-17, Apple's
Guideline 5.6 notice cited quality/completeness, and the 150-line shell was the finding. No web
assets are bundled any more; `npm run build:ios` is gone.

- `App/Expression.swift`: recursive-descent parser replacing mathjs. Verified against real
  mathjs across 3,636 sample points. One deliberate divergence: mathjs rejects `x(x+1)`
  ("x is not a function"), this reads it as multiplication, strictly more permissive, so
  nothing that graphs on the web fails here.
- `App/GraphView.swift`: SwiftUI Canvas: grid, axes, labels, curves, pen-up across asymptotes
- `App/Store.swift`: equations persist to Application Support
- `App/PNG.swift`: CGImage to PNG via ImageIO, so the export has no UIKit/AppKit branch
- `Checks/main.swift`: evaluate.test.js + colors.test.js as plain asserts, plus a real check
  that the export produces decodable PNG bytes

```bash
cd ios && xcodegen generate
xcodebuild build -scheme Grapher-iOS -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/dd-curvely -skipPackagePluginValidation

# macOS. -allowProvisioningUpdates is required the first time: no Mac profile existed for
# com.nulljosh.grapher until 2026-08-30.
xcodebuild build -scheme Grapher-iOS -destination 'platform=macOS' \
  -derivedDataPath /tmp/dd-curvely-mac -skipPackagePluginValidation -allowProvisioningUpdates

# parser self-check, no framework needed
swiftc -o /tmp/curvecheck ios/App/Expression.swift ios/App/Palette.swift ios/App/PNG.swift \
  ios/Checks/main.swift && /tmp/curvecheck
```

Native-only capabilities the web build cannot offer: equations persist across launches, and the
graph exports as a rendered PNG through the system share sheet (ImageRenderer over the same
GraphView, so there is no second drawing path). Export goes through `ShareLink`, not a
`UIViewControllerRepresentable`, `UIActivityViewController` is iOS-only and was the one thing
blocking the macOS build. `ImageRenderer.cgImage` for the same reason: `uiImage`/`nsImage` each
exist on only one platform.

Two entitlements files, split by SDK. The iOS one's `application-identifier` is not a valid
macOS entitlement, with it present, Mac profile creation fails outright.

The Xcode target and project are still named `Grapher`, bundle ID `com.nulljosh.grapher` is
Apple-frozen, so the internal name stays even though the product is Curvely.

AppIcon asset catalog at `ios/App/Assets.xcassets/AppIcon.appiconset` (1024×1024, flattened from
`icon.svg`), plus the ten `mac_*.png` idiom sizes, macOS gets no icon from a universal 1024 alone.

## Key files

- `src/components/Graph.jsx`: canvas renderer, pan/zoom via ref transforms
- `src/components/EquationList.jsx` / `EquationRow.jsx`, equation inputs
- `src/utils/evaluate.js`: mathjs wrapper for the browser, strips `y =` prefix
- `src/lib/tools.js`: the fenced server-side evaluator behind `/api/*` and `/mcp`
- `src/utils/colors.js`: 8-color palette

# Curvely

v1.1.0 — Desmos-style graphing calculator. Client-side only, no backend.

## Run

```bash
npm install && npm run dev   # port 5174
npm run build
```

## Rules

- No backend — pure client math (mathjs on web, a hand-written parser on iOS)
- Canvas rendering only, no chart libs
- Apple Liquid Glass UI, dark mode only
- Mobile-first responsive

## iOS

Native SwiftUI app in `ios/` (xcodegen). Rewritten from a WKWebView shell 2026-08-17 — Apple's
Guideline 5.6 notice cited quality/completeness, and the 150-line shell was the finding. No web
assets are bundled any more; `npm run build:ios` is gone.

- `App/Expression.swift` — recursive-descent parser replacing mathjs. Verified against real
  mathjs across 3,636 sample points. One deliberate divergence: mathjs rejects `x(x+1)`
  ("x is not a function"), this reads it as multiplication — strictly more permissive, so
  nothing that graphs on the web fails here.
- `App/GraphView.swift` — SwiftUI Canvas: grid, axes, labels, curves, pen-up across asymptotes
- `App/Store.swift` — equations persist to Application Support
- `Checks/main.swift` — evaluate.test.js + colors.test.js as plain asserts

```bash
cd ios && xcodegen generate
xcodebuild build -scheme Grapher-iOS -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/dd-curvely -skipPackagePluginValidation

# parser self-check, no framework needed
swiftc -o /tmp/curvecheck ios/App/Expression.swift ios/App/Palette.swift ios/Checks/main.swift && /tmp/curvecheck
```

Native-only capabilities the web build cannot offer: equations persist across launches, and the
graph exports as a rendered PNG through the system share sheet (ImageRenderer over the same
GraphView, so there is no second drawing path).

The Xcode target and project are still named `Grapher` — bundle ID `com.nulljosh.grapher` is
Apple-frozen, so the internal name stays even though the product is Curvely.

AppIcon asset catalog at `ios/App/Assets.xcassets/AppIcon.appiconset` (1024×1024, flattened from `icon.svg`).

## Key files

- `src/components/Graph.jsx` — canvas renderer, pan/zoom via ref transforms
- `src/components/EquationList.jsx` / `EquationRow.jsx` — equation inputs
- `src/utils/evaluate.js` — mathjs wrapper, strips `y =` prefix
- `src/utils/colors.js` — 8-color palette

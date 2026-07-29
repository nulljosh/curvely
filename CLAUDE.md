# Grapher

v1.1.0 — Desmos-style graphing calculator. Client-side only, no backend.

## Run

```bash
npm install && npm run dev   # port 5174
npm run build
```

## Rules

- No backend — pure client math via mathjs
- Canvas rendering only, no chart libs
- Apple Liquid Glass UI, dark mode only
- Mobile-first responsive

## iOS

Thin WKWebView shell in `ios/` (xcodegen, no Capacitor — app has no native API needs). Serves the build over a custom `app://` scheme (not `file://`) since ES module scripts are blocked cross-origin under `file://`.

```bash
npm run build:ios            # builds to ios/web with relative asset paths
cd ios && xcodegen generate && open Grapher.xcodeproj
```

AppIcon asset catalog at `ios/App/Assets.xcassets/AppIcon.appiconset` (1024×1024, flattened from `icon.svg`).

## Key files

- `src/components/Graph.jsx` — canvas renderer, pan/zoom via ref transforms
- `src/components/EquationList.jsx` / `EquationRow.jsx` — equation inputs
- `src/utils/evaluate.js` — mathjs wrapper, strips `y =` prefix
- `src/utils/colors.js` — 8-color palette

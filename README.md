<img src="icon.svg" width="80">

# Curvely

![version](https://img.shields.io/badge/version-v1.2.1-blue) [![App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/us/app/curvely/id6794988370)

Desmos-style graphing calculator. Multi-equation, zoom/pan, Apple Liquid Glass UI.

## Roadmap

**This week**
- [ ] Generate AppIcon asset catalog from `icon.svg` for iOS build
- [ ] Pass over equation input UX — error states, edge-case parsing
- [ ] Fix any open pan/zoom bugs on canvas renderer

**This month**
- [ ] iOS build via `ios/` WKWebView shell — test on device
- [ ] App Store Connect registration + first TestFlight build
- [ ] Screenshots + metadata for submission

## Whitepaper

[Technical whitepaper](WHITEPAPER.md)

## API and agent tools

[`docs/API.md`](docs/API.md) documents the HTTP surface (where there is one) and
the WebMCP tools this app registers on `document.modelContext`, so an in-browser
agent can drive it. Tools are split into read-only, reversible writes, and the
few that require human confirmation.

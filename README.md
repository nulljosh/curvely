<img src="icon.svg" width="80">

# Curvely

![version](https://img.shields.io/badge/version-v1.2.2-blue) [![App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/us/app/curvely/id6794988370)

**Live:** https://curvely.heyitsmejosh.com

Desmos-style graphing calculator. Multi-equation, zoom/pan, Apple Liquid Glass UI.
Native SwiftUI on iPhone, iPad and Mac, plus the web app.

## Roadmap

- [ ] Pass over equation input UX — error states, edge-case parsing
- [ ] Restored equations lose their colour (grey dot) when the saved colorIndex
      falls outside the palette

## Whitepaper

[Technical whitepaper](WHITEPAPER.md)

## API and agent tools

[`docs/API.md`](docs/API.md) documents the HTTP surface (where there is one) and
the WebMCP tools this app registers on `document.modelContext`, so an in-browser
agent can drive it. Tools are split into read-only, reversible writes, and the
few that require human confirmation.

## Architecture

<img src="architecture.svg" width="600">

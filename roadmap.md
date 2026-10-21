# Curvely Roadmap

## v3 to v10 (Joshua's ask 2026-10-21: "loop to v5-10")
One major version per real feature batch, each on web, iOS and Mac, submitted once the last one clears review. Order is a proposal, Joshua can reshuffle.
- [x] v3 Functions: `f(x) = x^2` then `f(x+1)`, derivatives `f'(x)` and `d/dx`, piecewise `{x < 0: -x, x}`, domain limits `sin(x) {0 < x < 5}`. Built 2026-10-21 on web, iOS and Mac; web live, native ships as 3.0.0 after 2.0.0 clears review.
- [x] v4 Lists: `L = [1, 2, 3]`, ranges `[1...10]`, `(L, L^2)` and `sin(x) + [0, 1, 2]` draw once per element, `[(1, 2), (2, 4)]` plots a point list. Built 2026-10-21 on all three. An editable table UI moves to v31-40.
- [x] Patterns (Joshua's ask 2026-10-21, goal 50-100): 85 one-tap patterns in 11 categories (spirals, flowers incl. flower of life, hearts, classic curves, Lissajous, spirographs, waves, functions, dots, regions, implicit art). Adds rows, never replaces. Add one in src/utils/patterns.js, then `npm run gen:patterns` writes ios/App/Patterns.swift; a test fails if they drift.
- [x] v5 Sliders grown up: play button sweeps between bounds, `a = 3 {0 < a < 10}` sets the range (fixed while dragging), `{0 < t < pi}` / `{0 < theta < 6pi}` set parametric and polar ranges. Built 2026-10-21 on all three. Per-slider step left out: continuous plus 2-decimal rounding covers it.
- v6 Saved graphs: a list of named graphs, a share link on web (state in the URL), iCloud sync on native.
- v7 Look: per-row colour picker, line style (solid, dashed, points), labels on points.
- v8 Statistics: regressions `y1 ~ m x1 + b` over a table, mean, median, stdev.
- v9 Accessibility: audio trace (hear the curve, like Desmos), full VoiceOver graph description, larger type.
- v10 Apple extras: widgets with a saved graph, Shortcuts action, Apple Pencil handwriting into a row.

## v11 to v100 (Joshua 2026-10-21: "keep building out roadmap to v100, loop forever, ship every major")
One major per batch, same rule as above: all three platforms, tests, live check, submitted when the last one clears. Ten versions per line, in order.
- v11-20 Calculus: integrals with shaded area, tangent line at a point, Taylor polynomials on a slider, limits, slope fields, a solve row (`solve x^3 = 2`), sums and products, complex numbers, vectors as arrows, implicit derivatives.
- v21-30 Geometry: segments, polygons, circles by centre and radius, angle readouts, translate/rotate/reflect, loci, compass constructions, distance readouts, polygon area, snapping.
- v31-40 Data: CSV import, editable tables, histograms, box plots, scatter with trend, residual plots, normal and binomial distributions, random samples, t-tests, quantiles.
- v41-50 3D: z = f(x, y) surfaces, orbit and zoom, parametric surfaces, contour plots, 3D vector fields, level sets, lighting, STL export, AR on iPhone, Vision Pro.
- v51-60 Teaching: notes rows, folders, images on the plane, step-through animation, hide and reveal, presentation mode, classroom share codes, printable worksheets, LaTeX export, answer checking.
- v61-70 Input: a math keyboard on iOS, Pencil handwriting, voice ("graph y equals x squared"), plain-English rows via an on-device model, LaTeX paste, photo of a textbook to rows, Siri, Spotlight, Shortcuts, Live Activities for animations.
- v71-80 Cloud: jaybulb-api accounts, live collaboration, comments, version history, a public gallery, embeds for blogs, MCP tools for agents, user plugins, offline-first sync, PDF/SVG/video export.
- v81-90 Engine and platforms: WebGPU rendering, interval-arithmetic plotting, adaptive sampling, million-point data, watchOS glance, tvOS presenting, Android via KMP, Windows and Linux PWA, the TUI grown up, Raycast extension.
- v91-100 Finish: themes, an accessibility audit to AAA, 30 languages, onboarding tour, sonification v2, a scientific calculator mode, unit conversions, a finance mode, performance budget in CI, and a v100 retrospective on the landing.

## v2.0.0 (Desmos basics), started 2026-10-21
Each item lands on web, iOS and Mac together. Submit 2.0.0 once all are in and 1.2.6 has cleared review.
- [x] Tap a curve's dot to hide or show it (persists on native).
- [x] Points: `(1, 2)` plots a dot, `(a, a^2)` follows sliders. Native also got sliders, which it never had (dragging rewrites the row's text, like Desmos).
- [x] Key points: roots, extrema and intersections as small dots; hover (web, Mac) or tap (iOS) to read the coordinates.
- [x] Inequalities: `y > x^2`, `x^2+y^2 < 4` shade their region (strict edge thin and faded).
- [x] Polar: `r = 1 + cos(theta)`, theta 0 to 2 pi.
- [x] Parametric: `(cos(t), sin(t))` over t in 0 to 2 pi.

## State 2026-09-20
iOS + macOS 1.2.4 WAITING_FOR_REVIEW: full-screen graph, no header or zoom buttons, glass
equation panel. 1.2.5 work is on main: collapsible panel, Mac scroll-wheel zoom, web +/-/0 keys.

- [x] Recapture App Store screenshots (iPhone, iPad, Mac). 1.2.6 (build 202610210815) uploaded on iOS and Mac 2026-10-21 from committed code (carries the 10-17 brand icon fix). New iPhone, iPad and Mac shots are on the 1.2.6 draft. Superseded same day: the redesign (Curvely Sans, glass, new icon) plus light mode shipped as 1.2.6 build 202610210836, new shots, submitted on iOS and Mac 2026-10-21.
- [x] Support and privacy URLs moved to curvely.jaybulb.com 2026-10-21 (heyitsmejosh.com has lapsed).
- [x] Light mode on web, iOS and Mac, follows the system setting. 2026-10-21

- [x] Verify iPad layout visually on simulator -- 2026-09-02, done 2026-10-21 (iPad 13 inch shot for 1.2.6). Code review found no
  structural iPad issue: `ContentView` already branches on `horizontalSizeClass`
  (compact -> stacked, regular -> 320pt sidebar + graph `HStack`), and the one
  `.frame(maxWidth: 600)` found nearby is inside `ExportSheet`, bounding the exported PNG
  preview, not the main canvas. This machine's Xcode only has the iOS 26.5 SDK with the
  iOS 26.2 runtime downloaded, so `xcodebuild` won't recognize any simulator destination
  even by explicit UDID -- needs the matching platform component installed, then a
  screenshot check (portrait + landscape).

## In flight, grapher -> curvely hostname rename

Done 2026-08-27: Pages custom domain `curvely.heyitsmejosh.com` added to the `grapher`
project, and CNAME `curvely -> grapher-c2q.pages.dev` (proxied) created in the
heyitsmejosh.com zone. Cloudflare reports the domain `pending` while the cert issues.

Done 2026-08-30: `curvely.heyitsmejosh.com` and its `/privacy.html` both return 200, so
`ios/metadata/app-info/en-US.json` (privacyPolicyUrl) and
`ios/metadata/version/1.2.2/en-US.json` (supportUrl) now point at curvely, not grapher.
Not yet pushed to ASC, `asc metadata` push is the next submission's job.

Correction: an earlier version of this file said this could not be done headlessly because
there was no Cloudflare token and no wrangler. Both were wrong. wrangler runs via `npx`
(4.127.0, OAuth authenticated) and the DNS token is `CLOUDFLARE_DNS_TOKEN` in
`~/.config/fish/secrets.fish`, deliberately not named CLOUDFLARE_API_TOKEN because that
name makes wrangler skip OAuth. wrangler 4.x has no `pages domain` command; use the REST
API. The OAuth token can read zones but not write DNS records, use the DNS token for that.

## Long-term: domain split (needs Joshua decision + purchase)

All 19 App Store listings resolve to one apex, `heyitsmejosh.com`, which is the single
biggest template-farm signal in the portfolio. Genuinely splitting them means buying
per-app domains: money and a decision, not a code task. Same blocker shape as the
jaybulb.com purchase. Not a blocker for current work.

- Upload the refreshed App Store screenshots (`ios/screenshots/` in curvely, `screenshots/` in charwork) with the next version bump, the live listing still shows the pre-rebrand shots, and screenshots can only change on a new, editable version. 2026-08-31

## TUI pilot (2026-09-05)
- `curvely-tui` SwiftPM target (SwiftTUI). `swift build && ./.build/debug/curvely-tui "x^2" -5 5` fetches /api/sample and renders a text sparkline. mathjs stays server-side, not ported. Needs a real TTY.

## Ingested 2026-10-01
- [x] App Store screenshots are stale, refresh them. Done 2026-10-21, see the 1.2.6 note above.

## Ingested 2026-10-05
- [ ] QA

## Ingested 2026-10-16
- [x] Stale App Store screenshots (live 1.2.5 listing shows a blank icon in the preview). New shots and the icon fix are staged on 1.2.6, live once it ships. (screenshot: notes/attachments/2026-10-16/app-store-screenshots-1.png)

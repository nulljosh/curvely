# Tangent Roadmap

## v3 to v10 (Joshua's ask 2026-10-21: "loop to v5-10")
One major version per real feature batch, each on web, iOS and Mac, submitted once the last one clears review. Order is a proposal, Joshua can reshuffle.
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

## State 2026-10-21
2.0.0 is in App Review on iOS and Mac (1.2.6 was pulled and folded in). The web is live with v3 to v5 and the patterns; native 3.0.0 ships once 2.0.0 clears. Light mode follows the system setting on all three. The landing hero is now the live app, deployed 2026-10-21.

## Rename to Tangent (after 2.0.0 clears review)
- [ ] Rename Tangent to Tangent in the store. Joshua said "you decide" on 2026-10-21 and the pick is Tangent over Tilde. Repo, folder and tangent.jaybulb.com are done 2026-10-21; the App Store name waits on 2.0.0 clearing App Review, then the name probe and listing. Several Tangent apps exist and one is a math calculator, so probe first.

## In flight, grapher -> tangent hostname rename

Done 2026-08-27: Pages custom domain `curvely.heyitsmejosh.com` added to the `grapher`
project, and CNAME `tangent -> grapher-c2q.pages.dev` (proxied) created in the
heyitsmejosh.com zone. Cloudflare reports the domain `pending` while the cert issues.

Done 2026-08-30: `curvely.heyitsmejosh.com` and its `/privacy.html` both return 200, so
`ios/metadata/app-info/en-US.json` (privacyPolicyUrl) and
`ios/metadata/version/1.2.2/en-US.json` (supportUrl) now point at tangent, not grapher.
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

- Upload the refreshed App Store screenshots (`ios/screenshots/` in tangent, `screenshots/` in charwork) with the next version bump, the live listing still shows the pre-rebrand shots, and screenshots can only change on a new, editable version. 2026-08-31

## TUI pilot (2026-09-05)
- `tangent-tui` SwiftPM target (SwiftTUI). `swift build && ./.build/debug/tangent-tui "x^2" -5 5` fetches /api/sample and renders a text sparkline. mathjs stays server-side, not ported. Needs a real TTY.

## Ingested 2026-10-05
- [ ] QA


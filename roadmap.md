# Curvely Roadmap

## State 2026-09-20
iOS + macOS 1.2.4 WAITING_FOR_REVIEW: full-screen graph, no header or zoom buttons, glass
equation panel. 1.2.5 work is on main: collapsible panel, Mac scroll-wheel zoom, web +/-/0 keys.

- [ ] Recapture App Store screenshots (iPhone, iPad, Mac). Every live shot still shows the old
  header and zoom buttons. Upload with 1.2.5, screenshots only change on an editable version.
- [ ] Ship 1.2.5 once 1.2.4 clears review: `asc workflow run ship-ios VERSION:1.2.5`. The
  publish step is now `scripts/asc-submit.sh`. macOS is a raw xcodebuild archive + export
  with an automatic-signing plist, then `scripts/asc-submit.sh <app> <version> MAC_OS`.
- [ ] Support URL on the listing still says grapher.heyitsmejosh.com; move it to curvely.

- [ ] Verify iPad layout visually on simulator -- 2026-09-02. Code review found no
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

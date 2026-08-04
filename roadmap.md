# Curvely Roadmap

## Ship to App Store (blocked 2026-07-29 — three items left, all dashboard/manual)
Build 202607290328 (v1.1.0) uploaded and VALID on App Store Connect. Metadata complete: all ratings/content rights/categories/copyright/review contact set via asc CLI. Encryption exemption applied. Screenshot done 2026-07-29 (iPhone 6.5", `ios/.asc/screenshots.json`, launch-only capture — app seeds `x^2`/`sin(x)` by default). Availability + free pricing set via ASC dashboard (claude-in-chrome) 2026-07-29, 175 countries. `asc review submit` was attempted and rejected with THREE remaining blockers not caught by `asc validate` until submit-time:
1. **Privacy policy URL missing** — no privacy policy page exists for grapher.heyitsmejosh.com yet. Need to create one (client-side app, no data collection, should be a quick static page) and set via `asc apps info edit --support-url`-equivalent for privacy (check `asc app-setup info set --privacy-policy-url`).
2. **App Privacy declarations unpublished** — not available via public API, needs `asc web privacy pull/plan/apply/publish` (web-session flow) or manual dashboard completion at appStoreConnect.apple.com/apps/6794988370/appPrivacy.
3. **iPad screenshot required** (`ipadPro129`) — app apparently supports iPad (TARGETED_DEVICE_FAMILY in project.yml probably includes iPad by default from xcodegen), needs a second screenshot capture pass on an iPad Pro 12.9" simulator, same `asc-shots-pipeline` approach as iPhone.

Once all three are done, re-run: `asc review submit --app 6794988370 --version-id 16c69982-180c-4bbc-81d0-de81632d7b97 --build 0103486e-91de-4ac5-8d09-da7b8d07f6b5 --confirm`

## WKWebView shell (reviewed 2026-07-22)
Not a gap — `CLAUDE.md` documents this as intentional ("app has no native API needs"). Unlike Books, this was a deliberate choice, not an oversight. Revisit only if grapher ever needs a real native API (e.g. share sheet, widgets) that the web shell can't provide. If it's ever ported anyway, the blocker is replacing `mathjs` expression parsing/eval with a Swift equivalent — everything else (canvas plotting, equation list UI) maps cleanly to SwiftUI `Canvas`.

## From /work start (imported 2026-08-03)

Re-checked ship state via `asc review doctor --app 6794988370` and cleared 3 of the 5 blockers. Stopped before the iPad screenshot: usage limit near cap (session 85% WARNING) and a simulator capture run costs ~10% on its own.

Current ASC facts (verified 2026-08-03):
- App `6794988370`, bundle `com.nulljosh.grapher`, SKU `grapher-app`
- Version **1.1.0**, id `16c69982-180c-4bbc-81d0-de81632d7b97`, state `PREPARE_FOR_SUBMISSION`, reviewState `NOT_SUBMITTED`
- Build `0103486e-91de-4ac5-8d09-da7b8d07f6b5` (202607290328) already uploaded and VALID — **no rebuild/re-archive needed**
- appInfoLocalization (en-US): `d798e6c8-fbcb-49d1-9dca-86427292c872` — holds subtitle + privacyPolicyUrl
- appStoreVersionLocalization (en-US): `5235dfcd-4909-47a4-8a5f-3adf5b8cca58` — holds whatsNew; description/keywords/supportUrl already set
- reviewDetail `b9dead75-aa07-4aaa-878e-25b27bebf133`, configured
- `doctor` reports **0 errors / 0 blocking**, 3 warnings — but the 2026-07-29 submit attempt proves doctor misses the App-Privacy and iPad-screenshot blockers until submit-time. Do not trust "0 blocking".
- `grapher.heyitsmejosh.com` is live, HTTP 200, served by Cloudflare (the `.vercel/project.json` "grapher" project is legacy — publish the privacy page to Cloudflare, not Vercel)
- `ios/project.yml` has `TARGETED_DEVICE_FAMILY: "1,2"` (iPhone + iPad) — this is *why* the iPad screenshot is demanded

Done 2026-08-03:

Loose end:
- [ ] Stray empty review submission `2dc7aedd-0dee-4696-8491-f8e21304b93e` (created by a failed `asc review submit` attempt, state READY_FOR_REVIEW, no items). `asc review submissions-cancel` refuses it ("Resource is not in cancellable state"). Harmless as far as we can tell — the real submission went through — but check it doesn't confuse the next release, and clear it via the dashboard if it lingers.

## TestFlight signing defect (found 2026-08-03)

- [ ] **iOS builds are likely TestFlight-ineligible (ITMS-90886).** This repo has **no `.entitlements` file and no `CODE_SIGN_ENTITLEMENTS`** anywhere, so the app signs without an `application-identifier` while the provisioning profile has one. Apple reports it as "not required to fix", which is why it went unnoticed — but the build cannot be distributed via TestFlight.
  Fix proven on Uprighty 2026-08-03 (commit `df346b8`): add `<Target>.entitlements` with `application-identifier` = `$(AppIdentifierPrefix)$(CFBundleIdentifier)`, wire via `CODE_SIGN_ENTITLEMENTS` in `project.yml`, hand-commit it (xcodegen silently drops keys).
  Verify: `codesign -d --entitlements :- <exported>.app` should show `application-identifier`, `beta-reports-active: true`, `get-task-allow: false`. An entitlement change invalidates the profile — refetch with `asc signing fetch`.

## Ingested 2026-08-04
- [x] Website still shows the old name (grapher) — live site was serving a pre-rename build (`<title>Grapher</title>`); redeployed to CF Pages, now `Curvely`. Also fixed `package.json` name `grapher`→`curvely`.
- [x] Equations bottom drawer is too small — mobile drawer was a fixed 200px; now `--drawer-h: 45dvh` in `.main-layout`, with the graph pane's calc and `.eq-list-container` both deriving from it (`src/index.css`)
- [x] Header font still monospaced — root cause: shared `heyitsmejosh.com/tokens.css` defines `--font` as a mono stack. Overrode `--font` locally in `src/index.css` `:root` to the system sans stack; also dropped the unused Space Grotesk Google Fonts link and switched graph axis labels off it.

## From Apple Notes (imported 2026-08-04)
- [ ] Domain still `grapher.heyitsmejosh.com` (CF Pages project is also named `grapher`; `curvely.heyitsmejosh.com` does not resolve). Renaming means adding the new custom domain to the Pages project + a DNS record, then updating ASC support/privacy URLs and `ios/` shell. Left alone — outward-facing rename, user's call.
- [ ] `CLAUDE.md` still references `Grapher.xcodeproj` in the iOS build steps (xcodegen target name never renamed).

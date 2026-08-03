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
- [x] **iPad screenshot (`ipadPro129`)** — captured on the iPad Pro 13-inch (M5) sim (2064×2752, valid for `APP_IPAD_PRO_3GEN_129`) via plain xcodebuild + `simctl io screenshot`; `TARGETED_DEVICE_FAMILY` untouched so the VALID build stands. Saved to `ios/screenshots/ipad/01-graph.png`, uploaded with `asc screenshots upload --version-localization 5235dfcd-4909-47a4-8a5f-3adf5b8cca58 --device-type IPAD_PRO_3GEN_129` — asset `8ecbb239-2692-434b-a347-6dc32a54bf98`, state COMPLETE.
  - Noticed while reviewing the capture: the in-app header still reads **"Grapher"**, not "Curvely" — the App Store name is Curvely, so the screenshot shows the old brand. Not fixed here (would need a code change + rebuild + re-upload, invalidating the VALID build). Worth fixing before the next build.

- [x] **App Privacy declarations** — applied and published via `asc web` after Joshua re-ran the login: `published: true`, DATA_NOT_COLLECTED, usageId `5c6cf706-ec55-47ef-8928-782bc7f36d8c`.
- [x] **Grapher → Curvely rename (user-facing only)** — header (`src/App.jsx`), page `<title>` (`index.html`), `CFBundleDisplayName`/`CFBundleName` (`ios/App/Info.plist`), doc H1s. Scheme/target/bundle ID (`com.nulljosh.grapher`) and the "Grapher AppStore" provisioning profile name deliberately untouched — wiring, not branding.
- [x] **Rebuild + upload** — build `202608031005`, id `85485026-ac24-42f2-a214-fc1a2c4bd3be`, VALID, attached to version 1.1.0. The old 202607290328 build is superseded.
- [x] **Screenshots re-shot with correct branding** — iPad `3c5f39cc-ca06-4a51-aef5-e804a6149d47` (2064×2752) and iPhone 6.5" `a3cd2858-9f4f-4d1d-9b25-ac3843d49508` (1284×2778); stale "Grapher"-branded assets deleted (`8ecbb239…`, `cea08fc2…`). Header verified reading "Curvely" in the capture.
- [x] **SUBMITTED FOR REVIEW 2026-08-03** — review submission `108e1f88-69e9-4278-9a4b-35d98db58cea`, state WAITING_FOR_REVIEW, submittedDate 2026-08-03T17:10:41Z. Note: `asc review submit` could not drive this (it kept failing to reuse the pre-existing prepared submission); the working path was `asc versions attach-build --version-id … --build-id …` followed by `asc review submissions-submit --id 108e1f88… --confirm`.

Loose end:
- [ ] Stray empty review submission `2dc7aedd-0dee-4696-8491-f8e21304b93e` (created by a failed `asc review submit` attempt, state READY_FOR_REVIEW, no items). `asc review submissions-cancel` refuses it ("Resource is not in cancellable state"). Harmless as far as we can tell — the real submission went through — but check it doesn't confuse the next release, and clear it via the dashboard if it lingers.

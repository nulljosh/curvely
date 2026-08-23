# Curvely Roadmap

## App Review rejection reason — READ FROM RESOLUTION CENTER 2026-08-12

**Guideline 5.6 — Developer Code of Conduct — Review Suspended.** Not an app-specific
defect. Verbatim: *"the current submission does not meet the required quality standard for
distribution on the App Store... this app is not eligible for resubmission before August
18th, 2026. Replies and resubmissions before this date will not be reviewed."*

Apple's listed next steps before resubmitting: no placeholder/unfinished/unrefined content;
every screen reviewed and tested; stable across **all** supported devices (iPad included if
the app is offered there); and **detailed notes of the improvements made** in the App Review
Information → Notes field. Continued similar submissions are warned as grounds for removal
from the Developer Program.

This hit 4 apps at once on 2026-08-09: curvely, nyc, transcriptly, wiretext.

Source: `asc web review show --app 6794988370 --apple-id trommatic@icloud.com` (needs `asc-login`;
the public API only returns a generic "unresolved issues" wrapper). Submissions frozen
The freeze lifted 2026-08-18; submission is now gated only on the four in-flight review verdicts.

## ASC state VERIFIED 2026-08-12 (`asc versions list`)

**iOS 1.1.0 is `REJECTED`** — not "blocked on three pre-submission items" as the section
below says. It was submitted 2026-08-03 and came back rejected. The privacy-policy /
App Privacy / iPad-screenshot blockers listed below were all cleared before submission.
The actual rejection reason lives only in Resolution Center (`asc web review show`, needs
`asc-login`) — the public API returns a generic wrapper. Also: "What's New" is empty,
fix via `asc metadata push` regardless.

Freeze lifted 2026-08-18 (Guideline 5.6 suspension expired). Submitted that day and now
WAITING_FOR_REVIEW: Curvely iOS 1.2.0, Wiretext iOS 1.1.0, Wordroot iOS 1.0, Healstack iOS 2.3.4.
**Held pending those four verdicts — never a batch:** Sparkjar iOS+Mac, BCGD iOS+Mac, Wordroot Mac,
Lexly Mac. All six are `asc validate` clean (0 errors, 0 blocking) with a VALID build attached, so
each is one `asc review submit` away. Do not submit until the in-flight verdicts land.

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

## From Apple Notes (imported 2026-08-04)
- [ ] Domain still `grapher.heyitsmejosh.com` (CF Pages project is also named `grapher`; `curvely.heyitsmejosh.com` does not resolve). Renaming means adding the new custom domain to the Pages project + a DNS record, then updating ASC support/privacy URLs and `ios/` shell. Left alone — outward-facing rename, user's call.
- [ ] `CLAUDE.md` references `Grapher.xcodeproj` in the iOS build steps. Checked 2026-08-04: **the doc is accurate, not stale** — `ios/project.yml` still has `name: Grapher` and target/scheme `Grapher-iOS`, so xcodegen really does produce `Grapher.xcodeproj`. The actual work is renaming the xcodegen project/target/scheme to Curvely, which also touches the scheme name used by any ship workflow, the bundle id `com.nulljosh.grapher`, and the new `ios/Grapher.entitlements`. Not a doc edit — left alone as part of the same outward-facing rename as the domain item above.

## App Store submission freeze — LIFTED 2026-08-18
Freeze lifted 2026-08-18 (Guideline 5.6 suspension expired). Submitted that day and now
WAITING_FOR_REVIEW: Curvely iOS 1.2.0, Wiretext iOS 1.1.0, Wordroot iOS 1.0, Healstack iOS 2.3.4.
**Held pending those four verdicts — never a batch:** Sparkjar iOS+Mac, BCGD iOS+Mac, Wordroot Mac,
Lexly Mac. All six are `asc validate` clean (0 errors, 0 blocking) with a VALID build attached, so
each is one `asc review submit` away. Do not submit until the in-flight verdicts land.

## Decision 2026-08-10: keep the record, build the app out
Not withdrawing. The App Store record (6794988370) stays dormant until the app is real. Payments
alone will not clear Guideline 4.2 — a paid wrapper is still a wrapper.

> ~~Resume note (2026-08-11): a `wip: partial work from /work notes ingest` commit holds unfinished,
> unverified changes for the items above. Review `git show HEAD` before building on it — it was
> committed mid-flight, not reviewed, and is unpushed.~~
> **STALE — resolved 2026-08-13.** That commit is `f307318` and it is a single complete 19-line
> `ios/ExportOptions.plist` (app-store-connect method, manual signing, `Grapher AppStore` profile).
> Nothing unfinished, and it has been on `origin/main` since 08-11 — the "unpushed" claim was wrong.
> Same false-unpushed-wip note turned up in bookrank, talli, litigate and healstack the same day.

## Guideline 5.6 resubmission checklist — prepared 2026-08-12, DO NOT SUBMIT BEFORE 2026-08-18

Apple's 5.6 notice makes one thing mandatory that is easy to miss: **"Include detailed notes
of the improvements made to the app in the Notes field of the App Review Information section."**
A resubmission without those notes is a wasted attempt, and 5.6 warns that repeat submissions
with the same issues can mean removal from the Developer Program.

The notes must describe improvements that were **actually made**. Nothing has been written into
ASC yet on purpose — there is nothing truthful to claim until the work below is done.

Before resubmitting:

- [ ] Walk every screen and interaction once, on device. 5.6 is a quality judgement, not a
      spec violation — the reviewer decided the app felt unfinished.
- [ ] Test on **every** device family the app is offered on. If `TARGETED_DEVICE_FAMILY` is
      `"1,2"` the app must be genuinely good on iPad, not merely launchable. Narrowing to
      iPhone-only is a legitimate alternative to making iPad good.
- [ ] Confirm a non-empty "What's New" (`asc metadata push`).
- [ ] Then write the improvement notes:
      `asc review details-update --id b9dead75-aa07-4aaa-878e-25b27bebf133 --notes "..."`
- [ ] Only then submit. Review detail id for this version: `b9dead75-aa07-4aaa-878e-25b27bebf133`.

## From Apple Notes (imported 2026-08-13)
- [ ] Migrate Curvely (Grapher) from Vercel to Cloudflare — note cites ongoing Vercel issues; see [[project_vercel_to_cloudflare_migration]]

## 5.6 defect verification 2026-08-18

**Verdict: cited defect disproven as still-present — it was fixed before the resubmission.**

- iOS 1.2.0 is `WAITING_FOR_REVIEW` (submitted ~04:06 today), build `202608180347` uploaded
  03:50, VALID. Not a state this repo should touch further.
- Apple's actual 5.6 complaint was minimum functionality — "Curvely 4 files / 150 lines … still
  a WKWebView shell" (`ship-plan.md`). Current `ios/App/` is 911 lines across 9 Swift files
  (`Expression.swift` 279, `GraphView.swift` 180, `EquationListView.swift` 184 …) plus a
  125-line `Checks/main.swift`. **No WebKit import anywhere in the sources** — the only
  `WKWebView` grep hits are stale generated headers under `ios/.build/`.
- "No landing page" (2026-08-18 Notes review) no longer holds: commit `ae4dce4` added a
  marketing landing page at `/` and moved the app to `/app`. `grapher.heyitsmejosh.com` → 200
  (title "Curvely — a graphing calculator that stays out of the way"), `/app` → 200.
- Registered ASC support URL is `https://grapher.heyitsmejosh.com` (live); no marketing URL set.
  The dead `curvely.heyitsmejosh.com` host is **not** referenced by the ASC record, so it is a
  cosmetic rename item only, not a review risk.

No code change was needed. Do not submit anything further until this review clears —
`ship-plan.md` step 5 is one app at a time, and Wiretext went in alongside this one.

## Ingested 2026-08-22
- [ ] Graph view is too small — first amendment to ship now that v1.0 is submitted and approved on the App Store. (From Notes: "Submitted and approved on App Store / First version / Graph view too small / That's the first amendment".)

## 2026-08-23 — 1.2.1 to ship the iPhone graph fix
iOS 1.2.0 is Ready for Distribution, but HEAD (cc734fe "fix(ios): give the graph the screen on
iPhone") landed after that build. It is pushed to origin/main and NOT in the shipped binary.
- [ ] Bump to 1.2.1, archive, upload, submit so the fix actually reaches users.

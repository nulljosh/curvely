# Tangent loop handoff (2026-10-21, 10:44)

## What the loop is

Joshua's `/loop` for Tangent. It works down `roadmap.md` one major version at a time, toward v100. Each version lands on web, iOS and Mac together, gets tests and a live QA pass, is committed and pushed, and the web is deployed. Each major also goes to the App Store as soon as the version before it clears review: bump, build, upload, screenshots, submit, without asking.

## Where things stand

- 2.0.0 is in App Review on iOS and Mac. It replaces 1.2.6, which was pulled and folded in. It has light mode, points, parametric and polar curves, inequality shading, key points, tap a dot to hide a curve, and native sliders.
- 3.0 is built and committed on all three surfaces: v3 functions, v4 lists and ranges, v5 slider bounds and a play button, and 85 one-tap patterns in 11 categories. The web is live. Native 3.0.0 waits for 2.0.0 to clear.
- The repo is nulljosh/tangent, public, Apache 2.0, checked out at `~/Documents/Code/tangent`. Labs no longer tracks it. CI is green on web tests, Swift checks and docs.
- The landing hero is the live app in a frame above a blue title strip, with the Apollo art in its own band above the footer. It is deployed and verified live.
- The App Store privacy URL is tangent.jaybulb.com/app/privacy.html.
- The roadmap runs to v100. v6 is the next open version.
- The repo, folder and domain are Tangent as of 2026-10-21 (tangent.jaybulb.com, Pages project grapher kept on purpose). The App Store name is still Tangent until Apple accepts 2.0.0. The Tangent name probe waits on that review.

## Next, in order

1. Ship 3.0 (v3 to v5 and the patterns) the moment 2.0.0 is approved: bump to 3.0.0, build, upload, screenshots, submit.
2. v6 saved graphs and share links. Web share links keep their state in the URL; native syncs through iCloud.
3. v7 onward in `roadmap.md` order, on all three platforms each time.
4. Store rename to Tangent once 2.0.0 clears review. Repo, folder and domain are already done. Run the asc name probe on Tangent first (asc-name-creator), then the store listing. Do not start it before 2.0.0 clears.

## Restart prompt

```
/loop work on Tangent toward v100, forever: pick the next roadmap version (roadmap.md v6 onward), build it on web+iOS+macOS, test, QA, commit, push, deploy web; ship every major semver to the App Store (bump, build, upload, shots, submit, never ask) as soon as the previous version clears review. Next in order: v6 saved graphs and share links; ship 3.0 (v3-v5 plus patterns) the moment 2.0 is approved; rename to Tangent (Joshua said "you decide"; ASC name probe first) only once 2.0.0 has cleared review.
```

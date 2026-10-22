# Pan loop handoff (2026-10-22, early morning)

## What the loop is

Joshua's `/loop` for Pan. It works down `roadmap.md` one major version at a time, toward v100. Each version lands on web, iOS and Mac together, gets tests and a live QA pass, is committed and pushed, and the web is deployed. Each major also goes to the App Store as soon as the version before it clears review: bump, build, upload, screenshots, submit, without asking.

## Where things stand

- 2.0.0 was submitted to App Review on iOS and Mac on 2026-10-21 and was still in review at the last check. It replaces 1.2.6, which was pulled and folded in. It has light mode, points, parametric and polar curves, inequality shading, key points, tap a dot to hide a curve, and native sliders.
- 3.0 is built and committed on all three surfaces: v3 functions, v4 lists and ranges, v5 slider bounds and a play button, and 85 one-tap patterns in 11 categories. The web is live. Native 3.0.0 waits for 2.0.0 to clear.
- The repo is nulljosh/pan, public, Apache 2.0, checked out at `~/Documents/Code/pan`. Labs no longer tracks it. CI was green on web tests, Swift checks and docs.
- The landing hero is the live app in a frame above a blue title strip, with the Pan engraving in its own band above the footer. Deployed and verified live.
- The App Store privacy URL is curvely.jaybulb.com/privacy.html, which still serves.
- Everything is Pan as of 2026-10-21: repo, folder, pan.jaybulb.com, landing, web app, native product name, font and icon bundle. Kept on purpose: bundle IDs, the Android package, the grapher Pages project, the curvely localStorage key, and the old curvely. and tangent. hosts. The App Store listing is still Curvely until 2.0.0 clears review.
- Roadmap ingested from Apple Notes on 2026-10-21: the store name (P1, waits on Apple accepting Pan), an odd scroll where the equation sheet sits over the graph (P2), and a gap list against Desmos (P2).
- The roadmap runs to v100. v6 is the next open version.

## Next, in order

1. Ship 3.0 (v3 to v5 and the patterns) the moment 2.0.0 is approved: bump to 3.0.0, build, upload, screenshots, submit.
2. v6 saved graphs and share links. Web share links keep their state in the URL; native syncs through iCloud.
3. Fix the scroll bug where the equation sheet sits over the graph (P2, ingested 2026-10-21).
4. File the Desmos feature gaps in `roadmap.md` (P2, ingested 2026-10-21).
5. v7 onward in `roadmap.md` order, on all three platforms each time.
6. Store rename to Pan once 2.0.0 clears review. Run the asc name probe on Pan first (asc-name-creator), then the store listing. Do not start it before 2.0.0 clears.

## Restart prompt

```
/loop work on Pan toward v100, forever: pick the next roadmap version (roadmap.md v6 onward), build it on web+iOS+macOS, test, QA, commit, push, deploy web; ship every major semver to the App Store (bump, build, upload, shots, submit, never ask) as soon as the previous version clears review. Next in order: v6 saved graphs and share links; ship 3.0 (v3-v5 plus patterns) the moment 2.0 is approved; rename to Pan (Joshua said "you decide"; ASC name probe first) only once 2.0.0 has cleared review.
```

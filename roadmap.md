# Grapher Roadmap

## Ship to App Store (in progress 2026-07-29)
AppIcon.appiconset generated from icon.svg, wired into project.yml (DEVELOPMENT_TEAM QMM486NPYC added — was missing), `xcodebuild archive` succeeded at /tmp/Grapher.xcarchive. Remaining: export IPA, `asc` upload, `asc workflow run ship-ios VERSION:1.1.0` submit. Plan at ~/.claude/plans/stateless-snacking-minsky.md. Resume next session — stopped here at 90% usage, don't re-do the archive step.

## WKWebView shell (reviewed 2026-07-22)
Not a gap — `CLAUDE.md` documents this as intentional ("app has no native API needs"). Unlike Books, this was a deliberate choice, not an oversight. Revisit only if grapher ever needs a real native API (e.g. share sheet, widgets) that the web shell can't provide. If it's ever ported anyway, the blocker is replacing `mathjs` expression parsing/eval with a Swift equivalent — everything else (canvas plotting, equation list UI) maps cleanly to SwiftUI `Canvas`.

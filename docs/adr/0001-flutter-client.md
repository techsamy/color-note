# 0001 — Flutter for the client app
- Status: accepted · Date: 2026-11-05

## Context
Android first, iOS (and possibly web) later; single developer team.
## Decision
Build the client in Flutter. Native Kotlin only for home-screen widgets and platform glue.
## Consequences
One codebase for future iOS/web. Widgets need a small Kotlin layer. APK slightly larger than pure native.

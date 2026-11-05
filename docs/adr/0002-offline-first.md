# 0002 — Offline-first, local SQLite is the source of truth
- Status: accepted · Date: 2026-11-05

## Context
Users expect instant capture and full use with no account (ColorNote parity).
## Decision
UI reads/writes only the local Drift DB. A background sync engine reconciles with the server.
## Consequences
Need outbox, tombstones, cursors, conflict handling. Network failures never affect editing.

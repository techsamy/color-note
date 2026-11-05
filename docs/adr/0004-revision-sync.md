# 0004 — Revision-based sync with conflict copies
- Status: accepted · Date: 2026-11-05

## Context
Same note can be edited on multiple offline devices.
## Decision
Per-note `version` for conflict detection (push with base_version; mismatch = conflict → client keeps server copy and saves its edits as a "conflicted copy"). Per-user change feed (`change_log`, seq cursor) for pull, fanned out to every member of a note — so note sharing later only adds members.
## Consequences
No silent data loss; users occasionally see duplicate notes to merge manually. Field-level merge can be added later.

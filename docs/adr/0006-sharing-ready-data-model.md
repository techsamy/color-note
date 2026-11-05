# 0006 — Sharing-ready data model from v1.0
- Status: accepted · Date: 2026-11-05

## Context
Note sharing between users is planned for v1.3. Retro-fitting sharing onto a per-user sync model would require a sync redesign and migration of every device.
## Decision
From v1.0 the server splits notes into shared content (`notes`) and per-user state (`note_members`: colour, pin, archive, reminder, permission), and sync pulls from a per-user `change_log` feed. In v1.0 each note has only its owner as member.
## Consequences
Slightly more server complexity in v1.0; sharing later = new endpoints + UI only. Client API stays a single flat note object.

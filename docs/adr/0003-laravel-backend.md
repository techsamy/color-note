# 0003 — Laravel + MySQL + Sanctum backend
- Status: accepted · Date: 2026-11-05

## Context
Need accounts, sync and backups under our control; PHP hosting is available.
## Decision
Laravel REST API at /api/v1, MySQL 8, Redis for queue/cache/rate limits, Sanctum tokens, Google ID-token sign-in.
## Consequences
We operate the server (backups, updates, monitoring). No vendor lock-in.

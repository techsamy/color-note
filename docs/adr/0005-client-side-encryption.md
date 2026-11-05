# 0005 — Client-side encryption for locked notes and backups
- Status: accepted · Date: 2026-11-05

## Context
Locked notes must stay private even if the server or a backup file leaks.
## Decision
A random DEK (AES-256-GCM) encrypts locked notes; it is wrapped by a KEK derived with Argon2id from the master password (and optionally a recovery key). The wrapped DEK + salt sync via the server so the same password works on every device; the server never sees the password or plain key. Backups use their own password-derived key.
## Consequences
Password change only re-wraps the DEK. Forgotten password without recovery key = locked notes unrecoverable. Locked notes excluded from search index and cannot be shared (until per-note public-key wrapping in v2).

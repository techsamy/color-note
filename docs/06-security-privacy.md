# 06 — Security & Privacy

## 1. Threat model (summary)
| Threat | Mitigation |
|---|---|
| Lost/stolen phone | Note lock (AES-GCM, Argon2id key), biometric gate, FLAG_SECURE on locked notes, auto-relock |
| Server breach | Locked notes are E2E-encrypted (server sees ciphertext); passwords bcrypt/argon2; DB encrypted at rest (disk); tokens hashed (Sanctum default) |
| Network MITM | HTTPS only, HSTS, no cleartext traffic (`android:usesCleartextTraffic="false"`); optional certificate pinning (v1.1) |
| Account takeover | Rate-limited auth, no user enumeration, email verification, token revocation per device |
| Malicious backup file | Validate manifest + size limits, authenticated decryption (GCM tag), schema validation before import |
| Data leak via Android | `allowBackup` controlled via `data_extraction_rules.xml` (exclude secure prefs & DB if lock enabled), no logging of note content |

## 2. Rules
1. **Never log** note titles/bodies, passwords, tokens or keys — in app or server.
2. Crypto: only AES-256-GCM (random 96-bit nonce per encryption) and Argon2id (default m = 19 MiB, t = 2, p = 1 — OWASP baseline; ~0.3 s in the Dart VM, 64 MiB/t=3 measured ~1.1 s and slower on phones/web. Params are stored with every key/backup, so they can be raised later without breaking old data). No custom crypto.
3. Store secrets only in `flutter_secure_storage` (Keystore-backed).
4. Server validates every input via FormRequest; every query scoped by `user_id` (policies + global scope).
5. Dependencies: Dependabot/Renovate on; `composer audit` and `flutter pub outdated` in CI.
6. `.env`, keystores (`*.jks`), `key.properties`, `google-services.json` never committed.

## 3. Privacy (completely free, no tracking)
- No ads SDK, no analytics SDK. Crash reporting (e.g. Sentry) **opt-in**, with PII scrubbing.
- Play **Data safety** form (v1.0): collected = email, name (optional), user content (notes) — *only when account is used*, encrypted in transit, user can request deletion. Not shared with third parties.
- **Privacy policy** URL required on Play Store and in-app (Settings → About).
- **Account deletion**: in-app (`DELETE /me`) + a public web URL to request deletion (Play requirement).

## 4. Android permissions (request only when needed)
| Permission | Why | When requested |
|---|---|---|
| `INTERNET` | Sync | Install-time |
| `POST_NOTIFICATIONS` (13+) | Reminders, status-bar pin | When first reminder/pin is set |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Exact reminders | When first reminder is set (check Play policy eligibility) |
| `RECEIVE_BOOT_COMPLETED` | Reschedule reminders | Install-time |
| `USE_BIOMETRIC` | Unlock | Install-time |
| `VIBRATE` | Reminder | Install-time |

No storage permission — use Storage Access Framework (file picker) for backup/restore.

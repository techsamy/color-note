# 04 — Data Model

## 1. Note colours (fixed enum, stored as int)

| Value | Key | Default label | Light bg | Dark bg |
|---|---|---|---|---|
| 0 | `red` | Red | define in `note_palette.dart` | |
| 1 | `orange` | Orange | | |
| 2 | `yellow` | Yellow | | |
| 3 | `green` | Green | | |
| 4 | `blue` | Blue | | |
| 5 | `purple` | Purple | | |
| 6 | `black` | Black | | |
| 7 | `grey` | Grey | | |
| 8 | `white` | White | | |

Never reorder or reuse values — they're persisted and synced. New colours get new values.

## 2. Local database (Drift / SQLite)

### `notes`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID v7, generated on device |
| type | INTEGER | 0 = text, 1 = checklist |
| title | TEXT | ciphertext (base64) if locked |
| body | TEXT | text note: plain text. checklist: JSON `[{"id","text","checked","order"}]`. ciphertext if locked |
| color | INTEGER | 0–8 |
| is_pinned | BOOL | pinned at top of list |
| is_archived | BOOL | |
| is_locked | BOOL | |
| crypto_meta | TEXT NULL | JSON `{v, nonce, alg}` for locked notes |
| reminder_at | INTEGER NULL | UTC epoch ms |
| reminder_rule | TEXT NULL | `{"freq":"daily|weekly|monthly|yearly","interval":1,"byDay":[1,3]}` |
| reminder_all_day | BOOL | |
| status_bar_pinned | BOOL | ongoing notification |
| calendar_date | TEXT NULL | `YYYY-MM-DD` (v1.1) |
| created_at | INTEGER | UTC epoch ms |
| updated_at | INTEGER | UTC epoch ms |
| deleted_at | INTEGER NULL | trash (tombstone) |
| base_version | INTEGER | server version last synced, 0 = never synced |
| dirty | BOOL | needs push |
| owner_user_uuid | TEXT NULL | null = my note (or not yet synced); set when the note is shared *with* me |
| my_permission | INTEGER | 0 = owner, 1 = editor, 2 = viewer (sharing, Phase 4) |

Indexes: `(deleted_at, is_archived, is_pinned, updated_at)`, `(color)`, `(reminder_at)`.

### `notes_fts` (FTS5 virtual table)
`title`, `body_text` (checklist flattened to text) — kept in sync via triggers. Locked notes are **not** indexed.

### `color_labels`
| color INTEGER PK | label TEXT | updated_at | dirty | base_version |

### `sync_state`
| key TEXT PK | value TEXT |  — e.g. `cursor`, `last_sync_at`, `device_id`

### `settings`
Stored in `shared_preferences` (non-sensitive) — theme, font size, sort, view mode, default colour.
Sensitive values (tokens, wrapped keys, password verifier) → `flutter_secure_storage`.

## 3. Server database (MySQL)

```sql
users (
  id BIGINT UNSIGNED PK AUTO_INCREMENT,
  uuid CHAR(36) UNIQUE,
  name VARCHAR(100) NULL,
  email VARCHAR(191) UNIQUE,
  password VARCHAR(255) NULL,          -- null for Google-only accounts
  google_id VARCHAR(64) UNIQUE NULL,
  email_verified_at TIMESTAMP NULL,
  feed_seq BIGINT UNSIGNED DEFAULT 0,  -- last seq in this user's change feed
  -- master password (server never sees password or plain key):
  kdf_salt VARBINARY(32) NULL,
  kdf_params JSON NULL,                -- {alg:"argon2id", m, t, p}
  wrapped_dek TEXT NULL,               -- DEK encrypted with password-derived KEK
  recovery_wrapped_dek TEXT NULL,      -- DEK encrypted with recovery-key KEK (optional)
  key_version INT DEFAULT 0,           -- bump on password change
  fcm_tokens via devices table,
  created_at, updated_at, deleted_at
)

devices (
  id BIGINT PK, user_id FK, device_uuid CHAR(36), name VARCHAR(100),
  platform VARCHAR(20), app_version VARCHAR(20), last_seen_at TIMESTAMP,
  UNIQUE(user_id, device_uuid)
)

-- Shared content of a note (same for every member)
notes (
  id CHAR(36) PK,                      -- client UUID v7
  owner_id BIGINT FK INDEX,
  type TINYINT,
  title TEXT, body MEDIUMTEXT,         -- opaque to server if is_locked
  is_locked BOOLEAN, crypto_meta JSON NULL,
  calendar_date DATE NULL,
  client_created_at BIGINT, client_updated_at BIGINT, deleted_at BIGINT NULL,
  version INT UNSIGNED,                -- +1 per change, used for conflict detection
  updated_by_user_id BIGINT NULL, updated_by_device_id BIGINT NULL
)

-- Per-user view of a note. Owner always has a row; shared members get rows in Phase 4.
note_members (
  note_id CHAR(36) FK, user_id BIGINT FK,
  permission TINYINT,                  -- 0 owner, 1 editor, 2 viewer
  status TINYINT,                      -- 0 pending, 1 active, 2 left/revoked
  color TINYINT, is_pinned, is_archived BOOLEAN,           -- personal
  reminder_at BIGINT NULL, reminder_rule JSON NULL,        -- personal
  reminder_all_day BOOLEAN, status_bar_pinned BOOLEAN,     -- personal
  version INT UNSIGNED,                -- version of the personal fields
  invited_by BIGINT NULL, created_at, updated_at,
  PRIMARY KEY (note_id, user_id), INDEX (user_id)
)

-- Per-user ordered change feed (what /sync/pull reads)
change_log (
  user_id BIGINT, seq BIGINT UNSIGNED,
  entity VARCHAR(20),                  -- note | note_member | color_label | ...
  entity_id VARCHAR(40),
  created_at TIMESTAMP,
  PRIMARY KEY (user_id, seq)
)

share_invites (                         -- Phase 4: invite by email (incl. non-users)
  id CHAR(36) PK, note_id FK, inviter_id FK, email VARCHAR(191),
  permission TINYINT, token_hash CHAR(64), expires_at, accepted_at NULL
)

color_labels (
  user_id FK, color TINYINT, label VARCHAR(50), version INT,
  PRIMARY KEY (user_id, color)
)

personal_access_tokens  -- Sanctum default
```

**Feed assignment:** in one transaction: update the note (`version + 1`), then for each active member (sorted by `user_id` to avoid deadlocks) `SELECT feed_seq FROM users WHERE id=? FOR UPDATE`, increment, insert `change_log(user_id, seq, 'note', id)`. Pull returns the *current* state of each referenced entity merged with that user's `note_members` fields — so each user gets a strictly ordered feed, and sharing just means "more members".

In v1 (no sharing) every note has exactly one `note_members` row (the owner) — the client sees a single flat note object; the split is a server detail.

**Purging:** tombstones older than 90 days AND older than every device's `last_seen_at` are hard-deleted by `PurgeTrashJob`.

## 4. Backup file format (`.huenote`)
```
zip
├─ manifest.json   {format_version, app_version, created_at, note_count, kdf:{alg:"argon2id", salt, m, t, p}, cipher:"aes-256-gcm", nonce}
└─ data.bin        AES-GCM( JSON { notes:[...], color_labels:[...], settings:{...} } )
```
Always bump `format_version` on change and keep readers for all previous versions.

# 07 — UI / UX Guidelines

## 1. Principles
1. **Zero-friction capture** — FAB on home opens a new note with cursor ready; no dialogs before typing.
2. **Colour is identity** — note colour shows in list card, editor background tint, widget, calendar dot.
3. **Never ask "Save?"** — auto-save always; back = save & close.
4. **Reversible actions** — delete/archive show a SnackBar with *Undo* (5 s).
5. **One-hand use** — primary actions in bottom half (FAB, bottom bar in editor).

## 2. Design system
- Material 3, `ColorScheme.fromSeed` for app chrome; Android 12+ dynamic colour optional (setting).
- Note palette: separate fixed `NotePalette` with light + dark variant for each of the 9 colours; text colour picked to keep contrast ≥ 4.5:1.
- Typography: system font (Roboto) — font size setting scales editor/body only (S / M / L / XL).
- Spacing scale: 4, 8, 12, 16, 24, 32. Corner radius: cards 12, sheets 28.
- Icons: Material Symbols (rounded).
- All tokens live in `lib/app/theme/` — **no hard-coded colours or sizes in widgets**.

## 3. Screens (MVP)
| Screen | Key elements |
|---|---|
| Home / Notes | Top app bar (search, view toggle, sort), colour filter chips, list/grid of note cards (pinned section first), FAB (+ → Text / Checklist) |
| Note editor (text) | Colour picker in app bar, title field, body, bottom bar: reminder, lock, share, more (archive, delete, duplicate, convert) |
| Note editor (checklist) | Add-item row, drag handles, checkbox, swipe-to-delete item, "checked items" collapsible section |
| Search | Live results, highlights matches, filter by colour |
| Archive / Trash | Same card list; trash shows "deleted N days ago", empty trash action |
| Reminder sheet | Date, time, repeat (none/daily/weekly/monthly/yearly), pin to status bar toggle |
| Lock setup / unlock | Master password create/confirm, biometric toggle, warning about unrecoverable password |
| Settings | Theme, font size, default colour, colour labels, sort, checklist behaviour, backup & restore, account & sync, about/privacy |
| Account | Sign in (Google / email), sync status, last synced, devices, sign out, delete account |

## 4. Navigation
Drawer or bottom navigation: **Notes · Calendar (v1.1) · Archive · Trash · Settings**.
Deep links: `huenote://note/<id>` (from notifications & widgets).

## 5. States every screen must handle
Empty (illustration + hint), loading (skeleton, only for network screens), error (message + retry), locked content placeholder.

## 6. Accessibility checklist
- Every icon button has a `tooltip`/semantic label.
- Colour is never the only signal: colour filter chips include the label text.
- Supports system font scale up to 200 % without overflow.
- Checklist items announce checked state.

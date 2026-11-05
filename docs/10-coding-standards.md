# 10 — Coding Standards

## Flutter / Dart
### Naming
- Files: `snake_case.dart`; one public class per file (small private helpers ok).
- Classes `PascalCase`; providers `camelCaseProvider` (e.g. `notesRepositoryProvider`).
- Use-cases are verbs: `CreateNote`, `ArchiveNotes`, `ScheduleReminder`.
- Booleans start with `is/has/should`.

### Structure
- Widgets ≤ ~150 lines; extract sub-widgets as classes (not helper methods returning widgets).
- `const` constructors wherever possible.
- Business logic **never** in widgets — it lives in Riverpod Notifiers / use cases.
- Controllers expose immutable state (`freezed`) — `AsyncValue<T>` for async.
- Repositories return `Future<Result<T>>` / `Stream<T>`; never throw across layers — map exceptions to `Failure` in data layer.
- Inject time (`Clock`) and ID generation (`IdGenerator`) via providers so tests are deterministic.

### Drift
- One DAO per aggregate; all multi-table writes in `transaction()`.
- Watch queries (`.watch()`) for lists; no polling.
- Every schema version has a generated schema snapshot (`drift_dev schema dump`) and a migration test.

### Style
- `very_good_analysis` (or `flutter_lints` + strict-casts/inference/raw-types) — zero warnings.
- `dart format` default line length (80).
- No `print` — use a `Logger` that strips in release and never receives note content.
- No `dynamic` unless JSON boundary; DTOs convert to typed entities immediately.

### Example layering
```dart
// domain/notes_repository.dart
abstract interface class NotesRepository {
  Stream<List<Note>> watchNotes(NoteQuery query);
  Future<Result<Note>> save(Note note);
  Future<Result<void>> moveToTrash(List<NoteId> ids);
}

// presentation/controllers/note_editor_controller.dart
@riverpod
class NoteEditorController extends _$NoteEditorController {
  @override
  FutureOr<NoteEditorState> build(NoteId? id) async { ... }
  void onBodyChanged(String body) { /* update state, debounce save via use case */ }
}
```

## Laravel / PHP
- PSR-12 via **Pint**; **Larastan** level ≥ 6; `declare(strict_types=1);` in all files.
- Controllers: thin — authorise, call a Service/Action, return a Resource.
- Validation only in `FormRequest`; authorisation in Policies.
- DB writes that touch revisions run in `DB::transaction()` with `lockForUpdate()` on the user row.
- Never `Model::all()` / unscoped queries on user data — always via `$request->user()->notes()`.
- No business logic in models beyond casts, relations, scopes.
- Config via `config()` — never `env()` outside config files.
- Jobs are idempotent (safe to retry).
- Feature test per endpoint covering: 200 path, 401, 403/404 (other user's data), 422.

## General
- Comments explain *why*, not *what*.
- No commented-out code; no TODO without an issue link.
- Keep PRs focused: one feature/fix per PR.
- Secrets never in code or git.

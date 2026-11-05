import 'package:drift/drift.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/notes/data/note_mapper.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/domain/notes_repository.dart';

final class NotesRepositoryImpl implements NotesRepository {
  new(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  $NotesTable get _notes => _db.notes;

  int get _nowMs => _clock.now().millisecondsSinceEpoch;

  @override
  Stream<List<Note>> watchNotes(NoteQuery query) {
    final select = _db.select(_notes)
      ..where((n) {
        var e = switch (query.section) {
          NoteSection.notes => n.deletedAt.isNull() & n.isArchived.not(),
          NoteSection.archive => n.deletedAt.isNull() & n.isArchived,
          NoteSection.trash => n.deletedAt.isNotNull(),
        };
        if (query.colors.isNotEmpty) {
          e &= n.color.isIn(query.colors.map((c) => c.value));
        }
        return e;
      })
      ..orderBy([
        if (query.section == NoteSection.notes)
          (n) => OrderingTerm.desc(n.isPinned),
        if (query.section == NoteSection.trash)
          (n) => OrderingTerm.desc(n.deletedAt),
        ...switch (query.sort) {
          NoteSort.modified => [
            ($NotesTable n) => OrderingTerm.desc(n.updatedAt),
          ],
          NoteSort.created => [
            ($NotesTable n) => OrderingTerm.desc(n.createdAt),
          ],
          NoteSort.title => [
            ($NotesTable n) =>
                OrderingTerm.asc(n.title.collate(Collate.noCase)),
            ($NotesTable n) => OrderingTerm.desc(n.updatedAt),
          ],
          NoteSort.color => [
            ($NotesTable n) => OrderingTerm.asc(n.color),
            ($NotesTable n) => OrderingTerm.desc(n.updatedAt),
          ],
        },
      ]);
    return select.watch().map(_toNotes);
  }

  @override
  Stream<List<Note>> watchSearch(
    String text, {
    Set<NoteColor> colors = const {},
  }) {
    final match = ftsMatchExpression(text);
    if (match == null) return Stream.value(const []);
    final colorSql = colors.isEmpty
        ? ''
        : 'AND n.color IN (${colors.map((c) => c.value).join(',')})';
    return _db
        .customSelect(
          'SELECT n.* FROM notes n '
          'WHERE n.deleted_at IS NULL AND n.is_locked = 0 $colorSql '
          'AND n.id IN (SELECT note_id FROM notes_fts WHERE notes_fts MATCH ?) '
          'ORDER BY n.updated_at DESC',
          variables: [Variable.withString(match)],
          readsFrom: {_notes, _db.notesFts},
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows) NoteMapper.fromRow(_notes.map(r.data)),
          ],
        );
  }

  /// Turns user input into a safe FTS5 query: every word must match as a
  /// prefix. Quotes are escaped so input can never inject FTS syntax.
  static String? ftsMatchExpression(String input) {
    final terms = input
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '""')}"*')
        .toList();
    return terms.isEmpty ? null : terms.join(' ');
  }

  @override
  Stream<Note?> watchNote(String id) =>
      (_db.select(_notes)..where((n) => n.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : NoteMapper.fromRow(r));

  @override
  Future<Note?> getNote(String id) async {
    final row = await (_db.select(
      _notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
    return row == null ? null : NoteMapper.fromRow(row);
  }

  @override
  Future<void> save(Note note) => _db.transaction(() async {
    final stamped = note.copyWith(updatedAt: _clock.now());
    await _db
        .into(_notes)
        .insertOnConflictUpdate(NoteMapper.toCompanion(stamped));
    await _reindex(stamped);
  });

  @override
  Future<List<Note>> allNotes() async =>
      _toNotes(await _db.select(_notes).get());

  @override
  Future<ImportResult> importNotes(List<Note> notes) =>
      _db.transaction(() async {
        var added = 0;
        var updated = 0;
        var skipped = 0;
        for (final note in notes) {
          final existing = await getNote(note.id);
          if (existing == null) {
            added++;
          } else if (note.updatedAt.isAfter(existing.updatedAt)) {
            updated++;
          } else {
            skipped++;
            continue;
          }
          await _db
              .into(_notes)
              .insertOnConflictUpdate(NoteMapper.toCompanion(note));
          await _reindex(note);
        }
        return ImportResult(added: added, updated: updated, skipped: skipped);
      });

  Future<void> _reindex(Note note) async {
    await (_db.delete(
      _db.notesFts,
    )..where((f) => f.noteId.equals(note.id))).go();
    if (note.isLocked) return; // never index locked content
    await _db
        .into(_db.notesFts)
        .insert(
          NotesFtsCompanion.insert(
            noteId: note.id,
            title: note.title,
            body: note.plainBody,
          ),
        );
  }

  Future<void> _update(Iterable<String> ids, NotesCompanion change) =>
      (_db.update(_notes)..where((n) => n.id.isIn(ids))).write(
        change.copyWith(updatedAt: Value(_nowMs), dirty: const Value(true)),
      );

  @override
  Future<void> setPinned(Iterable<String> ids, {required bool pinned}) =>
      _update(ids, NotesCompanion(isPinned: Value(pinned)));

  @override
  Future<void> setArchived(Iterable<String> ids, {required bool archived}) =>
      _update(
        ids,
        // Archived notes leave the pinned section.
        NotesCompanion(
          isArchived: Value(archived),
          isPinned: archived ? const Value(false) : const Value.absent(),
        ),
      );

  @override
  Future<void> setColor(Iterable<String> ids, NoteColor color) =>
      _update(ids, NotesCompanion(color: Value(color.value)));

  @override
  Future<void> moveToTrash(Iterable<String> ids) =>
      _update(ids, NotesCompanion(deletedAt: Value(_nowMs)));

  @override
  Future<void> restoreFromTrash(Iterable<String> ids) =>
      _update(ids, const NotesCompanion(deletedAt: Value(null)));

  // Phase 2: notes that were already synced must become server tombstones
  // instead of disappearing locally (docs/03 §3.2).
  @override
  Future<void> deleteForever(Iterable<String> ids) =>
      _deleteWhere((n) => n.id.isIn(ids));

  @override
  Future<void> emptyTrash() => _deleteWhere((n) => n.deletedAt.isNotNull());

  @override
  Future<int> purgeTrash(Duration retention) {
    final cutoff = _nowMs - retention.inMilliseconds;
    return _deleteWhere((n) => n.deletedAt.isSmallerThanValue(cutoff));
  }

  Future<int> _deleteWhere(Expression<bool> Function($NotesTable) filter) =>
      _db.transaction(() async {
        final count = await (_db.delete(_notes)..where(filter)).go();
        await _db.customStatement(
          'DELETE FROM notes_fts WHERE note_id NOT IN (SELECT id FROM notes)',
        );
        return count;
      });

  @override
  Future<String> duplicate(String id) async {
    final original = await getNote(id);
    if (original == null) throw StateError('Note $id not found');
    final now = _clock.now();
    final copy = original.copyWith(
      id: _ids.newId(),
      createdAt: now,
      updatedAt: now,
      isPinned: false,
      deletedAt: null,
    );
    await _db.transaction(() async {
      await _db.into(_notes).insert(NoteMapper.toCompanion(copy));
      await _reindex(copy);
    });
    return copy.id;
  }

  @override
  Future<int> countLocked() {
    final count = _notes.id.count();
    final q = _db.selectOnly(_notes)
      ..addColumns([count])
      ..where(_notes.isLocked);
    return q.getSingle().then((row) => row.read(count) ?? 0);
  }

  List<Note> _toNotes(List<NoteRow> rows) => [
    for (final r in rows) NoteMapper.fromRow(r),
  ];
}

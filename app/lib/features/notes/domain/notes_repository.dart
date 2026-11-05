import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';

/// Local notes store — the UI's source of truth (ADR 0002).
abstract interface class NotesRepository {
  Stream<List<Note>> watchNotes(NoteQuery query);

  /// Full-text search over active + archived notes (not trash, not locked).
  Stream<List<Note>> watchSearch(String text, {Set<NoteColor> colors});

  Stream<Note?> watchNote(String id);

  Future<Note?> getNote(String id);

  /// Inserts or updates. Locked notes must be sealed first.
  Future<void> save(Note note);

  Future<void> setPinned(Iterable<String> ids, {required bool pinned});

  Future<void> setArchived(Iterable<String> ids, {required bool archived});

  Future<void> setColor(Iterable<String> ids, NoteColor color);

  Future<void> moveToTrash(Iterable<String> ids);

  Future<void> restoreFromTrash(Iterable<String> ids);

  Future<void> deleteForever(Iterable<String> ids);

  Future<void> emptyTrash();

  /// Permanently deletes notes trashed more than [retention] ago.
  Future<int> purgeTrash(Duration retention);

  /// Returns the id of the copy.
  Future<String> duplicate(String id);

  Future<int> countLocked();

  /// Every note including trash, locked notes still sealed (for backup).
  Future<List<Note>> allNotes();

  /// Upserts preserving timestamps; an existing note is only replaced when
  /// the incoming copy is newer (restore never overwrites newer edits).
  Future<ImportResult> importNotes(List<Note> notes);
}

final class ImportResult {
  const new({
    required this.added,
    required this.updated,
    required this.skipped,
  });

  final int added;
  final int updated;
  final int skipped;
}

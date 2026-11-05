import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/features/notes/domain/note.dart';

/// Keeps notes_fts in step with notes. Call inside the write transaction.
abstract final class FtsIndex {
  static Future<void> reindex(AppDatabase db, Note note) async {
    await remove(db, note.id);
    if (note.isLocked) return; // never index locked content
    await db
        .into(db.notesFts)
        .insert(
          NotesFtsCompanion.insert(
            noteId: note.id,
            title: note.title,
            body: note.plainBody,
          ),
        );
  }

  static Future<void> remove(AppDatabase db, String noteId) =>
      (db.delete(db.notesFts)..where((f) => f.noteId.equals(noteId))).go();
}

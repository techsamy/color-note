import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

/// Row <-> domain mapping. Storage format: docs/04-data-model.md §2.
abstract final class NoteMapper {
  static DateTime _ms(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static Note fromRow(NoteRow r) {
    final type = NoteType.fromValue(r.type);
    final base = Note(
      id: r.id,
      type: type,
      createdAt: _ms(r.createdAt),
      updatedAt: _ms(r.updatedAt),
      color: NoteColor.fromValue(r.color),
      isPinned: r.isPinned,
      isArchived: r.isArchived,
      isLocked: r.isLocked,
      deletedAt: r.deletedAt == null ? null : _ms(r.deletedAt!),
    );
    if (r.isLocked) {
      final meta = jsonDecode(r.cryptoMeta ?? '{}') as Map<String, dynamic>;
      return base.copyWith(
        encrypted: EncryptedBlob.fromJson({...meta, 'ciphertext': r.body}),
      );
    }
    return switch (type) {
      NoteType.text => base.copyWith(title: r.title, text: r.body),
      NoteType.checklist => base.copyWith(
        title: r.title,
        items: decodeItems(r.body),
      ),
    };
  }

  static NotesCompanion toCompanion(Note n) {
    if (n.isLocked && n.encrypted == null) {
      // Guard: plaintext of a locked note must never reach storage.
      throw StateError('Locked note ${n.id} must be sealed before saving');
    }
    final enc = n.encrypted;
    final String body;
    final String? meta;
    if (n.isLocked && enc != null) {
      body = enc.ciphertext;
      meta = jsonEncode(enc.toJson()..remove('ciphertext'));
    } else {
      body = switch (n.type) {
        NoteType.text => n.text,
        NoteType.checklist => encodeItems(n.items),
      };
      meta = null;
    }
    return NotesCompanion(
      id: Value(n.id),
      type: Value(n.type.value),
      title: Value(n.isLocked ? '' : n.title),
      body: Value(body),
      color: Value(n.color.value),
      isPinned: Value(n.isPinned),
      isArchived: Value(n.isArchived),
      isLocked: Value(n.isLocked),
      cryptoMeta: Value(meta),
      createdAt: Value(n.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(n.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(n.deletedAt?.millisecondsSinceEpoch),
      dirty: const Value(true),
    );
  }

  static String encodeItems(List<ChecklistItem> items) =>
      jsonEncode([for (final i in items) i.toJson()]);

  static List<ChecklistItem> decodeItems(String body) {
    if (body.isEmpty) return const [];
    try {
      return [
        for (final e in jsonDecode(body) as List<dynamic>)
          ChecklistItem.fromJson(e as Map<String, dynamic>),
      ];
    } on FormatException {
      // Corrupt/legacy body: keep the user's text instead of losing it.
      return [
        for (final (i, line) in body.split('\n').indexed)
          if (line.trim().isNotEmpty)
            ChecklistItem(id: 'legacy-$i', text: line),
      ];
    }
  }
}

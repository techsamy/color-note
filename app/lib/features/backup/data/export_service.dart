import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

/// FR-B7 — plain, unencrypted export to read notes anywhere.
/// Locked and trashed notes are left out on purpose.
class ExportService {
  const new();

  Uint8List export(List<Note> notes, {required DateTime now}) {
    final included = notes
        .where((n) => !n.isLocked && !n.isTrashed && !n.isEmpty)
        .toList();
    final archive = Archive();
    final used = <String>{};
    for (final n in included) {
      final name = _fileName(n, used);
      archive.add(ArchiveFile.string('notes/$name', _text(n)));
    }
    archive.add(
      ArchiveFile.string(
        'notes.json',
        const JsonEncoder.withIndent('  ').convert({
          'exported_at': now.toUtc().toIso8601String(),
          'notes': [for (final n in included) _json(n)],
        }),
      ),
    );
    return ZipEncoder().encodeBytes(archive);
  }

  static String _text(Note n) {
    final body = switch (n.type) {
      NoteType.text => n.text,
      NoteType.checklist =>
        n.items.map((i) => '${i.checked ? '[x]' : '[ ]'} ${i.text}').join('\n'),
    };
    return n.title.trim().isEmpty ? '$body\n' : '${n.title}\n\n$body\n';
  }

  static Map<String, dynamic> _json(Note n) => {
    'id': n.id,
    'type': n.type.name,
    'title': n.title,
    if (n.type == NoteType.text) 'text': n.text,
    if (n.type == NoteType.checklist)
      'items': [
        for (final i in n.items) {'text': i.text, 'checked': i.checked},
      ],
    'color': n.color.name,
    'pinned': n.isPinned,
    'archived': n.isArchived,
    'created_at': n.createdAt.toUtc().toIso8601String(),
    'updated_at': n.updatedAt.toUtc().toIso8601String(),
  };

  /// Readable, filesystem-safe and unique.
  static String _fileName(Note n, Set<String> used) {
    final source = n.title.trim().isNotEmpty
        ? n.title
        : n.plainBody.split('\n').first;
    var base = source
        .replaceAll(RegExp(r'[^\p{L}\p{N} _-]', unicode: true), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (base.isEmpty) base = 'note';
    if (base.length > 60) base = base.substring(0, 60).trim();
    var name = '$base.txt';
    for (var i = 2; !used.add(name); i++) {
      name = '$base ($i).txt';
    }
    return name;
  }
}

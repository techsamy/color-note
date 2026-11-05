import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

/// Backup JSON for a note (format_version 1). Keep readers for every
/// version ever shipped.
abstract final class NoteJson {
  static Map<String, dynamic> encode(Note n) => {
    'id': n.id,
    'type': n.type.value,
    'title': n.title,
    'text': n.text,
    'items': [for (final i in n.items) i.toJson()],
    'color': n.color.value,
    'isPinned': n.isPinned,
    'isArchived': n.isArchived,
    'isLocked': n.isLocked,
    'encrypted': n.encrypted?.toJson(),
    'createdAt': n.createdAt.millisecondsSinceEpoch,
    'updatedAt': n.updatedAt.millisecondsSinceEpoch,
    'deletedAt': n.deletedAt?.millisecondsSinceEpoch,
  };

  static Note decode(Map<String, dynamic> j) {
    DateTime ms(Object? v) =>
        DateTime.fromMillisecondsSinceEpoch(v! as int, isUtc: true);
    final enc = j['encrypted'] as Map<String, dynamic>?;
    return Note(
      id: j['id'] as String,
      type: NoteType.fromValue(j['type'] as int),
      title: j['title'] as String? ?? '',
      text: j['text'] as String? ?? '',
      items: [
        for (final e in (j['items'] as List<dynamic>? ?? const []))
          ChecklistItem.fromJson(e as Map<String, dynamic>),
      ],
      color: NoteColor.fromValue(j['color'] as int),
      isPinned: j['isPinned'] as bool? ?? false,
      isArchived: j['isArchived'] as bool? ?? false,
      isLocked: j['isLocked'] as bool? ?? false,
      encrypted: enc == null ? null : EncryptedBlob.fromJson(enc),
      createdAt: ms(j['createdAt']),
      updatedAt: ms(j['updatedAt']),
      deletedAt: j['deletedAt'] == null ? null : ms(j['deletedAt']),
    );
  }
}

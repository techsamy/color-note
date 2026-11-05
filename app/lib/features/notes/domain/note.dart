import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

part 'note.freezed.dart';

/// A note as the app sees it.
///
/// Locked notes come out of storage *sealed*: [encrypted] is set and
/// [title]/[text]/[items] are empty. The lock feature unseals them for
/// editing and seals them again before saving (ADR 0005).
@freezed
abstract class Note with _$Note {
  const factory({
    required String id,
    required NoteType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('') String title,
    @Default('') String text,
    @Default(<ChecklistItem>[]) List<ChecklistItem> items,
    @Default(NoteColor.yellow) NoteColor color,
    @Default(false) bool isPinned,
    @Default(false) bool isArchived,
    @Default(false) bool isLocked,
    EncryptedBlob? encrypted,
    DateTime? deletedAt,
  }) = _Note;

  const new _();

  bool get isTrashed => deletedAt != null;

  /// Sealed = locked and content not decrypted in memory.
  bool get isSealed => isLocked && encrypted != null;

  /// Nothing worth keeping (new empty notes are discarded, like ColorNote).
  bool get isEmpty =>
      !isSealed &&
      title.trim().isEmpty &&
      switch (type) {
        NoteType.text => text.trim().isEmpty,
        NoteType.checklist => items.every((i) => i.text.trim().isEmpty),
      };

  /// Plain text used for previews, sharing and the search index.
  String get plainBody => switch (type) {
    NoteType.text => text,
    NoteType.checklist => items.map((i) => i.text).join('\n'),
  };
}

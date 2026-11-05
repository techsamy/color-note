import 'package:huenote/features/notes/domain/note_color.dart';

/// User-renamed colour labels (FR-L5). Missing entry = default name.
abstract interface class ColorLabelsRepository {
  Stream<Map<NoteColor, String>> watchLabels();

  Future<Map<NoteColor, String>> getLabels();

  /// Empty/blank [label] resets to the default name.
  Future<void> setLabel(NoteColor color, String label);
}

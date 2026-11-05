import 'package:drift/drift.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/features/notes/domain/color_labels_repository.dart';
import 'package:huenote/features/notes/domain/note_color.dart';

final class ColorLabelsRepositoryImpl implements ColorLabelsRepository {
  new(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<Map<NoteColor, String>> watchLabels() =>
      _db.select(_db.colorLabels).watch().map(_toMap);

  @override
  Future<Map<NoteColor, String>> getLabels() async =>
      _toMap(await _db.select(_db.colorLabels).get());

  // Blank label is stored (not deleted) so a "reset" can sync later.
  @override
  Future<void> setLabel(NoteColor color, String label) => _db
      .into(_db.colorLabels)
      .insertOnConflictUpdate(
        ColorLabelsCompanion.insert(
          color: Value(color.value),
          label: label.trim(),
          updatedAt: _clock.now().millisecondsSinceEpoch,
        ),
      );

  Map<NoteColor, String> _toMap(List<ColorLabelRow> rows) => {
    for (final r in rows)
      if (r.label.isNotEmpty) NoteColor.fromValue(r.color): r.label,
  };
}

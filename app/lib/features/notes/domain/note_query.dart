import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:huenote/features/notes/domain/note_color.dart';

part 'note_query.freezed.dart';

enum NoteSection { notes, archive, trash }

/// Persisted by name in settings.
enum NoteSort { modified, created, title, color }

enum NoteViewMode { list, grid }

@freezed
abstract class NoteQuery with _$NoteQuery {
  const factory({
    @Default(NoteSection.notes) NoteSection section,
    @Default(<NoteColor>{}) Set<NoteColor> colors,
    @Default(NoteSort.modified) NoteSort sort,
  }) = _NoteQuery;
}

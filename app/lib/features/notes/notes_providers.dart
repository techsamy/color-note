import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/notes/data/color_labels_repository_impl.dart';
import 'package:huenote/features/notes/data/notes_repository_impl.dart';
import 'package:huenote/features/notes/domain/color_labels_repository.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/domain/notes_repository.dart';

/// Composition root of the notes feature (wires data -> domain).
final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final colorLabelsRepositoryProvider = Provider<ColorLabelsRepository>(
  (ref) => ColorLabelsRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final notesProvider = StreamProvider.autoDispose.family<List<Note>, NoteQuery>(
  (ref, query) => ref.watch(notesRepositoryProvider).watchNotes(query),
);

final noteProvider = StreamProvider.autoDispose.family<Note?, String>(
  (ref, id) => ref.watch(notesRepositoryProvider).watchNote(id),
);

final colorLabelsProvider = StreamProvider<Map<NoteColor, String>>(
  (ref) => ref.watch(colorLabelsRepositoryProvider).watchLabels(),
);

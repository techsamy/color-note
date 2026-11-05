import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/features/notes/domain/note_query.dart';

/// Multi-select state per list section (FR-L6).
class SelectionController extends Notifier<Set<String>> {
  new(this.section);

  final NoteSection section;

  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void selectAll(Iterable<String> ids) => state = ids.toSet();

  void clear() => state = const {};
}

final selectionProvider = NotifierProvider.autoDispose
    .family<SelectionController, Set<String>, NoteSection>(
      SelectionController.new,
    );

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/checklist_ops.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/notes/domain/notes_repository.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/settings/settings_providers.dart';

/// Identifies an editor session. For a new note the screen generates the id
/// up front so the provider key stays stable.
typedef EditorArgs = ({String id, bool isNew, NoteType type});

final class NoteNotFoundException implements Exception {
  const new();
}

@immutable
final class EditorState {
  const new({required this.note, this.needsUnlock = false});

  final Note note;

  /// Locked note whose content isn't decrypted yet (session locked).
  final bool needsUnlock;

  bool get readOnly => needsUnlock || note.isTrashed;
}

/// Owns one note while it's open. Auto-saves 500 ms after the last change
/// and on close (FR-N1). Locked notes are re-sealed before every save.
class NoteEditorController extends AsyncNotifier<EditorState> {
  new(this.args);

  final EditorArgs args;

  static const debounce = Duration(milliseconds: 500);

  // Captured in build() so saving still works while the provider disposes.
  late NotesRepository _repo;
  late LockController _lock;
  late Clock _clock;
  late IdGenerator _ids;

  Timer? _timer;
  var _dirty = false;
  var _persisted = false;
  Future<void> _saving = Future.value();

  @override
  Future<EditorState> build() async {
    _repo = ref.read(notesRepositoryProvider);
    _lock = ref.read(lockControllerProvider.notifier);
    _clock = ref.read(clockProvider);
    _ids = ref.read(idGeneratorProvider);
    ref.onDispose(() {
      _timer?.cancel();
      if (_dirty) unawaited(_persist());
    });

    if (args.isNew) {
      final now = _clock.now();
      var note = Note(
        id: args.id,
        type: args.type,
        createdAt: now,
        updatedAt: now,
        color: ref.read(settingsProvider).defaultColor,
      );
      if (args.type == NoteType.checklist) {
        note = note.copyWith(items: [ChecklistItem(id: _ids.newId())]);
      }
      return EditorState(note: note);
    }

    final stored = await _repo.getNote(args.id);
    if (stored == null) throw const NoteNotFoundException();
    _persisted = true;
    if (!stored.isSealed) return EditorState(note: stored);
    final lockState = await ref.read(lockControllerProvider.future);
    if (!lockState.isUnlocked) {
      return EditorState(note: stored, needsUnlock: true);
    }
    return EditorState(note: await _lock.unseal(stored));
  }

  EditorState? get _state => state.value;

  /// Call after the user unlocked the session.
  Future<void> openLocked() async {
    final s = _state;
    if (s == null || !s.needsUnlock) return;
    state = AsyncData(EditorState(note: await _lock.unseal(s.note)));
  }

  void _edit(Note Function(Note) change, {bool immediate = false}) {
    final s = _state;
    if (s == null || s.readOnly) return;
    state = AsyncData(EditorState(note: change(s.note)));
    _dirty = true;
    _timer?.cancel();
    if (immediate) {
      unawaited(flush());
    } else {
      _timer = Timer(debounce, () => unawaited(flush()));
    }
  }

  void setTitle(String v) => _edit((n) => n.copyWith(title: v));

  void setText(String v) => _edit((n) => n.copyWith(text: v));

  void setColor(NoteColor c) =>
      _edit((n) => n.copyWith(color: c), immediate: true);

  void togglePinned() =>
      _edit((n) => n.copyWith(isPinned: !n.isPinned), immediate: true);

  void convertTo(NoteType type) =>
      _edit((n) => n.convertTo(type, _ids.newId), immediate: true);

  // ---- checklist (FR-N2) ----

  void setItemText(String itemId, String text) =>
      _edit((n) => n.updateItem(itemId, (i) => i.copyWith(text: text)));

  void toggleItem(String itemId) => _edit((n) {
    final toggled = n.toggleItem(itemId);
    return ref.read(settingsProvider).checkedToBottom
        ? toggled.copyWith(items: checkedToBottom(toggled.items))
        : toggled;
  }, immediate: true);

  /// Returns the new item's id (so the UI can focus it).
  String addItem({String? afterId}) {
    final id = _ids.newId();
    _edit((n) => n.insertItemAfter(afterId, ChecklistItem(id: id)));
    return id;
  }

  void removeItem(String itemId) =>
      _edit((n) => n.removeItem(itemId), immediate: true);

  void reorderItem(int oldIndex, int newIndex) =>
      _edit((n) => n.reorderItem(oldIndex, newIndex), immediate: true);

  void uncheckAll() => _edit((n) => n.uncheckAll(), immediate: true);

  void removeChecked() => _edit((n) => n.removeChecked(), immediate: true);

  // ---- lock (FR-S1) ----

  /// Session must be unlocked (UI ensures it).
  void lockNote() => _edit((n) => n.copyWith(isLocked: true), immediate: true);

  void removeLock() => _edit(
    (n) => n.copyWith(isLocked: false, encrypted: null),
    immediate: true,
  );

  // ---- persistence ----

  /// Saves pending changes now.
  Future<void> flush() {
    _timer?.cancel();
    if (!_dirty) return _saving;
    _dirty = false;
    return _saving = _saving.then((_) => _persist());
  }

  Future<void> _persist() async {
    final s = _state;
    if (s == null || s.needsUnlock) return;
    final note = s.note;
    // A brand-new note isn't stored until it has content.
    if (note.isEmpty && !_persisted) return;
    final toSave = note.isLocked ? await _lock.seal(note) : note;
    await _repo.save(toSave);
    _persisted = true;
  }

  /// Leaving the editor: save, and drop a note created here but left empty.
  Future<void> close() async {
    await flush();
    final s = _state;
    if (s != null && args.isNew && _persisted && s.note.isEmpty) {
      await _repo.deleteForever([s.note.id]);
    }
  }

  Future<String> duplicate() async {
    await flush();
    if (!_persisted) await _forceSave();
    return await _repo.duplicate(args.id);
  }

  /// Saves even an empty note (needed before actions on the stored row).
  Future<void> _forceSave() async {
    final s = _state;
    if (s == null) return;
    final toSave = s.note.isLocked ? await _lock.seal(s.note) : s.note;
    await _repo.save(toSave);
    _persisted = true;
  }

  Future<void> archive({required bool archived}) async {
    await flush();
    if (!_persisted) await _forceSave();
    await _repo.setArchived([args.id], archived: archived);
  }

  /// Returns false when there was nothing stored to trash.
  Future<bool> trash() async {
    await flush();
    if (!_persisted) return false;
    await _repo.moveToTrash([args.id]);
    return true;
  }

  Future<void> restore() async {
    await _repo.restoreFromTrash([args.id]);
    final s = _state;
    if (s != null) {
      state = AsyncData(EditorState(note: s.note.copyWith(deletedAt: null)));
    }
  }
}

final noteEditorProvider = AsyncNotifierProvider.autoDispose
    .family<NoteEditorController, EditorState, EditorArgs>(
      NoteEditorController.new,
    );

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/widgets/dialogs.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/notes_repository.dart'
    show NotesRepository;
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

/// Bulk/single note actions with undo (FR-N5..N7, L6). UI glue only —
/// the work happens in [NotesRepository].
class NoteBulkActions {
  new(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Future<void> trash(List<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.moveToTrash(ids);
    if (!context.mounted) return;
    showSnack(
      context,
      _l10n.movedToTrash(ids.length),
      onUndo: () => repo.restoreFromTrash(ids),
    );
  }

  Future<void> archive(List<String> ids, {required bool archived}) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.setArchived(ids, archived: archived);
    if (!context.mounted) return;
    showSnack(
      context,
      archived ? _l10n.archived(ids.length) : _l10n.unarchived(ids.length),
      onUndo: () => repo.setArchived(ids, archived: !archived),
    );
  }

  Future<void> restore(List<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.restoreFromTrash(ids);
    if (!context.mounted) return;
    showSnack(
      context,
      _l10n.restored(ids.length),
      onUndo: () => repo.moveToTrash(ids),
    );
  }

  Future<bool> deleteForever(List<String> ids) async {
    final ok = await confirm(
      context,
      title: _l10n.deleteForeverConfirm(ids.length),
      message: _l10n.cannotUndo,
      confirmLabel: _l10n.actionDeleteForever,
    );
    if (ok) await ref.read(notesRepositoryProvider).deleteForever(ids);
    return ok;
  }

  Future<void> emptyTrash() async {
    final ok = await confirm(
      context,
      title: _l10n.emptyTrashConfirm,
      message: _l10n.cannotUndo,
      confirmLabel: _l10n.actionEmptyTrash,
    );
    if (ok) await ref.read(notesRepositoryProvider).emptyTrash();
  }

  Future<void> setPinned(List<String> ids, {required bool pinned}) =>
      ref.read(notesRepositoryProvider).setPinned(ids, pinned: pinned);

  Future<void> setColor(List<String> ids, NoteColor color) =>
      ref.read(notesRepositoryProvider).setColor(ids, color);
}

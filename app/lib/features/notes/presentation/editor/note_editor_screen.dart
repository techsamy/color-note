import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/core/widgets/dialogs.dart';
import 'package:huenote/core/widgets/empty_state.dart';
import 'package:huenote/features/lock/presentation/unlock_dialog.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/notes/presentation/color_picker_sheet.dart';
import 'package:huenote/features/notes/presentation/editor/checklist_editor.dart';
import 'package:huenote/features/notes/presentation/editor/note_editor_controller.dart';
import 'package:huenote/features/notes/presentation/note_text_style.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

enum _MenuAction {
  convert,
  duplicate,
  archive,
  lock,
  removeLock,
  uncheckAll,
  deleteChecked,
  delete,
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const new existing({required String this.noteId, super.key}) : newType = null;

  const new create({required NoteType this.newType, super.key}) : noteId = null;

  final String? noteId;
  final NoteType? newType;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final EditorArgs _args;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    final id = widget.noteId;
    _args = id != null
        ? (id: id, isNew: false, type: NoteType.text)
        : (
            id: ref.read(idGeneratorProvider).newId(),
            isNew: true,
            type: widget.newType!,
          );
  }

  NoteEditorController get _ctrl =>
      ref.read(noteEditorProvider(_args).notifier);

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _ctrl.close();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(noteEditorProvider(_args));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: async.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: EmptyState(
            icon: Icons.error_outline,
            title: l10n.noteNotFound,
            message: '',
          ),
        ),
        data: (state) =>
            _Editor(state: state, ctrl: _ctrl, args: _args, onClose: _close),
      ),
    );
  }
}

class _Editor extends ConsumerWidget {
  const new({
    required this.state,
    required this.ctrl,
    required this.args,
    required this.onClose,
  });

  final EditorState state;
  final NoteEditorController ctrl;
  final EditorArgs args;
  final Future<void> Function() onClose;

  Note get note => state.note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final swatch = NotePalette.of(context)[note.color];
    final fg = swatch.foreground;
    final bodyStyle = noteBodyStyle(context, settings.fontSize, fg);
    final titleStyle = noteTitleStyle(context, settings.fontSize, fg);

    return Theme(
      // Cursor/selection colours readable on every note colour.
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: fg,
          selectionColor: fg.withValues(alpha: 0.25),
          selectionHandleColor: fg,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? fg : Colors.transparent,
          ),
          checkColor: WidgetStatePropertyAll(swatch.background),
        ),
      ),
      child: Scaffold(
        backgroundColor: swatch.background,
        appBar: AppBar(
          backgroundColor: swatch.background,
          foregroundColor: fg,
          leading: BackButton(onPressed: onClose),
          actions: _actions(context, ref, l10n),
        ),
        body: state.needsUnlock
            ? _LockedBody(
                color: fg,
                onUnlock: () async {
                  if (await ensureUnlocked(context, ref)) {
                    await ctrl.openLocked();
                  }
                },
              )
            : CustomScrollView(
                slivers: [
                  if (note.isTrashed)
                    SliverToBoxAdapter(
                      child: _TrashBanner(onRestore: ctrl.restore),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _Field(
                        key: ValueKey('title-${note.id}'),
                        initial: note.title,
                        hint: l10n.titleHint,
                        style: titleStyle,
                        readOnly: state.readOnly,
                        autofocus: args.isNew && note.type == NoteType.text,
                        onChanged: ctrl.setTitle,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sm),
                  ),
                  if (note.type == NoteType.text)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: _Field(
                          key: ValueKey('body-${note.id}-${note.type}'),
                          initial: note.text,
                          hint: l10n.noteHint,
                          style: bodyStyle,
                          readOnly: state.readOnly,
                          multiline: true,
                          onChanged: ctrl.setText,
                        ),
                      ),
                    )
                  else
                    ChecklistEditor(
                      key: ValueKey('list-${note.id}'),
                      items: note.items,
                      readOnly: state.readOnly,
                      textStyle: bodyStyle,
                      foreground: fg,
                      checkedToBottom: settings.checkedToBottom,
                      onChanged: ctrl.setItemText,
                      onToggle: ctrl.toggleItem,
                      onAdd: ctrl.addItem,
                      onRemove: ctrl.removeItem,
                      onReorder: ctrl.reorderItem,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    if (note.isTrashed) {
      return [
        IconButton(
          tooltip: l10n.actionDeleteForever,
          icon: const Icon(Icons.delete_forever),
          onPressed: () async {
            final ok = await confirm(
              context,
              title: l10n.deleteForeverConfirm(1),
              message: l10n.cannotUndo,
              confirmLabel: l10n.actionDeleteForever,
            );
            if (!ok) return;
            await ref.read(notesRepositoryProvider).deleteForever([note.id]);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ];
    }
    if (state.needsUnlock) return const [];
    return [
      IconButton(
        tooltip: note.isPinned ? l10n.actionUnpin : l10n.actionPin,
        icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
        onPressed: ctrl.togglePinned,
      ),
      IconButton(
        tooltip: l10n.actionColor,
        icon: const Icon(Icons.palette_outlined),
        onPressed: () async {
          final c = await pickNoteColor(context, selected: note.color);
          if (c != null) ctrl.setColor(c);
        },
      ),
      PopupMenuButton<_MenuAction>(
        onSelected: (a) => _onMenu(context, ref, l10n, a),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _MenuAction.convert,
            child: Text(
              note.type == NoteType.text
                  ? l10n.actionConvertToChecklist
                  : l10n.actionConvertToText,
            ),
          ),
          if (note.type == NoteType.checklist) ...[
            PopupMenuItem(
              value: _MenuAction.uncheckAll,
              child: Text(l10n.actionUncheckAll),
            ),
            PopupMenuItem(
              value: _MenuAction.deleteChecked,
              child: Text(l10n.actionDeleteChecked),
            ),
          ],
          PopupMenuItem(
            value: note.isLocked ? _MenuAction.removeLock : _MenuAction.lock,
            child: Text(
              note.isLocked ? l10n.actionRemoveLock : l10n.actionLock,
            ),
          ),
          PopupMenuItem(
            value: _MenuAction.duplicate,
            child: Text(l10n.actionDuplicate),
          ),
          PopupMenuItem(
            value: _MenuAction.archive,
            child: Text(
              note.isArchived ? l10n.actionUnarchive : l10n.actionArchive,
            ),
          ),
          PopupMenuItem(
            value: _MenuAction.delete,
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    ];
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    _MenuAction action,
  ) async {
    final repo = ref.read(notesRepositoryProvider);
    switch (action) {
      case _MenuAction.convert:
        ctrl.convertTo(
          note.type == NoteType.text ? NoteType.checklist : NoteType.text,
        );
      case _MenuAction.uncheckAll:
        ctrl.uncheckAll();
      case _MenuAction.deleteChecked:
        ctrl.removeChecked();
      case _MenuAction.lock:
        if (await ensureUnlocked(context, ref)) ctrl.lockNote();
      case _MenuAction.removeLock:
        ctrl.removeLock();
      case _MenuAction.duplicate:
        final copyId = await ctrl.duplicate();
        if (!context.mounted) return;
        showSnack(context, l10n.noteDuplicated);
        context.pushReplacement(Routes.note(copyId));
      case _MenuAction.archive:
        final archived = !note.isArchived;
        await ctrl.archive(archived: archived);
        if (!context.mounted) return;
        showSnack(
          context,
          archived ? l10n.archived(1) : l10n.unarchived(1),
          onUndo: () => repo.setArchived([note.id], archived: !archived),
        );
        Navigator.of(context).pop();
      case _MenuAction.delete:
        final trashed = await ctrl.trash();
        if (!context.mounted) return;
        if (trashed) {
          showSnack(
            context,
            l10n.movedToTrash(1),
            onUndo: () => repo.restoreFromTrash([note.id]),
          );
        }
        Navigator.of(context).pop();
    }
  }
}

/// Text field that owns its controller; [initial] is only read once so
/// typing never fights state updates.
class _Field extends StatefulWidget {
  const new({
    required this.initial,
    required this.hint,
    required this.style,
    required this.readOnly,
    required this.onChanged,
    this.multiline = false,
    this.autofocus = false,
    super.key,
  });

  final String initial;
  final String hint;
  final TextStyle style;
  final bool readOnly;
  final bool multiline;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    readOnly: widget.readOnly,
    autofocus: widget.autofocus,
    style: widget.style,
    maxLines: widget.multiline ? null : 3,
    minLines: widget.multiline ? 8 : 1,
    keyboardType: widget.multiline
        ? TextInputType.multiline
        : TextInputType.text,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration.collapsed(
      hintText: widget.hint,
      hintStyle: widget.style.copyWith(
        color: widget.style.color?.withValues(alpha: 0.45),
      ),
    ),
    onChanged: widget.onChanged,
  );
}

class _LockedBody extends StatelessWidget {
  const new({required this.color, required this.onUnlock});

  final Color color;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 56, color: color),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.lockedNote,
              style: Theme.of(context).textTheme.titleLarge!
                  .copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.lockedNoteBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.actionUnlock),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashBanner extends StatelessWidget {
  const new({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MaterialBanner(
      content: Text(l10n.noteInTrash),
      leading: const Icon(Icons.delete_outline),
      actions: [
        TextButton(onPressed: onRestore, child: Text(l10n.actionRestore)),
      ],
    );
  }
}

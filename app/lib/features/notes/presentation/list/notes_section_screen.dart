import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/core/widgets/app_drawer.dart';
import 'package:huenote/core/widgets/empty_state.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/notes/presentation/color_picker_sheet.dart';
import 'package:huenote/features/notes/presentation/list/color_filter_bar.dart';
import 'package:huenote/features/notes/presentation/list/note_bulk_actions.dart';
import 'package:huenote/features/notes/presentation/list/notes_sliver.dart';
import 'package:huenote/features/notes/presentation/list/selection_controller.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

/// Notes / Archive / Trash list (one screen, three sections).
class NotesSectionScreen extends ConsumerStatefulWidget {
  const new({required this.section, super.key});

  final NoteSection section;

  @override
  ConsumerState<NotesSectionScreen> createState() => _NotesSectionScreenState();
}

class _NotesSectionScreenState extends ConsumerState<NotesSectionScreen> {
  var _colors = <NoteColor>{};

  NoteSection get _section => widget.section;

  String get _route => switch (_section) {
    NoteSection.notes => Routes.home,
    NoteSection.archive => Routes.archive,
    NoteSection.trash => Routes.trash,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final query = NoteQuery(
      section: _section,
      colors: _colors,
      sort: settings.sort,
    );
    final notesAsync = ref.watch(notesProvider(query));
    final selection = ref.watch(selectionProvider(_section));
    final selecting = selection.isNotEmpty;
    final notes = notesAsync.value ?? const <Note>[];

    void open(Note n) {
      if (selecting) {
        ref.read(selectionProvider(_section).notifier).toggle(n.id);
      } else {
        unawaited(context.push(Routes.note(n.id)));
      }
    }

    void select(Note n) =>
        ref.read(selectionProvider(_section).notifier).toggle(n.id);

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(selectionProvider(_section).notifier).clear();
      },
      child: Scaffold(
        drawer: selecting ? null : AppDrawer(current: _route),
        appBar: selecting
            ? _SelectionBar(
                section: _section,
                notes: notes,
                selection: selection,
              )
            : _MainBar(section: _section, settings: settings, notes: notes),
        floatingActionButton: _section == NoteSection.notes && !selecting
            ? FloatingActionButton(
                tooltip: l10n.newNote,
                onPressed: () => _newNote(context),
                child: const Icon(Icons.add),
              )
            : null,
        body: CustomScrollView(
          slivers: [
            if (_section != NoteSection.trash)
              SliverToBoxAdapter(
                child: ColorFilterBar(
                  selected: _colors,
                  onChanged: (c) => setState(() => _colors = c),
                ),
              ),
            if (notesAsync.isLoading && notesAsync.value == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _empty(l10n, settings),
              )
            else
              ..._content(l10n, notes, settings, selection, open, select),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    AppLocalizations l10n,
    List<Note> notes,
    AppSettings settings,
    Set<String> selection,
    ValueChanged<Note> onTap,
    ValueChanged<Note> onLongPress,
  ) {
    NotesSliver sliver(List<Note> list) => NotesSliver(
      notes: list,
      viewMode: settings.viewMode,
      fontSize: settings.fontSize,
      selected: selection,
      onTap: onTap,
      onLongPress: onLongPress,
    );
    final pinned = _section == NoteSection.notes
        ? notes.where((n) => n.isPinned).toList()
        : const <Note>[];
    if (pinned.isEmpty) return [sliver(notes)];
    final others = notes.where((n) => !n.isPinned).toList();
    return [
      SectionHeader(l10n.pinnedHeader),
      sliver(pinned),
      if (others.isNotEmpty) ...[
        SectionHeader(l10n.othersHeader),
        sliver(others),
      ],
    ];
  }

  Widget _empty(AppLocalizations l10n, AppSettings settings) {
    if (_colors.isNotEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: l10n.emptyFilterTitle,
        message: '',
      );
    }
    return switch (_section) {
      NoteSection.notes => EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: l10n.emptyNotesTitle,
        message: l10n.emptyNotesBody,
      ),
      NoteSection.archive => EmptyState(
        icon: Icons.archive_outlined,
        title: l10n.emptyArchiveTitle,
        message: l10n.emptyArchiveBody,
      ),
      NoteSection.trash => EmptyState(
        icon: Icons.delete_outline,
        title: l10n.emptyTrashTitle,
        message: settings.trashRetentionDays == 0
            ? l10n.emptyTrashBodyForever
            : l10n.emptyTrashBody(settings.trashRetentionDays),
      ),
    };
  }

  Future<void> _newNote(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final type = await showModalBottomSheet<NoteType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notes),
              title: Text(l10n.newTextNote),
              onTap: () => Navigator.pop(context, NoteType.text),
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(l10n.newChecklist),
              onTap: () => Navigator.pop(context, NoteType.checklist),
            ),
          ],
        ),
      ),
    );
    if (type != null && context.mounted) {
      await context.push(Routes.newNote(type));
    }
  }
}

class _MainBar extends ConsumerWidget implements PreferredSizeWidget {
  const new({
    required this.section,
    required this.settings,
    required this.notes,
  });

  final NoteSection section;
  final AppSettings settings;
  final List<Note> notes;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final isGrid = settings.viewMode == NoteViewMode.grid;
    return AppBar(
      title: Text(switch (section) {
        NoteSection.notes => l10n.notesTitle,
        NoteSection.archive => l10n.archiveTitle,
        NoteSection.trash => l10n.trashTitle,
      }),
      actions: [
        if (section != NoteSection.trash)
          IconButton(
            tooltip: l10n.searchTitle,
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.search),
          ),
        if (section == NoteSection.trash && notes.isNotEmpty)
          TextButton(
            onPressed: () => NoteBulkActions(context, ref).emptyTrash(),
            child: Text(l10n.actionEmptyTrash),
          ),
        IconButton(
          tooltip: isGrid ? l10n.actionListView : l10n.actionGridView,
          icon: Icon(isGrid ? Icons.view_agenda_outlined : Icons.grid_view),
          onPressed: () => settingsCtrl.update(
            (s) => s.copyWith(
              viewMode: isGrid ? NoteViewMode.list : NoteViewMode.grid,
            ),
          ),
        ),
        if (section != NoteSection.trash)
          PopupMenuButton<NoteSort>(
            tooltip: l10n.actionSort,
            icon: const Icon(Icons.sort),
            initialValue: settings.sort,
            onSelected: (s) => settingsCtrl.update((x) => x.copyWith(sort: s)),
            itemBuilder: (context) => [
              for (final s in NoteSort.values)
                CheckedPopupMenuItem(
                  value: s,
                  checked: s == settings.sort,
                  child: Text(switch (s) {
                    NoteSort.modified => l10n.sortModified,
                    NoteSort.created => l10n.sortCreated,
                    NoteSort.title => l10n.sortTitle,
                    NoteSort.color => l10n.sortColor,
                  }),
                ),
            ],
          ),
      ],
    );
  }
}

class _SelectionBar extends ConsumerWidget implements PreferredSizeWidget {
  const new({
    required this.section,
    required this.notes,
    required this.selection,
  });

  final NoteSection section;
  final List<Note> notes;
  final Set<String> selection;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctrl = ref.read(selectionProvider(section).notifier);
    final actions = NoteBulkActions(context, ref);
    final ids = selection.toList();
    final chosen = notes.where((n) => selection.contains(n.id));
    final allPinned = chosen.isNotEmpty && chosen.every((n) => n.isPinned);

    Future<void> run(Future<void> Function() action) async {
      ctrl.clear();
      await action();
    }

    return AppBar(
      leading: IconButton(
        tooltip: l10n.actionClose,
        icon: const Icon(Icons.close),
        onPressed: ctrl.clear,
      ),
      title: Text(l10n.selectedCount(selection.length)),
      actions: [
        IconButton(
          tooltip: l10n.actionSelectAll,
          icon: const Icon(Icons.select_all),
          onPressed: () => ctrl.selectAll(notes.map((n) => n.id)),
        ),
        if (section == NoteSection.trash) ...[
          IconButton(
            tooltip: l10n.actionRestore,
            icon: const Icon(Icons.restore_from_trash),
            onPressed: () => run(() => actions.restore(ids)),
          ),
          IconButton(
            tooltip: l10n.actionDeleteForever,
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              if (await actions.deleteForever(ids)) ctrl.clear();
            },
          ),
        ] else ...[
          if (section == NoteSection.notes)
            IconButton(
              tooltip: allPinned ? l10n.actionUnpin : l10n.actionPin,
              icon: Icon(allPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () =>
                  run(() => actions.setPinned(ids, pinned: !allPinned)),
            ),
          IconButton(
            tooltip: l10n.actionColor,
            icon: const Icon(Icons.palette_outlined),
            onPressed: () async {
              final color = await pickNoteColor(context);
              if (color != null) await run(() => actions.setColor(ids, color));
            },
          ),
          IconButton(
            tooltip: section == NoteSection.archive
                ? l10n.actionUnarchive
                : l10n.actionArchive,
            icon: Icon(
              section == NoteSection.archive
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            onPressed: () => run(
              () => actions.archive(
                ids,
                archived: section != NoteSection.archive,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => run(() => actions.trash(ids)),
          ),
        ],
      ],
    );
  }
}

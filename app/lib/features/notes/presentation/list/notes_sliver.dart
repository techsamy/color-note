import 'package:flutter/material.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/presentation/list/note_card.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';

/// Notes as a list or grid sliver (FR-L1).
class NotesSliver extends StatelessWidget {
  const new({
    required this.notes,
    required this.viewMode,
    required this.fontSize,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final List<Note> notes;
  final NoteViewMode viewMode;
  final NoteFontSize fontSize;
  final Set<String> selected;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;

  Widget _card(Note n) => NoteCard(
    key: ValueKey(n.id),
    note: n,
    fontSize: fontSize,
    compact: viewMode == NoteViewMode.list,
    selected: selected.contains(n.id),
    onTap: () => onTap(n),
    onLongPress: () => onLongPress(n),
  );

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    );
    if (viewMode == NoteViewMode.grid) {
      return SliverPadding(
        padding: padding,
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, i) => _card(notes[i]),
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _card(notes[i]),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge!
            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

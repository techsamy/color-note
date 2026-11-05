import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:huenote/l10n/note_color_l10n.dart';

/// Colour filter chips (FR-L3). Label text is always shown, so colour is
/// never the only signal (accessibility).
class ColorFilterBar extends ConsumerWidget {
  const new({required this.selected, required this.onChanged, super.key});

  final Set<NoteColor> selected;
  final ValueChanged<Set<NoteColor>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = NotePalette.of(context);
    final labels = ref.watch(colorLabelsProvider).value ?? const {};
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final c in NoteColor.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                avatar: CircleAvatar(backgroundColor: palette[c].background),
                label: Text(c.label(l10n, labels)),
                selected: selected.contains(c),
                showCheckmark: false,
                onSelected: (on) => onChanged(
                  on ? {...selected, c} : ({...selected}..remove(c)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

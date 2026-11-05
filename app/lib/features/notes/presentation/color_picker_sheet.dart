import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:huenote/l10n/note_color_l10n.dart';

/// Bottom sheet with the 9 colours + their labels. Returns the choice.
Future<NoteColor?> pickNoteColor(BuildContext context, {NoteColor? selected}) {
  return showModalBottomSheet<NoteColor>(
    context: context,
    showDragHandle: true,
    builder: (context) => _ColorPicker(selected: selected),
  );
}

class _ColorPicker extends ConsumerWidget {
  const new({this.selected});

  final NoteColor? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = NotePalette.of(context);
    final labels = ref.watch(colorLabelsProvider).value ?? const {};
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chooseColor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final c in NoteColor.values)
                  ColorSwatchButton(
                    swatch: palette[c],
                    label: c.label(l10n, labels),
                    selected: c == selected,
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ColorSwatchButton extends StatelessWidget {
  const new({
    required this.swatch,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final NoteSwatch swatch;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: swatch.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, color: swatch.foreground)
                    : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

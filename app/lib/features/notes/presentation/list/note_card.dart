import 'package:flutter/material.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  const new({
    required this.note,
    required this.fontSize,
    required this.compact,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final Note note;
  final NoteFontSize fontSize;

  /// List view = compact (fewer preview lines than grid).
  final bool compact;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final swatch = NotePalette.of(context)[note.color];
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = swatch.foreground;
    final bodyStyle = text.bodyMedium!.copyWith(
      color: fg,
      fontSize: (text.bodyMedium!.fontSize ?? 14) * fontSize.scale,
    );
    final maxLines = compact ? 3 : 8;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: swatch.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.isSealed)
                  _LockedPreview(color: fg, label: l10n.lockedNote)
                else ...[
                  if (note.title.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium!.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (note.type == NoteType.text && note.text.trim().isNotEmpty)
                    Text(
                      note.text.trim(),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle,
                    ),
                  if (note.type == NoteType.checklist)
                    _ChecklistPreview(
                      note: note,
                      style: bodyStyle,
                      maxItems: maxLines,
                    ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _Footer(note: note, color: fg.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedPreview extends StatelessWidget {
  const new({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.lock, size: 18, color: color),
      const SizedBox(width: AppSpacing.sm),
      Text(
        label,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: color),
      ),
    ],
  );
}

class _ChecklistPreview extends StatelessWidget {
  const new({required this.note, required this.style, required this.maxItems});

  final Note note;
  final TextStyle style;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...note.items.where((i) => !i.checked),
      ...note.items.where((i) => i.checked),
    ].where((i) => i.text.trim().isNotEmpty).take(maxItems);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Row(
            children: [
              Icon(
                item.checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: style.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: item.checked
                      ? style.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: style.color?.withValues(alpha: 0.6),
                        )
                      : style,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const new({required this.note, required this.color});

  final Note note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale);
    final deleted = note.deletedAt;
    final label = deleted != null
        ? l10n.deletedOn(date.format(deleted.toLocal()))
        : date.format(note.updatedAt.toLocal());
    final style = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: color);
    return Row(
      children: [
        if (note.isPinned) Icon(Icons.push_pin, size: 14, color: color),
        if (note.isLocked && !note.isSealed)
          Icon(Icons.lock_open, size: 14, color: color),
        if (note.isPinned || (note.isLocked && !note.isSealed))
          const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: style)),
      ],
    );
  }
}

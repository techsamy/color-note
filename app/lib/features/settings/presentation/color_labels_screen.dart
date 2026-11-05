import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:huenote/l10n/note_color_l10n.dart';

/// FR-L5 — rename what each colour means. Saved as you type (on blur/done).
class ColorLabelsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final labels = ref.watch(colorLabelsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsColorLabels)),
      body: labels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (map) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l10n.settingsColorLabelsHint),
            const SizedBox(height: AppSpacing.lg),
            for (final c in NoteColor.values)
              _LabelField(color: c, initial: map[c] ?? ''),
          ],
        ),
      ),
    );
  }
}

class _LabelField extends ConsumerStatefulWidget {
  const new({required this.color, required this.initial});

  final NoteColor color;
  final String initial;

  @override
  ConsumerState<_LabelField> createState() => _LabelFieldState();
}

class _LabelFieldState extends ConsumerState<_LabelField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_controller.text.trim() == widget.initial) return;
    unawaited(
      ref
          .read(colorLabelsRepositoryProvider)
          .setLabel(widget.color, _controller.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final swatch = NotePalette.of(context)[widget.color];
    final name = widget.color.defaultLabel(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Focus(
        onFocusChange: (has) {
          if (!has) _save();
        },
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _save(),
          maxLength: 30,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: swatch.background,
              ),
            ),
            labelText: name,
            hintText: l10n.colorLabelHint(name),
            border: const OutlineInputBorder(),
            counterText: '',
          ),
        ),
      ),
    );
  }
}

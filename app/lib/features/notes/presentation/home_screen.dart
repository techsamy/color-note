import 'package:flutter/material.dart';
import 'package:huenote/core/widgets/empty_state.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

/// Placeholder home. Note list, FAB and filters arrive in Phase 1.
class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notesTitle)),
      body: EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: l10n.emptyNotesTitle,
        message: l10n.emptyNotesBody,
      ),
    );
  }
}

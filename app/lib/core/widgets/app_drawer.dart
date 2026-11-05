import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const new({required this.current, super.key});

  final String current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void go(String route) {
      Navigator.pop(context);
      if (route != current) context.go(route);
    }

    return NavigationDrawer(
      selectedIndex: switch (current) {
        Routes.archive => 1,
        Routes.trash => 2,
        _ => 0,
      },
      onDestinationSelected: (i) {
        if (i == 3) {
          Navigator.pop(context);
          unawaited(context.push(Routes.settings));
          return;
        }
        go([Routes.home, Routes.archive, Routes.trash][i]);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, AppSpacing.lg, 16, 10),
          child: Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.sticky_note_2_outlined),
          selectedIcon: const Icon(Icons.sticky_note_2),
          label: Text(l10n.notesTitle),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.archive_outlined),
          selectedIcon: const Icon(Icons.archive),
          label: Text(l10n.archiveTitle),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.delete_outline),
          selectedIcon: const Icon(Icons.delete),
          label: Text(l10n.trashTitle),
        ),
        const Divider(indent: 28, endIndent: 28),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          label: Text(l10n.settingsTitle),
        ),
      ],
    );
  }
}

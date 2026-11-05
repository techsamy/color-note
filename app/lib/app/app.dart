import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/features/auth/auth_providers.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:huenote/features/sync/sync_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

class HueNoteApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HueNoteApp> createState() => _HueNoteAppState();
}

class _HueNoteAppState extends ConsumerState<HueNoteApp> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    unawaited(_purgeTrash());
    unawaited(_syncIfSignedIn());
  }

  /// Only touches the sync machinery for signed-in users, so offline use
  /// never makes network calls.
  Future<void> _syncIfSignedIn() async {
    final account = await ref.read(authControllerProvider.future);
    if (account != null && mounted) {
      await ref.read(syncControllerProvider.notifier).syncNow(quiet: true);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// FR-N6: auto-empty trash after the configured retention.
  Future<void> _purgeTrash() async {
    final days = ref.read(settingsProvider).trashRetentionDays;
    if (days > 0) {
      await ref.read(notesRepositoryProvider).purgeTrash(Duration(days: days));
    }
  }

  void _onHide() => _hiddenAt = ref.read(clockProvider).now();

  /// FR-S3: relock after N minutes in background.
  void _onShow() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    unawaited(_syncIfSignedIn());
    if (hiddenAt == null) return;
    final limit = Duration(
      minutes: ref.read(settingsProvider).autoRelockMinutes,
    );
    if (ref.read(clockProvider).now().difference(hiddenAt) >= limit) {
      ref.read(lockControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

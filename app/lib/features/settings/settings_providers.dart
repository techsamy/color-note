import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/features/settings/data/settings_repository.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance (and in tests).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPreferencesProvider'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }

  Future<void> replace(AppSettings settings) => update((_) => settings);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

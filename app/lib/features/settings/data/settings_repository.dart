import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  new(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'app_settings_v1';

  AppSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e) {
      // Unknown enum from a newer version etc. — fall back, don't crash.
      debugPrint('Settings reset: $e');
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) =>
      _prefs.setString(_key, jsonEncode(settings.toJson()));
}

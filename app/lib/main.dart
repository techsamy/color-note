import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/app.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bootstrap only — no logic here. See docs/03-architecture.md §2.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const HueNoteApp(),
    ),
  );
}

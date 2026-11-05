import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/app/app.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Boots the real app on an in-memory DB with fast crypto.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) async {
  // A blinking cursor schedules frames forever and pumpAndSettle never ends.
  EditableText.debugDeterministicCursor = true;
  addTearDown(() => EditableText.debugDeterministicCursor = false);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  tester.view.physicalSize = const Size(412 * 3, 892 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = memoryDb();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      secureStoreProvider.overrideWithValue(InMemorySecureStore()),
      cryptoServiceProvider.overrideWithValue(fastCrypto()),
    ],
  );
  addTearDown(() async {
    // Unmount first so drift stream subscriptions are cancelled.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HueNoteApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Lets real async work (DB, crypto) finish, then settles the UI.
/// Loops while a spinner is visible (e.g. password hashing in progress).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final busy =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
    if (!busy && !tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle();
}

/// One DB write from the test, outside fake async. Do ONE write per call:
/// a live query in the UI re-runs between writes and needs a pump, or
/// the next write deadlocks on drift's lock.
Future<void> dbWrite(WidgetTester tester, Future<void> Function() write) async {
  await tester.runAsync(write);
  await settle(tester);
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/config/app_config.dart';
import 'package:huenote/core/network/api_client.dart';
import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/auth/data/auth_api.dart';
import 'package:huenote/features/auth/data/session_store.dart';
import 'package:huenote/features/auth/domain/account.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:huenote/features/sync/sync_providers.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(
    ref.watch(secureStoreProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// Stable per-install id sent as X-Device-Id.
final deviceIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final existing = prefs.getString('device_uuid');
  if (existing != null) return existing;
  final id = ref.watch(idGeneratorProvider).newId();
  unawaited(prefs.setString('device_uuid', id));
  return id;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(sessionStoreProvider);
  return ApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    token: session.token,
    deviceId: ref.watch(deviceIdProvider),
    appVersion: AppConfig.appVersion,
  );
});

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(
    ref.watch(apiClientProvider),
    deviceId: ref.watch(deviceIdProvider),
    deviceName: kIsWeb ? 'Web browser' : defaultTargetPlatform.name,
  ),
);

/// Signed-in account, or null (offline-only use is fully supported).
class AuthController extends AsyncNotifier<Account?> {
  SessionStore get _session => ref.read(sessionStoreProvider);

  AuthApi get _api => ref.read(authApiProvider);

  @override
  Future<Account?> build() async {
    final token = await _session.token();
    return token == null ? null : _session.account();
  }

  Future<void> signIn(String email, String password) async {
    await _complete(await _api.login(email.trim(), password));
  }

  Future<void> signUp(String email, String password, {String? name}) async {
    await _complete(await _api.register(email.trim(), password, name: name));
  }

  Future<void> _complete(SignInResult result) async {
    final last = _session.lastAccountUuid();
    if (last != null && last != result.account.uuid) {
      // Different account than the data on this device belongs to.
      await ref
          .read(syncStoreProvider)
          .detachForNewAccount(ref.read(idGeneratorProvider).newId);
    }
    await _session.save(result.token, result.account);
    state = AsyncData(result.account);
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
  }

  /// [keepNotes] false removes notes and the master key from this device.
  Future<void> signOut({required bool keepNotes}) async {
    final sync = ref.read(syncControllerProvider.notifier);
    // Best effort: get pending edits to the server first.
    await sync.syncNow(quiet: true);
    try {
      await _api.logout();
    } on ApiException {
      // Offline or token already revoked — signing out locally is enough.
    }
    await _session.clear(forgetDeviceData: !keepNotes);
    if (!keepNotes) {
      await ref.read(syncStoreProvider).wipe();
      await ref.read(lockControllerProvider.notifier).clear();
    }
    sync.reset();
    state = const AsyncData(null);
  }

  /// FR-B6. Notes stay on this device as offline notes.
  Future<void> deleteAccount(String password) async {
    await _api.deleteAccount(password: password);
    await ref.read(syncStoreProvider).detachKeepingIds();
    await _session.clear(forgetDeviceData: true);
    ref.read(syncControllerProvider.notifier).reset();
    state = const AsyncData(null);
  }

  /// Server said our token is no longer valid (revoked device etc.).
  Future<void> sessionExpired() async {
    await _session.clear(forgetDeviceData: false);
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Account?>(
  AuthController.new,
);

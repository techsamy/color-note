import 'dart:async';

import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/network/api_client.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/auth/auth_providers.dart';
import 'package:huenote/features/lock/domain/key_material.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/sync/data/http_sync_api.dart';
import 'package:huenote/features/sync/data/sync_store.dart';
import 'package:huenote/features/sync/domain/key_sync.dart';
import 'package:huenote/features/sync/domain/sync_engine.dart';

/// English fallback; the UI isn't involved in creating conflict copies.
const conflictCopySuffix = ' (conflicted copy)';

final syncStoreProvider = Provider<SyncStore>(
  (ref) => SyncStore(
    ref.watch(appDatabaseProvider),
    conflictSuffix: conflictCopySuffix,
  ),
);

final httpSyncApiProvider = Provider<HttpSyncApi>(
  (ref) => HttpSyncApi(ref.watch(apiClientProvider)),
);

@immutable
final class SyncStatus {
  const new({
    this.syncing = false,
    this.lastSyncedAt,
    this.error,
    this.keyMismatch = false,
  });

  final bool syncing;
  final DateTime? lastSyncedAt;

  /// Last failure (null when the last run succeeded).
  final ApiException? error;

  /// Account uses a different master password (docs/03 §3.4).
  final bool keyMismatch;

  SyncStatus copyWith({
    bool? syncing,
    DateTime? lastSyncedAt,
    ApiException? error,
    bool clearError = false,
    bool? keyMismatch,
  }) => SyncStatus(
    syncing: syncing ?? this.syncing,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    error: clearError ? null : (error ?? this.error),
    keyMismatch: keyMismatch ?? this.keyMismatch,
  );
}

/// Runs sync on demand, shortly after local edits, on app resume and every
/// few minutes while open (FR-B3). Background sync on Android: step 9.
class SyncController extends Notifier<SyncStatus> {
  static const editDebounce = Duration(seconds: 3);
  static const period = Duration(minutes: 5);

  Timer? _debounce;
  Timer? _periodic;
  var _rerun = false;

  @override
  SyncStatus build() {
    final db = ref.watch(appDatabaseProvider);
    final sub = db
        .tableUpdates(TableUpdateQuery.onAllTables([db.notes, db.colorLabels]))
        .listen((_) => _scheduleSoon());
    ref.onDispose(() {
      unawaited(sub.cancel());
      _debounce?.cancel();
      _periodic?.cancel();
    });
    return const SyncStatus();
  }

  void _scheduleSoon() {
    if (state.syncing) return; // our own writes while applying remote data
    if (ref.read(authControllerProvider).value == null) return;
    _debounce?.cancel();
    _debounce = Timer(editDebounce, () async {
      if (await ref.read(syncStoreProvider).hasDirty()) {
        await syncNow(quiet: true);
      }
    });
  }

  void reset() {
    _periodic?.cancel();
    _periodic = null;
    _debounce?.cancel();
    state = const SyncStatus();
  }

  SyncEngine _engine(String accountUuid) {
    final api = ref.read(httpSyncApiProvider);
    final session = ref.read(sessionStoreProvider);
    final lock = ref.read(lockControllerProvider.notifier);
    final keys = KeySync(
      api: api,
      readLocal: () async =>
          (await ref.read(lockControllerProvider.future)).material,
      adopt: lock.adoptMaterial,
      state: session.keyState(accountUuid),
    );
    return SyncEngine(
      api: api,
      store: ref.read(syncStoreProvider),
      cursor: session.cursor(accountUuid),
      newId: ref.read(idGeneratorProvider).newId,
      reconcileKeys: keys.reconcile,
    );
  }

  /// [quiet] runs keep a previous error visible but don't surface new
  /// network errors (offline is normal).
  Future<void> syncNow({bool quiet = false}) async {
    final account = await ref.read(authControllerProvider.future);
    if (account == null) return;
    _periodic ??= Timer.periodic(
      period,
      (_) => unawaited(syncNow(quiet: true)),
    );
    if (state.syncing) {
      _rerun = true;
      return;
    }
    state = state.copyWith(syncing: true);
    try {
      final report = await _engine(account.uuid).run();
      state = state.copyWith(
        syncing: false,
        lastSyncedAt: ref.read(clockProvider).now(),
        clearError: true,
        keyMismatch: report.keyState == KeyState.mismatch,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        syncing: false,
        error: quiet && e.isNetwork ? null : e,
      );
      if (e.status == 401) {
        await ref.read(authControllerProvider.notifier).sessionExpired();
      }
    } on Object catch (e) {
      debugPrint('Sync failed: $e');
      state = state.copyWith(
        syncing: false,
        error: ApiException(code: 'SYNC_FAILED', message: '$e'),
      );
    }
    if (_rerun) {
      _rerun = false;
      await syncNow(quiet: true);
    }
  }

  /// Re-encrypts this device's locked notes with the account's key so one
  /// master password works everywhere. Local session must be unlocked.
  /// Returns false for a wrong account master password.
  Future<bool> resolveKeyMismatch(String accountMasterPassword) async {
    final api = ref.read(httpSyncApiProvider);
    final remote = await api.getKeys();
    if (remote == null) return true;
    final theirs = KeyMaterial.fromJson(remote.material);
    final SecretKey theirDek;
    try {
      theirDek = await ref
          .read(masterKeyServiceProvider)
          .unlock(theirs, accountMasterPassword);
    } on WrongKeyException {
      return false;
    }
    final lock = ref.read(lockControllerProvider.notifier);
    final codec = ref.read(lockedNoteCodecProvider);
    final repo = ref.read(notesRepositoryProvider);
    for (final n in await repo.allNotes()) {
      final blob = n.encrypted;
      if (blob == null || blob.keyId == theirs.keyId) continue;
      final open = await lock.unseal(n);
      await repo.save(await codec.seal(open, theirDek, theirs.keyId));
    }
    await lock.adoptMaterial(theirs, dek: theirDek);
    final account = await ref.read(authControllerProvider.future);
    if (account != null) {
      await ref
          .read(sessionStoreProvider)
          .keyState(account.uuid)
          .writeVersion(remote.version);
    }
    state = state.copyWith(keyMismatch: false);
    await syncNow();
    return true;
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

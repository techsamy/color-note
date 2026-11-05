import 'dart:convert';

import 'package:huenote/features/lock/domain/key_material.dart';
import 'package:huenote/features/sync/domain/sync_api.dart';
import 'package:huenote/features/sync/domain/sync_engine.dart';

/// Remembers what we last agreed with the server (per account).
abstract interface class KeySyncState {
  Future<int?> readVersion();

  Future<void> writeVersion(int version);
}

/// Keeps the wrapped master key the same on the account and this device,
/// so one master password works everywhere (FR-S5).
class KeySync {
  new({
    required this.api,
    required this.readLocal,
    required this.adopt,
    required this.state,
  });

  final KeysApi api;
  final Future<KeyMaterial?> Function() readLocal;

  /// Replace local key material (session stays unlocked if same DEK).
  final Future<void> Function(KeyMaterial) adopt;
  final KeySyncState state;

  Future<KeyState> reconcile() async {
    final local = await readLocal();
    final remote = await api.getKeys();
    if (remote == null) {
      if (local != null) {
        await state.writeVersion(await api.putKeys(local.toJson(), 0));
      }
      return KeyState.ok;
    }
    final remoteMat = KeyMaterial.fromJson(remote.material);
    if (local == null) {
      await adopt(remoteMat);
      await state.writeVersion(remote.version);
      return KeyState.ok;
    }
    if (local.keyId != remoteMat.keyId) return KeyState.mismatch;
    if (jsonEncode(local.toJson()) == jsonEncode(remoteMat.toJson())) {
      await state.writeVersion(remote.version);
      return KeyState.ok;
    }
    final known = await state.readVersion() ?? 0;
    if (remote.version > known) {
      // Password changed on another device: take theirs.
      await adopt(remoteMat);
      await state.writeVersion(remote.version);
      return KeyState.ok;
    }
    try {
      // Password changed here: upload.
      await state.writeVersion(
        await api.putKeys(local.toJson(), remote.version),
      );
    } on KeyVersionConflict {
      final latest = await api.getKeys();
      if (latest != null) {
        await adopt(KeyMaterial.fromJson(latest.material));
        await state.writeVersion(latest.version);
      }
    }
    return KeyState.ok;
  }
}

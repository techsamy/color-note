import 'dart:convert';

import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/features/lock/domain/key_material.dart';

/// Persists the (wrapped) master key material. Synced to the server in
/// Phase 2 (`/me/keys`).
class KeyMaterialStore {
  new(this._store);

  final SecureStore _store;
  static const _key = 'master_key_v1';

  Future<KeyMaterial?> read() async {
    final raw = await _store.read(_key);
    return raw == null
        ? null
        : KeyMaterial.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(KeyMaterial m) =>
      _store.write(_key, jsonEncode(m.toJson()));
}

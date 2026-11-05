import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/lock/data/key_material_store.dart';
import 'package:huenote/features/lock/domain/key_material.dart';
import 'package:huenote/features/lock/domain/locked_note_codec.dart';
import 'package:huenote/features/lock/domain/master_key_service.dart';
import 'package:huenote/features/notes/domain/note.dart';

final keyMaterialStoreProvider = Provider<KeyMaterialStore>(
  (ref) => KeyMaterialStore(ref.watch(secureStoreProvider)),
);

final masterKeyServiceProvider = Provider<MasterKeyService>((ref) {
  final ids = ref.watch(idGeneratorProvider);
  return MasterKeyService(ref.watch(cryptoServiceProvider), ids.newId);
});

final lockedNoteCodecProvider = Provider<LockedNoteCodec>(
  (ref) => LockedNoteCodec(ref.watch(cryptoServiceProvider)),
);

@immutable
final class LockState {
  const new({this.material, this.dek});

  final KeyMaterial? material;

  /// In memory only while unlocked; dropped on [LockController.lock].
  final SecretKey? dek;

  bool get hasMasterPassword => material != null;

  bool get isUnlocked => dek != null;
}

/// Master-password session (FR-S1, S3, S6).
class LockController extends AsyncNotifier<LockState> {
  KeyMaterialStore get _store => ref.read(keyMaterialStoreProvider);

  MasterKeyService get _keys => ref.read(masterKeyServiceProvider);

  LockedNoteCodec get _codec => ref.read(lockedNoteCodecProvider);

  @override
  Future<LockState> build() async => LockState(material: await _store.read());

  LockState get _current => state.value ?? const LockState();

  /// Creates the master password and unlocks. Returns the recovery key.
  Future<String> setUp(String password) async {
    if (_current.hasMasterPassword) {
      throw StateError('Master password already set');
    }
    final created = await _keys.create(password);
    await _store.write(created.material);
    state = AsyncData(LockState(material: created.material, dek: created.dek));
    return created.recoveryKey;
  }

  /// Returns false for a wrong password.
  Future<bool> unlock(String password) async {
    final material = _current.material;
    if (material == null) return false;
    try {
      final dek = await _keys.unlock(material, password);
      state = AsyncData(LockState(material: material, dek: dek));
      return true;
    } on WrongKeyException {
      return false;
    }
  }

  /// Sets a new password using the recovery key. Returns the NEW recovery
  /// key, or null if the recovery key was wrong.
  Future<String?> resetWithRecoveryKey(
    String recoveryKey,
    String newPassword,
  ) async {
    final material = _current.material;
    if (material == null) return null;
    try {
      final dek = await _keys.unlockWithRecoveryKey(material, recoveryKey);
      return await _rewrap(material, dek, newPassword);
    } on WrongKeyException {
      return null;
    }
  }

  /// Returns the NEW recovery key, or null if [current] was wrong.
  Future<String?> changePassword(String current, String newPassword) async {
    final material = _current.material;
    if (material == null) return null;
    try {
      final dek = await _keys.unlock(material, current);
      return await _rewrap(material, dek, newPassword);
    } on WrongKeyException {
      return null;
    }
  }

  Future<String> _rewrap(
    KeyMaterial material,
    SecretKey dek,
    String newPassword,
  ) async {
    final next = await _keys.rewrap(material, dek, newPassword);
    await _store.write(next.material);
    state = AsyncData(LockState(material: next.material, dek: dek));
    return next.recoveryKey;
  }

  void lock() {
    final current = _current;
    if (current.isUnlocked) {
      state = AsyncData(LockState(material: current.material));
    }
  }

  /// Replaces the key material (backup restore, account key sync).
  /// Stays unlocked when [dek] is given, or when the key id is unchanged
  /// (same DEK, only the password wrapping changed).
  Future<void> adoptMaterial(KeyMaterial material, {SecretKey? dek}) async {
    await _store.write(material);
    final current = _current;
    final keep = current.material?.keyId == material.keyId ? current.dek : null;
    state = AsyncData(LockState(material: material, dek: dek ?? keep));
  }

  /// Forget the master key on this device (sign-out with "remove notes").
  Future<void> clear() async {
    await _store.clear();
    state = const AsyncData(LockState());
  }

  Future<Note> seal(Note note) {
    final s = _current;
    final dek = s.dek;
    final material = s.material;
    if (dek == null || material == null) throw StateError('Locked');
    return _codec.seal(note, dek, material.keyId);
  }

  Future<Note> unseal(Note note) {
    final dek = _current.dek;
    if (dek == null) throw StateError('Locked');
    return _codec.unseal(note, dek);
  }
}

final lockControllerProvider = AsyncNotifierProvider<LockController, LockState>(
  LockController.new,
);

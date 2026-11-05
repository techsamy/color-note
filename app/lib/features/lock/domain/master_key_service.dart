import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/features/lock/domain/key_material.dart';

final class NewMasterKey {
  const new({
    required this.material,
    required this.dek,
    required this.recoveryKey,
  });

  final KeyMaterial material;
  final SecretKey dek;

  /// Shown to the user once; never stored.
  final String recoveryKey;
}

/// Key hierarchy: password -> KEK (Argon2id) -> wraps random DEK.
/// Changing the password only re-wraps the DEK (ADR 0005).
class MasterKeyService {
  new(this._crypto, this._newId);

  final CryptoService _crypto;
  final String Function() _newId;

  static const minPasswordLength = 6;

  Future<NewMasterKey> create(String password) async {
    final dek = await _crypto.newKey();
    final recoveryKey = generateRecoveryKey();
    final material = await _wrap(
      keyId: _newId(),
      dek: dek,
      password: password,
      recoveryKey: recoveryKey,
    );
    return NewMasterKey(material: material, dek: dek, recoveryKey: recoveryKey);
  }

  /// Throws [WrongKeyException] for a wrong password.
  Future<SecretKey> unlock(KeyMaterial m, String password) async {
    final kek = await _crypto.deriveKey(password, m.kdf);
    final bytes = await _crypto.decrypt(
      kek,
      Sealed(ciphertext: m.wrappedDek, nonce: m.wrapNonce),
    );
    return _crypto.keyFromBytes(bytes);
  }

  /// Throws [WrongKeyException] for a wrong/missing recovery key.
  Future<SecretKey> unlockWithRecoveryKey(
    KeyMaterial m,
    String recoveryKey,
  ) async {
    final kdf = m.recoveryKdf;
    final wrapped = m.recoveryWrappedDek;
    final nonce = m.recoveryWrapNonce;
    if (kdf == null || wrapped == null || nonce == null) {
      throw const WrongKeyException();
    }
    final kek = await _crypto.deriveKey(normalizeRecoveryKey(recoveryKey), kdf);
    final bytes = await _crypto.decrypt(
      kek,
      Sealed(ciphertext: wrapped, nonce: nonce),
    );
    return _crypto.keyFromBytes(bytes);
  }

  /// New password for the same DEK. Issues a new recovery key too.
  Future<NewMasterKey> rewrap(
    KeyMaterial m,
    SecretKey dek,
    String newPassword,
  ) async {
    final recoveryKey = generateRecoveryKey();
    final material = await _wrap(
      keyId: m.keyId,
      dek: dek,
      password: newPassword,
      recoveryKey: recoveryKey,
    );
    return NewMasterKey(material: material, dek: dek, recoveryKey: recoveryKey);
  }

  Future<KeyMaterial> _wrap({
    required String keyId,
    required SecretKey dek,
    required String password,
    required String recoveryKey,
  }) async {
    final dekBytes = await _crypto.keyBytes(dek);
    final kdf = _crypto.newKdfParams();
    final wrapped = await _crypto.encrypt(
      await _crypto.deriveKey(password, kdf),
      dekBytes,
    );
    final rKdf = _crypto.newKdfParams();
    final rWrapped = await _crypto.encrypt(
      await _crypto.deriveKey(normalizeRecoveryKey(recoveryKey), rKdf),
      dekBytes,
    );
    return KeyMaterial(
      keyId: keyId,
      kdf: kdf,
      wrappedDek: wrapped.ciphertext,
      wrapNonce: wrapped.nonce,
      recoveryKdf: rKdf,
      recoveryWrappedDek: rWrapped.ciphertext,
      recoveryWrapNonce: rWrapped.nonce,
    );
  }

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  /// 24 chars from a 32-symbol alphabet = 120 bits, shown as XXXX-XXXX-...
  String generateRecoveryKey() {
    final bytes = _crypto.randomBytes(24);
    final chars = [for (final b in bytes) _alphabet[b % _alphabet.length]];
    return [
      for (var i = 0; i < chars.length; i += 4)
        chars.sublist(i, min(i + 4, chars.length)).join(),
    ].join('-');
  }

  /// Accepts any case / spacing / dashes.
  static String normalizeRecoveryKey(String input) =>
      input.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
}

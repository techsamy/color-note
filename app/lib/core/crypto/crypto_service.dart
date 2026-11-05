import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/crypto/kdf_params.dart';

/// Thrown when a password/key cannot decrypt (GCM authentication failed).
final class WrongKeyException implements Exception {
  const new();

  @override
  String toString() => 'WrongKeyException';
}

/// AES-256-GCM output: base64(ciphertext || 16-byte mac) + base64 nonce.
final class Sealed {
  const new({required this.ciphertext, required this.nonce});

  final String ciphertext;
  final String nonce;
}

/// The only place that touches crypto primitives (docs/06 §2).
/// No custom crypto: AES-256-GCM + Argon2id from package:cryptography.
class CryptoService {
  new({this.memoryKib = 19456, this.iterations = 2});

  /// Defaults for *new* keys. Existing data uses its stored [KdfParams].
  final int memoryKib;
  final int iterations;

  static const _macLength = 16;
  final _aes = AesGcm.with256bits();

  KdfParams newKdfParams() => KdfParams(
    salt: base64Encode(_randomBytes(16)),
    memoryKib: memoryKib,
    iterations: iterations,
  );

  Future<SecretKey> deriveKey(String password, KdfParams p) {
    if (p.alg != 'argon2id') {
      throw UnsupportedError('Unknown KDF ${p.alg}');
    }
    return Argon2id(
      memory: p.memoryKib,
      iterations: p.iterations,
      parallelism: p.parallelism,
      hashLength: 32,
    ).deriveKeyFromPassword(password: password, nonce: base64Decode(p.salt));
  }

  Future<SecretKey> newKey() => _aes.newSecretKey();

  Future<Sealed> encrypt(SecretKey key, List<int> plaintext) async {
    final box = await _aes.encrypt(plaintext, secretKey: key);
    return Sealed(
      ciphertext: base64Encode([...box.cipherText, ...box.mac.bytes]),
      nonce: base64Encode(box.nonce),
    );
  }

  Future<Uint8List> decrypt(SecretKey key, Sealed sealed) async {
    final data = base64Decode(sealed.ciphertext);
    if (data.length < _macLength) throw const WrongKeyException();
    final split = data.length - _macLength;
    try {
      final clear = await _aes.decrypt(
        SecretBox(
          data.sublist(0, split),
          nonce: base64Decode(sealed.nonce),
          mac: Mac(data.sublist(split)),
        ),
        secretKey: key,
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const WrongKeyException();
    }
  }

  Future<Sealed> encryptString(SecretKey key, String text) =>
      encrypt(key, utf8.encode(text));

  Future<String> decryptString(SecretKey key, Sealed sealed) async =>
      utf8.decode(await decrypt(key, sealed));

  Future<List<int>> keyBytes(SecretKey key) => key.extractBytes();

  SecretKey keyFromBytes(List<int> bytes) => SecretKey(bytes);

  List<int> randomBytes(int length) => _randomBytes(length);

  static List<int> _randomBytes(int length) =>
      SecretKeyData.random(length: length).bytes;
}

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

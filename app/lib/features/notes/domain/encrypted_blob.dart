import 'package:freezed_annotation/freezed_annotation.dart';

part 'encrypted_blob.freezed.dart';
part 'encrypted_blob.g.dart';

/// AES-256-GCM ciphertext (+ 16-byte MAC appended) with its metadata.
/// Stored as `body` (ciphertext) + `crypto_meta` (the rest) — docs/04.
@freezed
abstract class EncryptedBlob with _$EncryptedBlob {
  const factory({
    /// base64(ciphertext || mac)
    required String ciphertext,

    /// base64 96-bit nonce
    required String nonce,

    /// Which data-encryption key sealed this (supports key changes later).
    required String keyId,
    @Default(1) int v,
    @Default('aes-256-gcm') String alg,
  }) = _EncryptedBlob;

  factory fromJson(Map<String, dynamic> json) => _$EncryptedBlobFromJson(json);
}

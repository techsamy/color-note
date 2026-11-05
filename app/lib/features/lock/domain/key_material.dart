import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:huenote/core/crypto/kdf_params.dart';

part 'key_material.freezed.dart';
part 'key_material.g.dart';

/// Everything needed to recover the note-encryption key (DEK) from the
/// master password or recovery key. Safe to store/sync: the DEK is only
/// present *wrapped* (encrypted). docs/03 §3.4.
@freezed
abstract class KeyMaterial with _$KeyMaterial {
  const factory({
    required String keyId,
    required KdfParams kdf,
    required String wrappedDek,
    required String wrapNonce,
    KdfParams? recoveryKdf,
    String? recoveryWrappedDek,
    String? recoveryWrapNonce,
  }) = _KeyMaterial;

  factory fromJson(Map<String, dynamic> json) => _$KeyMaterialFromJson(json);
}

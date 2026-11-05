import 'package:freezed_annotation/freezed_annotation.dart';

part 'kdf_params.freezed.dart';
part 'kdf_params.g.dart';

/// Password-hashing parameters, stored next to whatever they protect so
/// costs can be raised later without breaking old keys/backups.
@freezed
abstract class KdfParams with _$KdfParams {
  const factory({
    /// base64 random salt (16 bytes)
    required String salt,
    @Default('argon2id') String alg,

    /// KiB. Default 19 MiB / 2 passes = OWASP baseline (docs/06 §2).
    @Default(19456) int memoryKib,
    @Default(2) int iterations,
    @Default(1) int parallelism,
  }) = _KdfParams;

  factory fromJson(Map<String, dynamic> json) => _$KdfParamsFromJson(json);
}

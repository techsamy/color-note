import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/crypto/kdf_params.dart';
import 'package:huenote/features/backup/data/note_json.dart';
import 'package:huenote/features/lock/domain/key_material.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';

final class InvalidBackupException implements Exception {
  const new(this.reason);

  final String reason;

  @override
  String toString() => 'InvalidBackupException: $reason';
}

/// Decrypted contents of a `.huenote` backup.
final class BackupContents {
  const new({
    required this.createdAt,
    required this.notes,
    required this.colorLabels,
    required this.settings,
    this.keyMaterial,
  });

  final DateTime createdAt;
  final List<Note> notes;
  final Map<NoteColor, String> colorLabels;
  final Map<String, dynamic>? settings;

  /// Wrapped master key of the device that made the backup (locked notes).
  final KeyMaterial? keyMaterial;

  int get lockedCount => notes.where((n) => n.isLocked).length;
}

/// Encrypted backup file format — docs/04-data-model.md §4.
///   zip { manifest.json (plain), data.bin (AES-GCM of JSON payload) }
class BackupService {
  new(this._crypto, {required this.appVersion});

  final CryptoService _crypto;
  final String appVersion;

  static const formatVersion = 1;
  static const fileExtension = 'huenote';
  static const int maxFileBytes = 200 * 1024 * 1024;

  Future<Uint8List> create({
    required String password,
    required DateTime now,
    required List<Note> notes,
    required Map<NoteColor, String> colorLabels,
    required Map<String, dynamic> settings,
    KeyMaterial? keyMaterial,
  }) async {
    final payload = jsonEncode({
      'notes': [for (final n in notes) NoteJson.encode(n)],
      'colorLabels': {
        for (final e in colorLabels.entries) '${e.key.value}': e.value,
      },
      'settings': settings,
      'keyMaterial': keyMaterial?.toJson(),
    });
    final kdf = _crypto.newKdfParams();
    final key = await _crypto.deriveKey(password, kdf);
    final sealed = await _crypto.encryptString(key, payload);
    final manifest = jsonEncode({
      'format_version': formatVersion,
      'app_version': appVersion,
      'created_at': now.toUtc().toIso8601String(),
      'note_count': notes.length,
      'kdf': kdf.toJson(),
      'cipher': 'aes-256-gcm',
      'nonce': sealed.nonce,
    });
    final archive = Archive()
      ..add(ArchiveFile.string('manifest.json', manifest))
      ..add(ArchiveFile.bytes('data.bin', base64Decode(sealed.ciphertext)));
    return ZipEncoder().encodeBytes(archive);
  }

  /// Throws [InvalidBackupException] or [WrongKeyException].
  Future<BackupContents> open(Uint8List bytes, String password) async {
    if (bytes.length > maxFileBytes) {
      throw const InvalidBackupException('File too large');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const InvalidBackupException('Not a backup file');
    }
    final manifestFile = archive.findFile('manifest.json');
    final dataFile = archive.findFile('data.bin');
    if (manifestFile == null || dataFile == null) {
      throw const InvalidBackupException('Not a backup file');
    }
    final Map<String, dynamic> manifest;
    try {
      manifest =
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
    } on FormatException {
      throw const InvalidBackupException('Corrupt manifest');
    }
    final version = manifest['format_version'];
    if (version is! int || version > formatVersion) {
      throw const InvalidBackupException('Made by a newer app version');
    }
    final kdf = KdfParams.fromJson(manifest['kdf'] as Map<String, dynamic>);
    final key = await _crypto.deriveKey(password, kdf);
    final json = await _crypto.decryptString(
      key,
      Sealed(
        ciphertext: base64Encode(dataFile.content),
        nonce: manifest['nonce'] as String,
      ),
    );
    final data = jsonDecode(json) as Map<String, dynamic>;
    final keyJson = data['keyMaterial'] as Map<String, dynamic>?;
    return BackupContents(
      createdAt: DateTime.parse(manifest['created_at'] as String),
      notes: [
        for (final n in data['notes'] as List<dynamic>)
          NoteJson.decode(n as Map<String, dynamic>),
      ],
      colorLabels: {
        for (final e in (data['colorLabels'] as Map<String, dynamic>).entries)
          NoteColor.fromValue(int.parse(e.key)): e.value as String,
      },
      settings: data['settings'] as Map<String, dynamic>?,
      keyMaterial: keyJson == null ? null : KeyMaterial.fromJson(keyJson),
    );
  }
}

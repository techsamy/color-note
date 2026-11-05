import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note.dart';

/// Seals/unseals the content (title + body) of locked notes with the DEK.
class LockedNoteCodec {
  new(this._crypto);

  final CryptoService _crypto;

  Future<Note> seal(Note note, SecretKey dek, String keyId) async {
    final payload = jsonEncode({
      'title': note.title,
      'text': note.text,
      'items': [for (final i in note.items) i.toJson()],
    });
    final sealed = await _crypto.encryptString(dek, payload);
    return note.copyWith(
      isLocked: true,
      title: '',
      text: '',
      items: const [],
      encrypted: EncryptedBlob(
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
        keyId: keyId,
      ),
    );
  }

  /// Returns the note with readable content; still `isLocked`, and
  /// `encrypted` cleared so it is re-sealed on save.
  /// Throws [WrongKeyException] if [dek] doesn't match.
  Future<Note> unseal(Note note, SecretKey dek) async {
    final blob = note.encrypted;
    if (blob == null) return note;
    final json = jsonDecode(
      await _crypto.decryptString(
        dek,
        Sealed(ciphertext: blob.ciphertext, nonce: blob.nonce),
      ),
    ) as Map<String, dynamic>;
    return note.copyWith(
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      items: [
        for (final e in (json['items'] as List<dynamic>? ?? const []))
          ChecklistItem.fromJson(e as Map<String, dynamic>),
      ],
      encrypted: null,
    );
  }
}

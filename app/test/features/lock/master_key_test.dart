import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/features/lock/domain/locked_note_codec.dart';
import 'package:huenote/features/lock/domain/master_key_service.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

import '../../helpers/fakes.dart';

void main() {
  final crypto = fastCrypto();
  final service = MasterKeyService(crypto, SeqIds().newId);
  final codec = LockedNoteCodec(crypto);

  test('password unlocks the same DEK; wrong password fails', () async {
    final created = await service.create('hunter22');
    final dek = await service.unlock(created.material, 'hunter22');
    expect(await dek.extractBytes(), await created.dek.extractBytes());
    expect(
      () => service.unlock(created.material, 'nope'),
      throwsA(isA<WrongKeyException>()),
    );
  });

  test('recovery key works in any formatting', () async {
    final created = await service.create('hunter22');
    expect(
      created.recoveryKey,
      matches(RegExp(r'^([A-Z2-9]{4}-){5}[A-Z2-9]{4}$')),
    );
    final messy = created.recoveryKey.toLowerCase().replaceAll('-', ' ');
    final dek = await service.unlockWithRecoveryKey(created.material, messy);
    expect(await dek.extractBytes(), await created.dek.extractBytes());
    expect(
      () => service.unlockWithRecoveryKey(created.material, 'AAAA-BBBB'),
      throwsA(isA<WrongKeyException>()),
    );
  });

  test('rewrap: new password works, old fails, notes still decrypt', () async {
    final created = await service.create('first1');
    final sealed = await codec.seal(
      textNote('n', title: 'secret', text: 'body'),
      created.dek,
      created.material.keyId,
    );
    final next = await service.rewrap(created.material, created.dek, 'second2');
    expect(next.material.keyId, created.material.keyId);
    expect(
      () => service.unlock(next.material, 'first1'),
      throwsA(isA<WrongKeyException>()),
    );
    final dek = await service.unlock(next.material, 'second2');
    final open = await codec.unseal(sealed, dek);
    expect(open.title, 'secret');
    expect(open.text, 'body');
  });

  test('codec seals all content and rejects a foreign key', () async {
    final a = await service.create('aaaaaa');
    final b = await service.create('bbbbbb');
    final note = textNote('n', title: 'TopSecretTitle').copyWith(
      type: NoteType.checklist,
      items: const [ChecklistItem(id: '1', text: 'x', checked: true)],
    );
    final sealed = await codec.seal(note, a.dek, a.material.keyId);
    expect(sealed.isSealed, isTrue);
    expect(sealed.title, isEmpty);
    expect(sealed.items, isEmpty);
    expect(
      String.fromCharCodes(base64Decode(sealed.encrypted!.ciphertext)),
      isNot(contains('TopSecretTitle')),
    );

    final open = await codec.unseal(sealed, a.dek);
    expect(open.items, note.items);
    expect(open.isSealed, isFalse);
    expect(
      () => codec.unseal(sealed, b.dek),
      throwsA(isA<WrongKeyException>()),
    );
  });
}

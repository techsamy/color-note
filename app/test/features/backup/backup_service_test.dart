import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/features/backup/data/backup_service.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

import '../../helpers/fakes.dart';

void main() {
  final service = BackupService(fastCrypto(), appVersion: '0.1.0');
  final notes = [
    textNote('a', title: 'Hello', text: 'world'),
    textNote('b').copyWith(
      type: NoteType.checklist,
      items: const [ChecklistItem(id: '1', text: 'milk', checked: true)],
      deletedAt: DateTime.utc(2026, 11),
    ),
  ];

  Future<Uint8List> make() => service.create(
    password: 'backup-pw',
    now: DateTime.utc(2026, 11, 5),
    notes: notes,
    colorLabels: {NoteColor.red: 'Work'},
    settings: {'sort': 'title'},
  );

  test('round-trips notes, labels and settings', () async {
    final contents = await service.open(await make(), 'backup-pw');
    expect(contents.notes, notes);
    expect(contents.colorLabels, {NoteColor.red: 'Work'});
    expect(contents.settings, {'sort': 'title'});
    expect(contents.createdAt, DateTime.utc(2026, 11, 5));
    expect(contents.keyMaterial, isNull);
  });

  test('content is encrypted', () async {
    final bytes = await make();
    expect(String.fromCharCodes(bytes), isNot(contains('Hello')));
  });

  test('wrong password and invalid files are rejected', () async {
    final bytes = await make();
    await expectLater(
      service.open(bytes, 'nope'),
      throwsA(isA<WrongKeyException>()),
    );
    await expectLater(
      service.open(Uint8List.fromList([1, 2, 3]), 'x'),
      throwsA(isA<InvalidBackupException>()),
    );
  });
}

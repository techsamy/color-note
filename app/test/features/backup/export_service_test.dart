import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/features/backup/data/export_service.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

import '../../helpers/fakes.dart';

void main() {
  test('exports readable text + json; skips locked, trashed, empty', () {
    final notes = [
      textNote('a', title: 'Shopping / list?', text: 'milk'),
      textNote('b', title: 'Shopping / list?', text: 'again'),
      textNote('c').copyWith(
        type: NoteType.checklist,
        items: const [
          ChecklistItem(id: '1', text: 'eggs', checked: true),
          ChecklistItem(id: '2', text: 'bread'),
        ],
      ),
      textNote('d', title: 'Secret').copyWith(
        isLocked: true,
        encrypted: const EncryptedBlob(ciphertext: 'x', nonce: 'y', keyId: 'k'),
      ),
      textNote('e', title: 'Old').copyWith(deletedAt: DateTime.utc(2026)),
      textNote('f'),
    ];
    final zip = ZipDecoder().decodeBytes(
      const ExportService().export(notes, now: DateTime.utc(2026, 11, 6)),
    );
    final names = zip.files.map((f) => f.name).toSet();
    expect(names, {
      'notes/Shopping list.txt',
      'notes/Shopping list (2).txt',
      'notes/eggs.txt',
      'notes.json',
    });
    expect(
      utf8.decode(zip.findFile('notes/eggs.txt')!.content),
      '[x] eggs\n[ ] bread\n',
    );
    final json = jsonDecode(
      utf8.decode(zip.findFile('notes.json')!.content),
    ) as Map<String, dynamic>;
    expect((json['notes'] as List).length, 3);
    expect(
      utf8.decode(zip.findFile('notes.json')!.content),
      isNot(contains('Secret')),
    );
  });
}

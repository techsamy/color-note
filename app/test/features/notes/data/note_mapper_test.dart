import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/features/notes/data/note_mapper.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

import '../../../helpers/fakes.dart';

Note roundTrip(Note n) {
  final c = NoteMapper.toCompanion(n);
  return NoteMapper.fromRow(
    NoteRow(
      id: c.id.value,
      type: c.type.value,
      title: c.title.value,
      body: c.body.value,
      color: c.color.value,
      isPinned: c.isPinned.value,
      isArchived: c.isArchived.value,
      isLocked: c.isLocked.value,
      cryptoMeta: c.cryptoMeta.value,
      reminderAllDay: false,
      statusBarPinned: false,
      createdAt: c.createdAt.value,
      updatedAt: c.updatedAt.value,
      deletedAt: c.deletedAt.value,
      baseVersion: 0,
      dirty: true,
      myPermission: 0,
      purged: false,
    ),
  );
}

void main() {
  test('text and checklist notes round-trip', () {
    final text = textNote('a', title: 'T', text: 'body');
    expect(roundTrip(text), text);

    final list = text.copyWith(
      type: NoteType.checklist,
      text: '',
      items: const [ChecklistItem(id: '1', text: 'x', checked: true)],
    );
    expect(roundTrip(list), list);
  });

  test('locked note stores only ciphertext', () {
    final locked = textNote('a').copyWith(
      isLocked: true,
      encrypted: const EncryptedBlob(
        ciphertext: 'Q0lQSA==',
        nonce: 'Tk9OQ0U=',
        keyId: 'k1',
      ),
    );
    final c = NoteMapper.toCompanion(locked);
    expect(c.title.value, '');
    expect(c.body.value, 'Q0lQSA==');
    expect(c.cryptoMeta.value, isNot(contains('Q0lQSA==')));
    expect(roundTrip(locked), locked);
  });

  test('refuses to store an unsealed locked note', () {
    final open = textNote('a', text: 'secret').copyWith(isLocked: true);
    expect(() => NoteMapper.toCompanion(open), throwsStateError);
  });

  test('corrupt checklist body keeps the text', () {
    expect(NoteMapper.decodeItems('milk\neggs').map((i) => i.text), [
      'milk',
      'eggs',
    ]);
    expect(const Value(1).present, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/features/notes/data/notes_repository_impl.dart';
import 'package:huenote/features/notes/domain/encrypted_blob.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';

import '../../../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late NotesRepositoryImpl repo;

  setUp(() {
    db = memoryDb();
    clock = FakeClock();
    repo = NotesRepositoryImpl(db, clock, SeqIds());
  });
  tearDown(() => db.close());

  Future<List<String>> ids([NoteQuery q = const NoteQuery()]) async =>
      (await repo.watchNotes(q).first).map((n) => n.id).toList();

  Future<List<String>> search(
    String text, {
    Set<NoteColor> colors = const {},
  }) async => (await repo.watchSearch(text, colors: colors).first)
      .map((n) => n.id)
      .toList();

  test('save stamps updatedAt and lists newest first', () async {
    await repo.save(textNote('a', text: 'one'));
    clock.advance(const Duration(minutes: 1));
    await repo.save(textNote('b', text: 'two'));
    expect(await ids(), ['b', 'a']);
    expect((await repo.getNote('b'))!.updatedAt, clock.now());
  });

  test('pinned first; archive and trash move between sections', () async {
    await repo.save(textNote('a'));
    clock.advance(const Duration(minutes: 1));
    await repo.save(textNote('b'));
    await repo.setPinned(['a'], pinned: true);
    expect(await ids(), ['a', 'b']);

    await repo.setArchived(['a'], archived: true);
    expect(await ids(), ['b']);
    expect(await ids(const NoteQuery(section: NoteSection.archive)), ['a']);
    expect((await repo.getNote('a'))!.isPinned, isFalse);

    await repo.moveToTrash(['b']);
    expect(await ids(), isEmpty);
    expect(await ids(const NoteQuery(section: NoteSection.trash)), ['b']);

    await repo.restoreFromTrash(['b']);
    expect(await ids(), ['b']);
  });

  test('colour filter and title sort', () async {
    await repo.save(textNote('a', title: 'banana', color: NoteColor.red));
    await repo.save(textNote('b', title: 'Apple', color: NoteColor.blue));
    await repo.save(textNote('c', title: 'cherry', color: NoteColor.red));
    expect(
      await ids(const NoteQuery(colors: {NoteColor.red})),
      unorderedEquals(['a', 'c']),
    );
    expect(await ids(const NoteQuery(sort: NoteSort.title)), ['b', 'a', 'c']);
  });

  test('search: prefix, all words, title+body, colour filter', () async {
    await repo.save(textNote('a', title: 'Groceries', text: 'milk eggs'));
    await repo.save(
      textNote(
        'b',
        title: 'Work',
        text: 'milkshake meeting',
        color: NoteColor.blue,
      ),
    );
    expect(await search('mil'), unorderedEquals(['a', 'b']));
    expect(await search('milk groc'), ['a']);
    expect(await search('meet', colors: {NoteColor.yellow}), isEmpty);
    expect(await search('   '), isEmpty);
  });

  test('search is injection-safe', () async {
    await repo.save(textNote('a', text: 'say "hi" OR NOT'));
    expect(await search('"hi'), ['a']);
    expect(await search('NOT'), ['a']);
    expect(await search('*'), isEmpty);
  });

  test(
    'search excludes trash and locked notes; index updates on edit',
    () async {
      await repo.save(textNote('a', text: 'alpha'));
      await repo.save(textNote('b', text: 'alpha'));
      await repo.moveToTrash(['b']);
      expect(await search('alpha'), ['a']);

      await repo.save(textNote('a', text: 'beta'));
      expect(await search('alpha'), isEmpty);

      await repo.save(
        textNote('a').copyWith(
          isLocked: true,
          encrypted: const EncryptedBlob(
            ciphertext: 'eA==',
            nonce: 'eA==',
            keyId: 'k',
          ),
        ),
      );
      expect(await search('beta'), isEmpty);
      expect(await repo.countLocked(), 1);
    },
  );

  test('delete forever, empty trash, purge by retention', () async {
    await repo.save(textNote('a', text: 'x'));
    await repo.save(textNote('b', text: 'x'));
    await repo.save(textNote('c', text: 'x'));
    await repo.moveToTrash(['a']);
    clock.advance(const Duration(days: 31));
    await repo.moveToTrash(['b']);

    expect(await repo.purgeTrash(const Duration(days: 30)), 1);
    expect(await repo.getNote('a'), isNull);

    await repo.deleteForever(['c']);
    expect(await repo.getNote('c'), isNull);
    expect(await search('x'), isEmpty);

    await repo.emptyTrash();
    expect(await repo.allNotes(), isEmpty);
  });

  test('duplicate creates an unpinned copy', () async {
    await repo.save(textNote('a', title: 'T', text: 'body'));
    await repo.setPinned(['a'], pinned: true);
    final copyId = await repo.duplicate('a');
    final copy = (await repo.getNote(copyId))!;
    expect(copy.title, 'T');
    expect(copy.text, 'body');
    expect(copy.isPinned, isFalse);
  });

  test('import keeps newer local edits', () async {
    await repo.save(textNote('a', text: 'local'));
    final older = textNote('a', text: 'old', at: DateTime.utc(2020));
    final newer = textNote('b', text: 'new');
    final result = await repo.importNotes([older, newer]);
    expect(result.added, 1);
    expect(result.skipped, 1);
    expect((await repo.getNote('a'))!.text, 'local');
    expect(await search('new'), ['b']);

    final evenNewer = textNote('a', text: 'restored', at: DateTime.utc(2030));
    expect((await repo.importNotes([evenNewer])).updated, 1);
    expect((await repo.getNote('a'))!.text, 'restored');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/notes/data/color_labels_repository_impl.dart';
import 'package:huenote/features/notes/data/notes_repository_impl.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/sync/data/sync_store.dart';
import 'package:huenote/features/sync/domain/sync_api.dart';
import 'package:huenote/features/sync/domain/sync_engine.dart';

import '../../helpers/fakes.dart';
import 'fake_server.dart';

class MemoryCursor implements CursorStore {
  int value = 0;

  @override
  Future<int> read() async => value;

  @override
  Future<void> write(int cursor) async => value = cursor;
}

/// One simulated phone: own DB, repository and engine.
class Device {
  new(FakeSyncServer server, String name, FakeClock clock) : db = memoryDb() {
    final ids = _PrefixedIds(name);
    repo = NotesRepositoryImpl(db, clock, ids);
    labels = ColorLabelsRepositoryImpl(db, clock);
    engine = SyncEngine(
      api: server,
      store: SyncStore(db, conflictSuffix: ' (conflicted copy)'),
      cursor: MemoryCursor(),
      newId: ids.newId,
      batchSize: 2, // exercise batching
    );
  }

  final AppDatabase db;
  late final NotesRepositoryImpl repo;
  late final ColorLabelsRepositoryImpl labels;
  late final SyncEngine engine;

  Future<SyncReport> sync() => engine.run();

  Future<Map<String, String>> titles() async => {
    for (final n in await repo.allNotes()) n.id: n.title,
  };
}

class _PrefixedIds implements IdGenerator {
  new(this.prefix);

  final String prefix;
  var _n = 0;

  @override
  String newId() => '$prefix-${++_n}';
}

void main() {
  late FakeSyncServer server;
  late FakeClock clock;
  late Device a;
  late Device b;

  setUp(() {
    server = FakeSyncServer();
    clock = FakeClock();
    a = Device(server, 'a', clock);
    b = Device(server, 'b', clock);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test(
    'offline notes upload on first sync; new device gets them (FR-B8/B9)',
    () async {
      for (final i in [1, 2, 3]) {
        await a.repo.save(textNote('n$i', title: 'Note $i'));
      }
      await a.labels.setLabel(NoteColor.red, 'Work');

      final first = await a.sync();
      expect(first.pushed, 4);
      expect(server.pushCalls, 2); // batchSize 2 → 4 records in 2 calls
      expect(server.notes.keys, unorderedEquals(['n1', 'n2', 'n3']));

      final second = await a.sync();
      expect(second.pushed, 0, reason: 'nothing dirty after a clean sync');

      await b.sync();
      expect(await b.titles(), {
        'n1': 'Note 1',
        'n2': 'Note 2',
        'n3': 'Note 3',
      });
      expect(await b.labels.getLabels(), {NoteColor.red: 'Work'});
    },
  );

  test('edits flow between devices', () async {
    await a.repo.save(textNote('n1', title: 'v1'));
    await a.sync();
    await b.sync();

    clock.advance(const Duration(minutes: 1));
    final onB = (await b.repo.getNote('n1'))!;
    await b.repo.save(onB.copyWith(title: 'edited on B'));
    await b.sync();
    await a.sync();
    expect((await a.repo.getNote('n1'))!.title, 'edited on B');
  });

  test(
    'concurrent edits: both versions survive as a conflicted copy',
    () async {
      await a.repo.save(textNote('n1', title: 'base'));
      await a.sync();
      await b.sync();

      await a.repo.save(
        (await a.repo.getNote('n1'))!.copyWith(title: 'A wins race'),
      );
      await b.repo.save(
        (await b.repo.getNote('n1'))!.copyWith(title: 'B offline'),
      );
      await a.sync();
      final report = await b.sync();
      expect(report.conflicts, 1);

      final onB = await b.titles();
      expect(onB['n1'], 'A wins race');
      expect(onB.values, contains('B offline (conflicted copy)'));

      await b.sync(); // upload the copy
      await a.sync();
      expect((await a.titles()).values.toSet(), {
        'A wins race',
        'B offline (conflicted copy)',
      });
    },
  );

  test('only personal fields differ: no conflicted copy', () async {
    await a.repo.save(textNote('n1', title: 'same'));
    await a.sync();
    await b.sync();
    await a.repo.setPinned(['n1'], pinned: true);
    await b.repo.setColor(['n1'], NoteColor.blue);
    await a.sync();
    await b.sync();
    expect((await b.repo.allNotes()).length, 1);
    await b.sync(); // rebased change goes up
    await a.sync();
    expect((await a.repo.getNote('n1'))!.color, NoteColor.blue);
  });

  test('delete forever reaches other devices via a purged tombstone', () async {
    await a.repo.save(textNote('n1', title: 'secret'));
    await a.sync();
    await b.sync();

    await a.repo.moveToTrash(['n1']);
    await a.repo.deleteForever(['n1']);
    expect(await a.repo.allNotes(), isEmpty, reason: 'hidden immediately');
    await a.sync();
    expect(
      await a.db.select(a.db.notes).get(),
      isEmpty,
      reason: 'tombstone removed after push',
    );
    expect(
      server.notes['n1']!.data['title'],
      '',
      reason: 'content wiped on server',
    );

    await b.sync();
    expect(await b.repo.allNotes(), isEmpty);
  });

  test('never-synced notes are deleted outright', () async {
    await a.repo.save(textNote('local', title: 'x'));
    await a.repo.deleteForever(['local']);
    expect(await a.db.select(a.db.notes).get(), isEmpty);
  });

  test('an edit during the push request stays dirty', () async {
    await a.repo.save(textNote('n1', title: 'first'));
    server.duringPush = () async {
      server.duringPush = null;
      clock.advance(const Duration(seconds: 1));
      await a.repo.save(
        (await a.repo.getNote('n1'))!.copyWith(title: 'second'),
      );
    };
    await a.sync();
    expect(server.notes['n1']!.data['title'], 'first');
    await a.sync();
    expect(server.notes['n1']!.data['title'], 'second');
  });

  test('pull pages through a long feed', () async {
    for (var i = 0; i < 7; i++) {
      await a.repo.save(textNote('n$i', title: '$i'));
    }
    await a.sync();
    // Reading with tiny pages must still deliver everything.
    final engine = SyncEngine(
      api: _TinyPages(server),
      store: SyncStore(b.db, conflictSuffix: ' (c)'),
      cursor: MemoryCursor(),
      newId: SeqIds().newId,
    );
    final report = await engine.run();
    expect(report.pulled, 7);
    expect((await b.repo.allNotes()).length, 7);
  });
}

class _TinyPages extends FakeSyncServer {
  new(this.inner);

  final FakeSyncServer inner;

  @override
  Future<PullPage> pull(int cursor, {int limit = 500}) =>
      inner.pull(cursor, limit: 3);
}

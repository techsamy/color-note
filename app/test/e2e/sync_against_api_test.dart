// Real HTTP against a running Laravel API. Skipped unless HUENOTE_E2E_API
// is set, e.g.:
//   (cd api && php artisan serve --port=8001) &
//   HUENOTE_E2E_API=http://127.0.0.1:8001/api/v1 flutter test test/e2e
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/network/api_client.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/auth/data/auth_api.dart';
import 'package:huenote/features/notes/data/notes_repository_impl.dart';
import 'package:huenote/features/sync/data/http_sync_api.dart';
import 'package:huenote/features/sync/data/sync_store.dart';
import 'package:huenote/features/sync/domain/sync_engine.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

final _base = Platform.environment['HUENOTE_E2E_API'];

class _Cursor implements CursorStore {
  int v = 0;

  @override
  Future<int> read() async => v;

  @override
  Future<void> write(int cursor) async => v = cursor;
}

class _Phone {
  new(this.deviceId) : db = memoryDb();

  final String deviceId;
  final AppDatabase db;
  final clock = FakeClock(DateTime.now().toUtc());
  String? token;

  ApiClient get api => ApiClient(
    baseUrl: _base!,
    token: () async => token,
    deviceId: deviceId,
    appVersion: '0.1.0',
  );

  late final repo = NotesRepositoryImpl(db, clock, _UuidIds());

  SyncEngine get engine => SyncEngine(
    api: HttpSyncApi(api),
    store: SyncStore(db, conflictSuffix: ' (conflicted copy)'),
    cursor: cursor,
    newId: const Uuid().v7,
  );

  final cursor = _Cursor();
}

class _UuidIds implements IdGenerator {
  @override
  String newId() => const Uuid().v7();
}

void main() {
  test('two phones, one account: upload, restore, conflict, delete', () async {
    final email = 'e2e-${DateTime.now().millisecondsSinceEpoch}@example.com';
    final a = _Phone(const Uuid().v7());
    final b = _Phone(const Uuid().v7());
    addTearDown(() async {
      await a.db.close();
      await b.db.close();
    });

    // Phone A: offline notes, then create an account (FR-B8).
    await a.repo.save(
      textNote(const Uuid().v7(), title: 'Groceries', text: 'milk'),
    );
    await a.repo.save(textNote(const Uuid().v7(), title: 'Ideas'));
    final signUp = await AuthApi(
      a.api,
      deviceId: a.deviceId,
    ).register(email, 'secret123');
    a.token = signUp.token;
    expect((await a.engine.run()).pushed, 2);

    // Phone B: sign in → everything arrives (FR-B9).
    b.token = (await AuthApi(
      b.api,
      deviceId: b.deviceId,
    ).login(email, 'secret123')).token;
    await b.engine.run();
    final onB = await b.repo.allNotes();
    expect(onB.map((n) => n.title), unorderedEquals(['Groceries', 'Ideas']));

    // Concurrent edits → conflicted copy, nothing lost (FR-B4).
    final id = onB.firstWhere((n) => n.title == 'Groceries').id;
    a.clock.advance(const Duration(seconds: 1));
    b.clock.advance(const Duration(seconds: 2));
    await a.repo.save((await a.repo.getNote(id))!.copyWith(text: 'milk, eggs'));
    await b.repo.save(
      (await b.repo.getNote(id))!.copyWith(text: 'milk, bread'),
    );
    await a.engine.run();
    expect((await b.engine.run()).conflicts, 1);
    await b.engine.run();
    await a.engine.run();
    final texts = (await a.repo.allNotes()).map((n) => n.text).toSet();
    expect(texts, containsAll(['milk, eggs', 'milk, bread']));

    // Delete forever on A → gone on B.
    await a.repo.deleteForever([id]);
    await a.engine.run();
    await b.engine.run();
    expect(await b.repo.getNote(id), isNull);

    // Clean up the test account.
    await AuthApi(
      a.api,
      deviceId: a.deviceId,
    ).deleteAccount(password: 'secret123');
  }, skip: _base == null ? 'set HUENOTE_E2E_API to run' : false);
}

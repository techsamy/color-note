import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/features/backup/backup_controller.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

/// A simulated device: own DB, prefs and secure storage.
Future<ProviderContainer> device() async {
  SharedPreferences.setMockInitialValues({});
  final db = memoryDb();
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      secureStoreProvider.overrideWithValue(InMemorySecureStore()),
      cryptoServiceProvider.overrideWithValue(fastCrypto()),
    ],
  );
  addTearDown(() async {
    c.dispose();
    await db.close();
  });
  return c;
}

void main() {
  late ProviderContainer a;

  setUp(() async {
    a = await device();
    final lock = a.read(lockControllerProvider.notifier);
    await a.read(lockControllerProvider.future);
    await lock.setUp('device-a-pw');
    final repo = a.read(notesRepositoryProvider);
    await repo.save(textNote('plain', title: 'Plain', text: 'hello'));
    await repo.save(
      await lock.seal(textNote('secret', title: 'Secret', text: 'shh')),
    );
    await a.read(colorLabelsRepositoryProvider).setLabel(NoteColor.red, 'Work');
  });

  Future<RestoreOutcome> restoreInto(
    ProviderContainer target, {
    String? oldMasterPassword,
  }) async {
    final bytes = await a.read(backupControllerProvider).createBackup('bk-pw');
    final ctrl = target.read(backupControllerProvider);
    final contents = await ctrl.open(bytes, 'bk-pw');
    return await ctrl.restore(
      contents,
      backupMasterPassword: oldMasterPassword,
    );
  }

  test(
    'fresh device adopts the backup key; old master password works',
    () async {
      final b = await device();
      final outcome = await restoreInto(b);
      expect(outcome, isA<RestoreDone>());
      expect((outcome as RestoreDone).result.added, 2);
      expect(await b.read(colorLabelsRepositoryProvider).getLabels(), {
        NoteColor.red: 'Work',
      });

      final lock = b.read(lockControllerProvider.notifier);
      expect(await lock.unlock('device-a-pw'), isTrue);
      final sealed = await b.read(notesRepositoryProvider).getNote('secret');
      expect((await lock.unseal(sealed!)).text, 'shh');
    },
  );

  test('device with its own master password re-keys locked notes', () async {
    final b = await device();
    final lock = b.read(lockControllerProvider.notifier);
    await b.read(lockControllerProvider.future);
    await lock.setUp('device-b-pw');

    expect(await restoreInto(b), isA<RestoreNeedsKeys>());
    expect(
      await restoreInto(b, oldMasterPassword: 'wrong'),
      isA<RestoreWrongMasterPassword>(),
    );
    expect(
      await restoreInto(b, oldMasterPassword: 'device-a-pw'),
      isA<RestoreDone>(),
    );

    // Now readable with B's own password only.
    lock.lock();
    expect(await lock.unlock('device-b-pw'), isTrue);
    final sealed = await b.read(notesRepositoryProvider).getNote('secret');
    expect((await lock.unseal(sealed!)).title, 'Secret');
  });

  test('restoring twice changes nothing the second time', () async {
    final b = await device();
    await restoreInto(b);
    final again = await restoreInto(b) as RestoreDone;
    expect(again.result.added, 0);
    expect(again.result.skipped, 2);
  });
}

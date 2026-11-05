import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/config/app_config.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/features/backup/data/backup_service.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/domain/notes_repository.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:huenote/features/settings/settings_providers.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(cryptoServiceProvider),
    appVersion: AppConfig.appVersion,
  ),
);

sealed class RestoreOutcome {
  const new();
}

final class RestoreDone extends RestoreOutcome {
  const new(this.result);

  final ImportResult result;
}

/// Backup has locked notes sealed with another device's key; the caller
/// must unlock this device AND supply the master password used there.
final class RestoreNeedsKeys extends RestoreOutcome {
  const new();
}

final class RestoreWrongMasterPassword extends RestoreOutcome {
  const new();
}

/// FR-B1 orchestration: gathers data for a backup and applies a restore,
/// re-keying locked notes when the backup came from another key.
class BackupController {
  new(this.ref);

  final Ref ref;

  Future<Uint8List> createBackup(String password) async {
    final lock = await ref.read(lockControllerProvider.future);
    return await ref
        .read(backupServiceProvider)
        .create(
          password: password,
          now: ref.read(clockProvider).now(),
          notes: await ref.read(notesRepositoryProvider).allNotes(),
          colorLabels: await ref
              .read(colorLabelsRepositoryProvider)
              .getLabels(),
          settings: ref.read(settingsProvider).toJson(),
          keyMaterial: lock.material,
        );
  }

  Future<BackupContents> open(Uint8List bytes, String password) =>
      ref.read(backupServiceProvider).open(bytes, password);

  Future<RestoreOutcome> restore(
    BackupContents contents, {
    String? backupMasterPassword,
  }) async {
    final lockCtrl = ref.read(lockControllerProvider.notifier);
    final lock = await ref.read(lockControllerProvider.future);
    final theirs = contents.keyMaterial;
    var notes = contents.notes;

    final foreignLocked =
        theirs != null &&
        contents.lockedCount > 0 &&
        lock.material?.keyId != theirs.keyId;
    if (foreignLocked) {
      if (!lock.hasMasterPassword) {
        // Fresh device: adopt the backup's key; old password keeps working.
        await lockCtrl.adoptMaterial(theirs);
      } else {
        if (backupMasterPassword == null || !lock.isUnlocked) {
          return const RestoreNeedsKeys();
        }
        final codec = ref.read(lockedNoteCodecProvider);
        final keys = ref.read(masterKeyServiceProvider);
        try {
          final theirDek = await keys.unlock(theirs, backupMasterPassword);
          notes = [
            for (final n in notes)
              if (n.isSealed && n.encrypted!.keyId == theirs.keyId)
                await lockCtrl.seal(await codec.unseal(n, theirDek))
              else
                n,
          ];
        } on WrongKeyException {
          return const RestoreWrongMasterPassword();
        }
      }
    }

    final result = await ref.read(notesRepositoryProvider).importNotes(notes);
    final labelsRepo = ref.read(colorLabelsRepositoryProvider);
    for (final e in contents.colorLabels.entries) {
      await labelsRepo.setLabel(e.key, e.value);
    }
    final settings = contents.settings;
    if (settings != null) {
      try {
        await ref
            .read(settingsProvider.notifier)
            .replace(AppSettings.fromJson(settings));
      } on Object {
        // Settings from another version: keep current ones.
      }
    }
    return RestoreDone(result);
  }
}

final backupControllerProvider = Provider<BackupController>(
  BackupController.new,
);

import 'package:huenote/features/sync/data/sync_store.dart';
import 'package:huenote/features/sync/domain/sync_api.dart';

/// Where the pull cursor is kept (per signed-in account).
abstract interface class CursorStore {
  Future<int> read();

  Future<void> write(int cursor);
}

enum KeyState {
  /// Keys agree (or there are none).
  ok,

  /// Account and device use different master keys; locked notes are held
  /// back until the user resolves it (docs/03 §3.4).
  mismatch,
}

final class SyncReport {
  const new({
    required this.pushed,
    required this.conflicts,
    required this.rejected,
    required this.pulled,
    required this.keyState,
  });

  final int pushed;
  final int conflicts;
  final int rejected;
  final int pulled;
  final KeyState keyState;
}

/// One sync run: reconcile keys, push dirty records, pull the feed.
/// Push first so our own edits are on the server before we pull.
class SyncEngine {
  new({
    required this.api,
    required this.store,
    required this.cursor,
    required this.newId,
    this.reconcileKeys,
    this.batchSize = 200,
  });

  final SyncApi api;
  final SyncStore store;
  final CursorStore cursor;
  final String Function() newId;
  final Future<KeyState> Function()? reconcileKeys;
  final int batchSize;

  Future<SyncReport> run() async {
    final keyState = await (reconcileKeys?.call() ?? Future.value(KeyState.ok));
    var pushed = 0;
    var conflicts = 0;
    var rejected = 0;
    final attempted = <String>{};

    while (true) {
      final batch = await store.outgoing(
        limit: batchSize,
        exclude: attempted,
        includeLocked: keyState == KeyState.ok,
      );
      if (batch.isEmpty) break;
      attempted.addAll(batch.map((o) => o.change.id));
      final results = await api.push([for (final o in batch) o.change]);
      for (final (i, r) in results.indexed) {
        final out = batch[i];
        switch (r.status) {
          case PushStatus.applied:
            pushed++;
            await store.markApplied(out, r.version!);
          case PushStatus.conflict:
            conflicts++;
            await store.resolveConflict(out, r.server!, newId);
          case PushStatus.rejected:
            // Stays dirty; retried next run (e.g. after an app update).
            rejected++;
        }
      }
      if (batch.length < batchSize) break;
    }

    var pulled = 0;
    var at = await cursor.read();
    while (true) {
      final page = await api.pull(at);
      for (final rec in page.changes) {
        await store.applyRemote(rec);
      }
      pulled += page.changes.length;
      at = page.nextCursor;
      await cursor.write(at);
      if (!page.hasMore) break;
    }

    return SyncReport(
      pushed: pushed,
      conflicts: conflicts,
      rejected: rejected,
      pulled: pulled,
      keyState: keyState,
    );
  }
}

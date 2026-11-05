import 'package:drift/drift.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/features/notes/data/fts_index.dart';
import 'package:huenote/features/notes/data/note_mapper.dart';
import 'package:huenote/features/sync/data/note_wire.dart';
import 'package:huenote/features/sync/domain/sync_api.dart';

/// A dirty local record plus the snapshot needed to settle its push result.
final class Outgoing {
  const new(this.change, {this.snapshotUpdatedAt});

  final WireChange change;

  /// Notes only: updated_at when read; edits after that keep `dirty`.
  final int? snapshotUpdatedAt;
}

/// All local DB work the sync engine needs (docs/03 §3.2-3.3).
class SyncStore {
  new(this._db, {required this.conflictSuffix});

  final AppDatabase _db;

  /// Appended to the title of a conflicted copy.
  final String conflictSuffix;

  Future<bool> hasDirty() async {
    final note =
        await (_db.select(_db.notes)
              ..where((n) => n.dirty)
              ..limit(1))
            .getSingleOrNull();
    if (note != null) return true;
    final label =
        await (_db.select(_db.colorLabels)
              ..where((l) => l.dirty)
              ..limit(1))
            .getSingleOrNull();
    return label != null;
  }

  Future<List<Outgoing>> outgoing({
    required int limit,
    required Set<String> exclude,
    required bool includeLocked,
  }) async {
    final notes =
        await (_db.select(_db.notes)
              ..where(
                (n) =>
                    n.dirty &
                    n.id.isNotIn(exclude) &
                    (includeLocked ? const Constant(true) : n.isLocked.not()),
              )
              ..orderBy([(n) => OrderingTerm.asc(n.updatedAt)])
              ..limit(limit))
            .get();
    final labels = notes.length < limit
        ? await (_db.select(_db.colorLabels)..where(
                (l) =>
                    l.dirty &
                    l.color.isNotIn(exclude.map(int.tryParse).nonNulls),
              ))
              .get()
        : const <ColorLabelRow>[];
    return [
      for (final n in notes)
        Outgoing(
          WireChange(
            entity: 'note',
            id: n.id,
            baseVersion: n.baseVersion,
            data: NoteWire.toData(n),
          ),
          snapshotUpdatedAt: n.updatedAt,
        ),
      for (final l in labels)
        Outgoing(
          WireChange(
            entity: 'color_label',
            id: '${l.color}',
            baseVersion: l.baseVersion,
            data: {'label': l.label},
          ),
        ),
    ];
  }

  Future<void> markApplied(Outgoing out, int version) => _db.transaction(
    () async {
      final c = out.change;
      if (c.entity == 'color_label') {
        await (_db.update(
          _db.colorLabels,
        )..where((l) => l.color.equals(int.parse(c.id)))).write(
          ColorLabelsCompanion(
            baseVersion: Value(version),
            dirty: const Value(false),
          ),
        );
        return;
      }
      await (_db.update(_db.notes)..where((n) => n.id.equals(c.id))).write(
        NotesCompanion(baseVersion: Value(version)),
      );
      // Only clean if not edited while the request was in flight.
      await (_db.update(_db.notes)..where(
            (n) =>
                n.id.equals(c.id) & n.updatedAt.equals(out.snapshotUpdatedAt!),
          ))
          .write(const NotesCompanion(dirty: Value(false)));
      // A confirmed purge tombstone has done its job.
      await (_db.delete(
        _db.notes,
      )..where((n) => n.id.equals(c.id) & n.purged & n.dirty.not())).go();
    },
  );

  /// Server has a different version: keep the server copy under this id and
  /// the local edits as a new "conflicted copy" note. Nothing is lost.
  Future<void> resolveConflict(
    Outgoing out,
    WireRecord server,
    String Function() newId,
  ) => _db.transaction(() async {
    final c = out.change;
    if (c.entity == 'color_label') {
      // Labels: server wins (tiny, low value).
      await _applyLabel(server, force: true);
      return;
    }
    final local = await _row(c.id);
    if (local == null) return;
    final s = server.data;
    final sameContent =
        s['type'] == local.type &&
        (s['title'] ?? '') == local.title &&
        (s['body'] ?? '') == local.body &&
        s['is_locked'] == local.isLocked &&
        s['purged'] != true;
    if (sameContent) {
      // Only personal fields differ: rebase local fields on the server version.
      await (_db.update(_db.notes)..where((n) => n.id.equals(c.id))).write(
        NotesCompanion(baseVersion: Value(server.version)),
      );
      return;
    }
    if (!local.purged) {
      final copyId = newId();
      final copy = local.copyWith(
        id: copyId,
        title: local.isLocked || local.title.isEmpty
            ? local.title
            : '${local.title}$conflictSuffix',
        baseVersion: 0,
        dirty: true,
      );
      await _db.into(_db.notes).insert(copy);
      await FtsIndex.reindex(_db, NoteMapper.fromRow(copy));
    }
    await _applyNote(server, force: true);
  });

  /// Applies a pulled change unless local edits are pending (those will
  /// meet the server version on the next push and conflict properly).
  Future<void> applyRemote(WireRecord rec) => _db.transaction(() async {
    switch (rec.entity) {
      case 'note':
        await _applyNote(rec);
      case 'color_label':
        await _applyLabel(rec);
    }
  });

  Future<void> _applyNote(WireRecord rec, {bool force = false}) async {
    final local = await _row(rec.id);
    if (!force &&
        local != null &&
        (local.dirty || local.baseVersion >= rec.version)) {
      return;
    }
    if (rec.data['purged'] == true) {
      await (_db.delete(_db.notes)..where((n) => n.id.equals(rec.id))).go();
      await FtsIndex.remove(_db, rec.id);
      return;
    }
    final companion = NoteWire.fromData(rec.id, rec.version, rec.data);
    await _db.into(_db.notes).insertOnConflictUpdate(companion);
    final row = await _row(rec.id);
    if (row != null) await FtsIndex.reindex(_db, NoteMapper.fromRow(row));
  }

  Future<void> _applyLabel(WireRecord rec, {bool force = false}) async {
    final color = int.parse(rec.id);
    final local = await (_db.select(
      _db.colorLabels,
    )..where((l) => l.color.equals(color))).getSingleOrNull();
    if (!force &&
        local != null &&
        (local.dirty || local.baseVersion >= rec.version)) {
      return;
    }
    await _db
        .into(_db.colorLabels)
        .insertOnConflictUpdate(
          ColorLabelsCompanion.insert(
            color: Value(color),
            label: rec.data['label'] as String? ?? '',
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            baseVersion: Value(rec.version),
            dirty: const Value(false),
          ),
        );
  }

  Future<NoteRow?> _row(String id) =>
      (_db.select(_db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  /// Signing into a different account: local notes become brand-new notes
  /// of that account (new ids so they can't collide with the old account).
  Future<void> detachForNewAccount(String Function() newId) =>
      _db.transaction(() async {
        await (_db.delete(_db.notes)..where((n) => n.purged)).go();
        final rows = await _db.select(_db.notes).get();
        for (final r in rows) {
          await (_db.delete(_db.notes)..where((n) => n.id.equals(r.id))).go();
          await FtsIndex.remove(_db, r.id);
          final moved = r.copyWith(id: newId(), baseVersion: 0, dirty: true);
          await _db.into(_db.notes).insert(moved);
          await FtsIndex.reindex(_db, NoteMapper.fromRow(moved));
        }
        await _db
            .update(_db.colorLabels)
            .write(
              const ColorLabelsCompanion(
                baseVersion: Value(0),
                dirty: Value(true),
              ),
            );
      });

  /// Account deleted: keep notes as plain offline notes.
  Future<void> detachKeepingIds() => _db.transaction(() async {
    await (_db.delete(_db.notes)..where((n) => n.purged)).go();
    await _db
        .update(_db.notes)
        .write(const NotesCompanion(baseVersion: Value(0), dirty: Value(true)));
    await _db
        .update(_db.colorLabels)
        .write(
          const ColorLabelsCompanion(baseVersion: Value(0), dirty: Value(true)),
        );
  });

  /// Sign out with "remove notes from this device".
  Future<void> wipe() => _db.transaction(() async {
    await _db.delete(_db.notes).go();
    await _db.delete(_db.colorLabels).go();
    await _db.customStatement('DELETE FROM notes_fts');
  });
}

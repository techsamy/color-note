import 'package:huenote/features/sync/domain/sync_api.dart';

/// In-memory stand-in for the Laravel sync API (single account), with the
/// same rules as api/app/Services/SyncService.php.
class FakeSyncServer implements SyncApi, KeysApi {
  final notes = <String, ({int version, Map<String, dynamic> data})>{};
  final labels = <String, ({int version, String label})>{};
  final _feed = <({int seq, String entity, String id})>[];
  RemoteKeys? keys;
  int pushCalls = 0;

  /// Runs inside push, before results return (simulate concurrent edits).
  Future<void> Function()? duringPush;

  void _append(String entity, String id) =>
      _feed.add((seq: _feed.length + 1, entity: entity, id: id));

  @override
  Future<List<PushResult>> push(List<WireChange> changes) async {
    pushCalls++;
    final results = <PushResult>[];
    for (final c in changes) {
      if (c.entity == 'color_label') {
        final cur = labels[c.id];
        final v = cur?.version ?? 0;
        if (v != c.baseVersion) {
          results.add(
            PushResult(
              id: c.id,
              status: PushStatus.conflict,
              server: _label(c.id),
            ),
          );
          continue;
        }
        labels[c.id] = (version: v + 1, label: c.data['label'] as String);
        _append('color_label', c.id);
        results.add(
          PushResult(id: c.id, status: PushStatus.applied, version: v + 1),
        );
        continue;
      }
      final cur = notes[c.id];
      if (cur == null) {
        notes[c.id] = (version: 1, data: _clean(c.data));
        _append('note', c.id);
        results.add(
          PushResult(id: c.id, status: PushStatus.applied, version: 1),
        );
      } else if (cur.data['purged'] == true || cur.version != c.baseVersion) {
        results.add(
          PushResult(
            id: c.id,
            status: PushStatus.conflict,
            server: _note(c.id),
          ),
        );
      } else {
        notes[c.id] = (version: cur.version + 1, data: _clean(c.data));
        _append('note', c.id);
        results.add(
          PushResult(
            id: c.id,
            status: PushStatus.applied,
            version: cur.version + 1,
          ),
        );
      }
    }
    await duringPush?.call();
    return results;
  }

  Map<String, dynamic> _clean(Map<String, dynamic> d) => d['purged'] == true
      ? {...d, 'title': '', 'body': '', 'is_locked': false, 'crypto_meta': null}
      : {...d};

  WireRecord _note(String id) => WireRecord(
    entity: 'note',
    id: id,
    version: notes[id]!.version,
    data: notes[id]!.data,
  );

  WireRecord _label(String id) => WireRecord(
    entity: 'color_label',
    id: id,
    version: labels[id]?.version ?? 0,
    data: {'label': labels[id]?.label ?? ''},
  );

  @override
  Future<PullPage> pull(int cursor, {int limit = 500}) async {
    final rows = _feed.where((f) => f.seq > cursor).toList();
    final page = rows.take(limit).toList();
    final latest = <String, ({int seq, String entity, String id})>{};
    for (final r in page) {
      latest.remove('${r.entity}:${r.id}');
      latest['${r.entity}:${r.id}'] = r;
    }
    return PullPage(
      changes: [
        for (final r in latest.values)
          if (r.entity == 'note') _note(r.id) else _label(r.id),
      ],
      nextCursor: page.isEmpty ? cursor : page.last.seq,
      hasMore: rows.length > limit,
    );
  }

  @override
  Future<RemoteKeys?> getKeys() async => keys;

  @override
  Future<int> putKeys(
    Map<String, dynamic> material,
    int expectedVersion,
  ) async {
    final current = keys?.version ?? 0;
    if (current != expectedVersion) throw const KeyVersionConflict();
    keys = RemoteKeys(material: material, version: current + 1);
    return current + 1;
  }
}

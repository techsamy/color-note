import 'package:huenote/core/network/api_client.dart';
import 'package:huenote/features/sync/domain/sync_api.dart';

final class HttpSyncApi implements SyncApi, KeysApi {
  new(this._api);

  final ApiClient _api;

  @override
  Future<List<PushResult>> push(List<WireChange> changes) async {
    final res = await _api.post('/sync/push', {
      'changes': [for (final c in changes) c.toJson()],
    });
    final results =
        (res['data'] as Map<String, dynamic>)['results'] as List<dynamic>;
    return [
      for (final r in results) PushResult.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<PullPage> pull(int cursor, {int limit = 500}) async {
    final res = await _api.get(
      '/sync/pull',
      query: {'cursor': cursor, 'limit': limit},
    );
    final data = res['data'] as Map<String, dynamic>;
    final meta = res['meta'] as Map<String, dynamic>;
    return PullPage(
      changes: [
        for (final c in data['changes'] as List<dynamic>)
          WireRecord.fromJson(c as Map<String, dynamic>),
      ],
      nextCursor: meta['next_cursor'] as int,
      hasMore: meta['has_more'] as bool,
    );
  }

  @override
  Future<RemoteKeys?> getKeys() async {
    try {
      final res = await _api.get('/me/keys');
      final data = res['data'] as Map<String, dynamic>;
      return RemoteKeys(
        material: (data['key_material'] as Map).cast<String, dynamic>(),
        version: data['key_version'] as int,
      );
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<int> putKeys(
    Map<String, dynamic> material,
    int expectedVersion,
  ) async {
    try {
      final res = await _api.put('/me/keys', {
        'key_material': material,
        'expected_key_version': expectedVersion,
      });
      return (res['data'] as Map<String, dynamic>)['key_version'] as int;
    } on ApiException catch (e) {
      if (e.status == 409) throw const KeyVersionConflict();
      rethrow;
    }
  }
}

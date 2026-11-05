/// Wire types for /sync and /me/keys (docs/05 §4). Kept free of HTTP so
/// the engine can run against a fake server in tests.
final class WireChange {
  const new({
    required this.entity,
    required this.id,
    required this.baseVersion,
    required this.data,
  });

  final String entity;
  final String id;
  final int baseVersion;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'id': id,
    'base_version': baseVersion,
    'data': data,
  };
}

final class WireRecord {
  const new({
    required this.entity,
    required this.id,
    required this.version,
    required this.data,
  });

  factory fromJson(Map<String, dynamic> j) => WireRecord(
    entity: j['entity'] as String,
    id: j['id'] as String,
    version: j['version'] as int,
    data: (j['data'] as Map).cast<String, dynamic>(),
  );

  final String entity;
  final String id;
  final int version;
  final Map<String, dynamic> data;
}

enum PushStatus { applied, conflict, rejected }

final class PushResult {
  const new({
    required this.id,
    required this.status,
    this.version,
    this.server,
    this.errorCode,
  });

  factory fromJson(Map<String, dynamic> j) {
    final server = j['server'];
    final error = j['error'];
    return PushResult(
      id: j['id'] as String,
      status: PushStatus.values.byName(j['status'] as String),
      version: j['version'] as int?,
      server: server is Map<String, dynamic>
          ? WireRecord.fromJson(server)
          : null,
      errorCode: error is Map<String, dynamic>
          ? error['code'] as String?
          : null,
    );
  }

  final String id;
  final PushStatus status;
  final int? version;
  final WireRecord? server;
  final String? errorCode;
}

final class PullPage {
  const new({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<WireRecord> changes;
  final int nextCursor;
  final bool hasMore;
}

abstract interface class SyncApi {
  /// Results are per record, in request order.
  Future<List<PushResult>> push(List<WireChange> changes);

  Future<PullPage> pull(int cursor, {int limit = 500});
}

final class RemoteKeys {
  const new({required this.material, required this.version});

  final Map<String, dynamic> material;
  final int version;
}

final class KeyVersionConflict implements Exception {
  const new();
}

abstract interface class KeysApi {
  /// Null when the account has no master key yet.
  Future<RemoteKeys?> getKeys();

  /// Returns the new version. Throws [KeyVersionConflict] on 409.
  Future<int> putKeys(Map<String, dynamic> material, int expectedVersion);
}

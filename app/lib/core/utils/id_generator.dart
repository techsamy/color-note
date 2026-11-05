import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Client-generated IDs: UUID v7 (time-sortable, safe offline). See ADR 0002.
abstract interface class IdGenerator {
  String newId();
}

final class UuidV7Generator implements IdGenerator {
  const new();

  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v7();
}

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidV7Generator(),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable time source so tests are deterministic. Always UTC.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const new();

  @override
  DateTime now() => DateTime.now().toUtc();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());

extension EpochMs on DateTime {
  /// Note timestamps are stored and synced as UTC epoch milliseconds.
  int get epochMs => toUtc().millisecondsSinceEpoch;
}

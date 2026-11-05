import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Local SQLite database — the UI's source of truth (ADR 0002).
///
/// Tables are added per feature (notes in Phase 1). Every schema change:
/// bump [schemaVersion], add a migration step, add a migration test.
@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  new([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'huenote',
              // Web (dev preview in Brave): files in web/ must match the
              // drift + sqlite3 package versions — see app/README.md.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

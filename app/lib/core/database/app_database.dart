import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/core/database/tables/notes_table.dart';

part 'app_database.g.dart';

/// Local SQLite database — the UI's source of truth (ADR 0002).
///
/// v1: first schema. v2: notes.purged (sync tombstones).
/// Every later change: bump
/// [schemaVersion], add a step in [migration], run
/// `dart run drift_dev make-migrations`, and add a migration test.
@DriftDatabase(
  tables: [Notes, ColorLabels],
  include: {'tables/notes_fts.drift'},
)
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(notes, notes.purged);
    },
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

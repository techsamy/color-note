import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/database/app_database.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/core/utils/id_generator.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

final class FakeClock implements Clock {
  new([DateTime? start]) : _now = start ?? DateTime.utc(2026, 11, 5, 10);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

final class SeqIds implements IdGenerator {
  var _n = 0;

  @override
  String newId() => 'id-${++_n}';
}

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Cheap KDF settings so tests run fast. Never use outside tests.
CryptoService fastCrypto() => CryptoService(memoryKib: 64, iterations: 1);

Note textNote(
  String id, {
  String title = '',
  String text = '',
  NoteColor color = NoteColor.yellow,
  DateTime? at,
}) {
  final t = at ?? DateTime.utc(2026, 11, 5, 10);
  return Note(
    id: id,
    type: NoteType.text,
    title: title,
    text: text,
    color: color,
    createdAt: t,
    updatedAt: t,
  );
}

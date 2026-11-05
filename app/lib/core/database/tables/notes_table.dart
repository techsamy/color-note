import 'package:drift/drift.dart';

/// Schema per docs/04-data-model.md §2. Reminder / calendar / sync columns
/// exist now so later phases don't need a migration for them.
@DataClassName('NoteRow')
@TableIndex(
  name: 'idx_notes_list',
  columns: {#deletedAt, #isArchived, #isPinned, #updatedAt},
)
@TableIndex(name: 'idx_notes_color', columns: {#color})
@TableIndex(name: 'idx_notes_reminder', columns: {#reminderAt})
class Notes extends Table {
  TextColumn get id => text()();
  IntColumn get type => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  IntColumn get color => integer()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get cryptoMeta => text().nullable()();
  IntColumn get reminderAt => integer().nullable()();
  TextColumn get reminderRule => text().nullable()();
  BoolColumn get reminderAllDay =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get statusBarPinned =>
      boolean().withDefault(const Constant(false))();
  TextColumn get calendarDate => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get baseVersion => integer().withDefault(const Constant(0))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  TextColumn get ownerUserUuid => text().nullable()();
  IntColumn get myPermission => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ColorLabelRow')
class ColorLabels extends Table {
  IntColumn get color => integer()();
  TextColumn get label => text()();
  IntColumn get updatedAt => integer()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  IntColumn get baseVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {color};
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:huenote/core/database/app_database.dart';

/// Local row <-> API flat note object (docs/05 §4). Body is sent exactly as
/// stored (text, checklist JSON, or ciphertext for locked notes).
abstract final class NoteWire {
  static Map<String, dynamic> toData(NoteRow r) => {
    'type': r.type,
    'title': r.title,
    'body': r.body,
    'color': r.color,
    'is_pinned': r.isPinned,
    'is_archived': r.isArchived,
    'is_locked': r.isLocked,
    'crypto_meta': _decode(r.cryptoMeta),
    'reminder_at': r.reminderAt,
    'reminder_rule': _decode(r.reminderRule),
    'reminder_all_day': r.reminderAllDay,
    'status_bar_pinned': r.statusBarPinned,
    'calendar_date': r.calendarDate,
    'created_at': r.createdAt,
    'updated_at': r.updatedAt,
    'deleted_at': r.deletedAt,
    'purged': r.purged,
  };

  static NotesCompanion fromData(
    String id,
    int version,
    Map<String, dynamic> d,
  ) => NotesCompanion(
    id: Value(id),
    type: Value(d['type'] as int),
    title: Value(d['title'] as String? ?? ''),
    body: Value(d['body'] as String? ?? ''),
    color: Value(d['color'] as int),
    isPinned: Value(d['is_pinned'] as bool? ?? false),
    isArchived: Value(d['is_archived'] as bool? ?? false),
    isLocked: Value(d['is_locked'] as bool? ?? false),
    cryptoMeta: Value(_encode(d['crypto_meta'])),
    reminderAt: Value(d['reminder_at'] as int?),
    reminderRule: Value(_encode(d['reminder_rule'])),
    reminderAllDay: Value(d['reminder_all_day'] as bool? ?? false),
    statusBarPinned: Value(d['status_bar_pinned'] as bool? ?? false),
    calendarDate: Value(d['calendar_date'] as String?),
    createdAt: Value(d['created_at'] as int),
    updatedAt: Value(d['updated_at'] as int),
    deletedAt: Value(d['deleted_at'] as int?),
    purged: Value(d['purged'] as bool? ?? false),
    baseVersion: Value(version),
    dirty: const Value(false),
  );

  static Object? _decode(String? json) =>
      json == null ? null : jsonDecode(json);

  static String? _encode(Object? value) =>
      value == null ? null : jsonEncode(value);
}

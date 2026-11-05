import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum AppThemeMode { system, light, dark }

enum NoteFontSize {
  small(0.9),
  medium(1),
  large(1.15),
  extraLarge(1.3);

  new(this.scale);

  final double scale;
}

/// FR-W2. Stored as JSON in shared_preferences (not sensitive).
@freezed
abstract class AppSettings with _$AppSettings {
  const factory({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(NoteFontSize.medium) NoteFontSize fontSize,
    @Default(NoteColor.yellow) NoteColor defaultColor,
    @Default(NoteSort.modified) NoteSort sort,
    @Default(NoteViewMode.list) NoteViewMode viewMode,
    @Default(true) bool checkedToBottom,

    /// 0 = keep forever.
    @Default(30) int trashRetentionDays,

    /// Relock locked notes after this long in background (FR-S3).
    @Default(5) int autoRelockMinutes,
  }) = _AppSettings;

  factory fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}

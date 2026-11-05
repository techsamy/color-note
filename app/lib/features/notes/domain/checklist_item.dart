import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_item.freezed.dart';
part 'checklist_item.g.dart';

@freezed
abstract class ChecklistItem with _$ChecklistItem {
  const factory({
    required String id,
    @Default('') String text,
    @Default(false) bool checked,
  }) = _ChecklistItem;

  factory fromJson(Map<String, dynamic> json) => _$ChecklistItemFromJson(json);
}

import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

/// Pure checklist / conversion rules (FR-N2, FR-N3). No I/O.
extension ChecklistOps on Note {
  /// Text -> checklist: every non-empty line becomes an item.
  /// Checklist -> text: item texts joined by newlines.
  Note convertTo(NoteType target, String Function() newId) {
    if (target == type) return this;
    return switch (target) {
      NoteType.checklist => copyWith(
        type: NoteType.checklist,
        items: [
          for (final line in text.split('\n'))
            if (line.trim().isNotEmpty)
              ChecklistItem(id: newId(), text: line.trim()),
        ],
        text: '',
      ),
      NoteType.text => copyWith(
        type: NoteType.text,
        text: items.map((i) => i.text).join('\n'),
        items: const [],
      ),
    };
  }

  Note updateItem(String itemId, ChecklistItem Function(ChecklistItem) f) =>
      copyWith(
        items: [
          for (final i in items)
            if (i.id == itemId) f(i) else i,
        ],
      );

  Note toggleItem(String itemId) =>
      updateItem(itemId, (i) => i.copyWith(checked: !i.checked));

  Note insertItemAfter(String? afterId, ChecklistItem item) {
    final index = afterId == null
        ? items.length
        : items.indexWhere((i) => i.id == afterId) + 1;
    final list = [...items]..insert(index.clamp(0, items.length), item);
    return copyWith(items: list);
  }

  Note removeItem(String itemId) =>
      copyWith(items: items.where((i) => i.id != itemId).toList());

  /// Moves an item from [oldIndex] to [newIndex] within [items].
  Note reorderItem(int oldIndex, int newIndex) {
    final list = [...items];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), item);
    return copyWith(items: list);
  }

  Note uncheckAll() =>
      copyWith(items: [for (final i in items) i.copyWith(checked: false)]);

  Note removeChecked() =>
      copyWith(items: items.where((i) => !i.checked).toList());
}

/// Unchecked first, then checked — each keeping their relative order.
List<ChecklistItem> checkedToBottom(List<ChecklistItem> items) => [
  ...items.where((i) => !i.checked),
  ...items.where((i) => i.checked),
];

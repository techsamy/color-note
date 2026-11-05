import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/checklist_ops.dart';
import 'package:huenote/features/notes/domain/note_type.dart';

import '../../../helpers/fakes.dart';

void main() {
  final ids = SeqIds();

  test('text -> checklist: one item per non-empty line (FR-N3)', () {
    final n = textNote(
      'a',
      text: 'milk\n\n  eggs  \nbread',
    ).convertTo(NoteType.checklist, ids.newId);
    expect(n.type, NoteType.checklist);
    expect(n.items.map((i) => i.text), ['milk', 'eggs', 'bread']);
    expect(n.text, isEmpty);
  });

  test('checklist -> text joins items', () {
    final n = textNote('a', text: 'a\nb')
        .convertTo(NoteType.checklist, ids.newId)
        .convertTo(NoteType.text, ids.newId);
    expect(n.text, 'a\nb');
    expect(n.items, isEmpty);
  });

  test('item operations', () {
    var n = textNote('a').copyWith(
      type: NoteType.checklist,
      items: const [
        ChecklistItem(id: '1', text: 'one'),
        ChecklistItem(id: '2', text: 'two'),
      ],
    );
    n = n.toggleItem('1');
    expect(n.items.first.checked, isTrue);
    n = n.insertItemAfter('1', const ChecklistItem(id: '3', text: 'x'));
    expect(n.items.map((i) => i.id), ['1', '3', '2']);
    n = n.reorderItem(2, 0);
    expect(n.items.map((i) => i.id), ['2', '1', '3']);
    n = n.removeItem('3');
    expect(n.items.map((i) => i.id), ['2', '1']);
    expect(checkedToBottom(n.items).map((i) => i.id), ['2', '1']);
    expect(n.uncheckAll().items.every((i) => !i.checked), isTrue);
    expect(n.removeChecked().items.map((i) => i.id), ['2']);
  });

  test('isEmpty ignores whitespace and blank checklist items', () {
    expect(textNote('a', text: '  \n').isEmpty, isTrue);
    expect(textNote('a', title: 'x').isEmpty, isFalse);
    final blank = textNote('a').copyWith(
      type: NoteType.checklist,
      items: const [ChecklistItem(id: '1', text: ' ')],
    );
    expect(blank.isEmpty, isTrue);
  });
}

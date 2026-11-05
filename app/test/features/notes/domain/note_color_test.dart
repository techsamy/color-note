import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/features/notes/domain/note_color.dart';

void main() {
  test('persisted colour values never change', () {
    // If this fails you are breaking every user's stored + synced notes.
    expect(
      {for (final c in NoteColor.values) c.name: c.value},
      {
        'red': 0,
        'orange': 1,
        'yellow': 2,
        'green': 3,
        'blue': 4,
        'purple': 5,
        'black': 6,
        'grey': 7,
        'white': 8,
      },
    );
  });

  test('fromValue round-trips and falls back for unknown values', () {
    for (final c in NoteColor.values) {
      expect(NoteColor.fromValue(c.value), c);
    }
    expect(NoteColor.fromValue(99), NoteColor.yellow);
  });
}

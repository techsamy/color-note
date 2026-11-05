import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/notes/notes_providers.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

Finder fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Future<void> newNote(WidgetTester tester, String kind) async {
  await tester.tap(find.byTooltip('New note'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(kind));
  await tester.pumpAndSettle();
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await settle(tester);
}

/// DB reads must run outside the fake-async zone (drift uses real timers).
Future<List<Note>> storedNotes(
  WidgetTester tester,
  ProviderContainer c,
) async =>
    (await tester.runAsync(() => c.read(notesRepositoryProvider).allNotes()))!;

Future<List<String>> storedTitles(
  WidgetTester tester,
  ProviderContainer c,
) async => [for (final n in await storedNotes(tester, c)) n.title];

void main() {
  testWidgets('create a text note; it auto-saves and shows in the list', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    await newNote(tester, 'Text');
    await tester.enterText(fieldWithHint('Title'), 'Shopping');
    await tester.enterText(fieldWithHint('Note'), 'milk and eggs');
    await tester.pump(const Duration(seconds: 1)); // debounce
    await goBack(tester);

    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('milk and eggs'), findsOneWidget);
    expect(await storedTitles(tester, c), ['Shopping']);
  });

  testWidgets('an empty new note is discarded', (tester) async {
    final c = await pumpApp(tester);
    await newNote(tester, 'Text');
    await goBack(tester);
    expect(find.text('No notes yet'), findsOneWidget);
    expect(await storedTitles(tester, c), isEmpty);
  });

  testWidgets('checklist: add items, tick one', (tester) async {
    final c = await pumpApp(tester);
    await newNote(tester, 'Checklist');
    await tester.enterText(fieldWithHint('Title'), 'Groceries');
    await tester.enterText(fieldWithHint('List item').first, 'milk');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    await tester.enterText(fieldWithHint('List item').last, 'bread');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump(const Duration(seconds: 1));
    await goBack(tester);

    final note = (await storedNotes(tester, c)).single;
    expect(note.type, NoteType.checklist);
    expect(
      note.items.map((i) => (i.text, i.checked)),
      [('bread', false), ('milk', true)], // checked moved to bottom
    );
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('select + delete, then undo', (tester) async {
    final c = await pumpApp(tester);
    await tester.runAsync(
      () => c.read(notesRepositoryProvider).save(textNote('a', title: 'Alpha')),
    );
    await settle(tester);

    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Note moved to trash'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('search finds notes by any word prefix', (tester) async {
    final c = await pumpApp(tester);
    final repo = c.read(notesRepositoryProvider);
    await dbWrite(
      tester,
      () => repo.save(textNote('a', title: 'Groceries', text: 'milk')),
    );
    await dbWrite(
      tester,
      () => repo.save(textNote('b', title: 'Work', text: 'meeting')),
    );

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'meet');
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);
  });

  testWidgets('lock a note: set master password, content is sealed', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    await tester.runAsync(
      () => c
          .read(notesRepositoryProvider)
          .save(textNote('a', title: 'Diary', text: 'secret')),
    );
    await settle(tester);
    await tester.tap(find.text('Diary'));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock note'));
    await settle(tester);

    // No master password yet -> setup screen.
    expect(find.text('Set master password'), findsWidgets);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'hunter22');
    await tester.enterText(fields.at(1), 'hunter22');
    await tester.tap(find.text('Save'));
    await settle(tester);

    // Recovery key must be acknowledged.
    expect(find.text('Save your recovery key'), findsOneWidget);
    await tester.tap(find.text('I have saved my recovery key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await settle(tester);
    await settle(tester);

    final stored = await tester.runAsync(
      () => c.read(notesRepositoryProvider).getNote('a'),
    );
    expect(stored!.isSealed, isTrue);
    expect(stored.title, isEmpty);

    await goBack(tester);
    expect(find.text('Locked note'), findsOneWidget);
    expect(find.text('Diary'), findsNothing);
  });
}

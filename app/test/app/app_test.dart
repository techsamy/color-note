import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/app/app.dart';

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    testWidgets('boots to the empty notes screen ($mode)', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = mode;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const ProviderScope(child: HueNoteApp()));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet'), findsOneWidget);
    });
  }
}

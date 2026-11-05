import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    testWidgets('boots to the empty notes screen ($mode)', (tester) async {
      await pumpApp(tester, brightness: mode);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('No notes yet'), findsOneWidget);
    });
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/app.dart';

/// Bootstrap only — no logic here. See docs/03-architecture.md §2.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HueNoteApp()));
}

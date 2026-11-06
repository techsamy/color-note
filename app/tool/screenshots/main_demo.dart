// Entry point used only to take website / store screenshots.
//
//   flutter build web -t tool/screenshots/main_demo.dart
//
// Opens the real app with a fresh database filled with demo notes. Query
// parameters pick the look: `?theme=dark&view=grid`. Run it in a throwaway
// browser profile — it writes to that profile's local database.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/app.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/settings/data/settings_repository.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final params = Uri.base.queryParameters;
  await SettingsRepository(prefs).save(
    AppSettings(
      themeMode: params['theme'] == 'dark'
          ? AppThemeMode.dark
          : AppThemeMode.light,
      viewMode: params['view'] == 'list'
          ? NoteViewMode.list
          : NoteViewMode.grid,
    ),
  );

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  await _seed(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const HueNoteApp()),
  );
}

Future<void> _seed(ProviderContainer c) async {
  final notes = c.read(notesRepositoryProvider);
  if ((await notes.allNotes()).isNotEmpty) return;

  final now = DateTime.now();
  var n = 0;
  Note note(
    String title, {
    required NoteColor color,
    String text = '',
    List<(String, bool)> items = const [],
    bool pinned = false,
    int minutesAgo = 0,
  }) {
    n++;
    final at = now.subtract(Duration(minutes: minutesAgo));
    return Note(
      id: 'demo-$n',
      type: items.isEmpty ? NoteType.text : NoteType.checklist,
      title: title,
      text: text,
      items: [
        for (final (i, (t, done)) in items.indexed)
          ChecklistItem(id: 'demo-$n-$i', text: t, checked: done),
      ],
      color: color,
      isPinned: pinned,
      createdAt: at,
      updatedAt: at,
    );
  }

  final lock = c.read(lockControllerProvider.notifier);
  await c.read(lockControllerProvider.future);
  await lock.setUp('demo master password');
  final secret = await lock.seal(
    note(
      'Bank & passwords',
      color: NoteColor.purple,
      text: 'Never shown in plain text.',
      minutesAgo: 300,
    ).copyWith(isLocked: true),
  );
  lock.lock();

  await notes.importNotes([
    note(
      'Groceries',
      color: NoteColor.green,
      pinned: true,
      minutesAgo: 5,
      items: [
        ('Milk', true),
        ('Bread', true),
        ('Tomatoes', false),
        ('Paneer', false),
        ('Coffee beans', false),
        ('Bananas', false),
      ],
    ),
    note(
      'Trip to Goa',
      color: NoteColor.blue,
      minutesAgo: 40,
      text:
          'Flight on Friday 7:40 am.\nPack sunscreen, charger, '
          'swimwear.\nBook the beach shack for Saturday dinner.',
    ),
    note(
      'Book ideas',
      color: NoteColor.yellow,
      minutesAgo: 90,
      text:
          'A detective who can only solve crimes on rainy days. '
          'Every chapter opens with the weather report.',
    ),
    note(
      'This week',
      color: NoteColor.orange,
      minutesAgo: 120,
      items: [
        ('Pay electricity bill', true),
        ('Call the plumber', false),
        ('Renew gym membership', false),
        ('Dentist on Thursday', false),
      ],
    ),
    note(
      'Gift for Maa',
      color: NoteColor.red,
      minutesAgo: 200,
      text: 'Silk saree from the old market, or the cookbook she liked.',
    ),
    secret,
    note(
      'Meeting notes',
      color: NoteColor.grey,
      minutesAgo: 600,
      text:
          'Launch moved to the 20th. Design review on Monday. '
          'Ask about the new budget.',
    ),
    note(
      'Wi-Fi at the office',
      color: NoteColor.white,
      minutesAgo: 1400,
      text: 'Network: Studio-5G. Ask reception for the guest code.',
    ),
  ]);

  final labels = c.read(colorLabelsRepositoryProvider);
  await labels.setLabel(NoteColor.green, 'Shopping');
  await labels.setLabel(NoteColor.blue, 'Travel');
  await labels.setLabel(NoteColor.orange, 'To-do');
}

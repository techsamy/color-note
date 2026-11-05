import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/features/backup/presentation/backup_screen.dart';
import 'package:huenote/features/lock/presentation/master_password_screen.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/domain/note_type.dart';
import 'package:huenote/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:huenote/features/notes/presentation/list/notes_section_screen.dart';
import 'package:huenote/features/search/presentation/search_screen.dart';
import 'package:huenote/features/settings/presentation/color_labels_screen.dart';
import 'package:huenote/features/settings/presentation/settings_screen.dart';

export 'package:huenote/features/lock/presentation/master_password_screen.dart'
    show MasterPasswordMode;

/// Route paths. Deep link scheme `huenote://note/<id>` maps onto these.
abstract final class Routes {
  static const home = '/';
  static const archive = '/archive';
  static const trash = '/trash';
  static const search = '/search';
  static const settings = '/settings';
  static const colorLabels = '/settings/labels';
  static const backup = '/settings/backup';

  static String note(String id) => '/note/$id';

  static String newNote(NoteType type) => '/new-note?type=${type.name}';

  static String masterPassword(MasterPasswordMode mode) =>
      '/settings/master-password?mode=${mode.name}';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const NotesSectionScreen(section: NoteSection.notes),
      ),
      GoRoute(
        path: Routes.archive,
        builder: (_, _) =>
            const NotesSectionScreen(section: NoteSection.archive),
      ),
      GoRoute(
        path: Routes.trash,
        builder: (_, _) => const NotesSectionScreen(section: NoteSection.trash),
      ),
      GoRoute(path: Routes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/note/:id',
        builder: (_, state) =>
            NoteEditorScreen.existing(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/new-note',
        builder: (_, state) => NoteEditorScreen.create(
          newType: state.uri.queryParameters['type'] == NoteType.checklist.name
              ? NoteType.checklist
              : NoteType.text,
        ),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: Routes.colorLabels,
        builder: (_, _) => const ColorLabelsScreen(),
      ),
      GoRoute(path: Routes.backup, builder: (_, _) => const BackupScreen()),
      GoRoute(
        path: '/settings/master-password',
        builder: (_, state) => MasterPasswordScreen(
          mode: MasterPasswordMode.values.firstWhere(
            (m) => m.name == state.uri.queryParameters['mode'],
            orElse: () => MasterPasswordMode.setup,
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

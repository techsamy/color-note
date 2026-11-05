import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/core/widgets/empty_state.dart';
import 'package:huenote/features/notes/domain/note.dart';
import 'package:huenote/features/notes/domain/note_query.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/notes/presentation/list/notes_sliver.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

final _searchResultsProvider = StreamProvider.autoDispose
    .family<List<Note>, String>(
      (ref, text) => ref.watch(notesRepositoryProvider).watchSearch(text),
    );

/// FR-L4 — live full-text search (locked notes excluded).
class SearchScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final results = _query.isEmpty
        ? const AsyncData<List<Note>>([])
        : ref.watch(_searchResultsProvider(_query));
    final notes = results.value ?? const <Note>[];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: l10n.actionClose,
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (_query.isNotEmpty && results.hasValue && notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off,
                title: l10n.emptySearchTitle,
                message: l10n.emptySearchBody,
              ),
            )
          else
            NotesSliver(
              notes: notes,
              viewMode: NoteViewMode.list,
              fontSize: settings.fontSize,
              selected: const {},
              onTap: (n) => context.push(Routes.note(n.id)),
              onLongPress: (n) => context.push(Routes.note(n.id)),
            ),
        ],
      ),
    );
  }
}

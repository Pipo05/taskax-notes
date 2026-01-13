import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_scaffold.dart';
import '../features/folders/presentation/folders_page.dart';
import '../features/notes/presentation/note_editor_page.dart';
import '../features/notes/presentation/notes_list_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/search/presentation/search_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/notes',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/notes',
            name: 'notes',
            builder: (context, state) => const NotesListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'note_new',
                builder: (context, state) => const NoteEditorPage(noteId: null),
              ),
              GoRoute(
                path: ':id',
                name: 'note_edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return NoteEditorPage(noteId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/folders',
            name: 'folders',
            builder: (context, state) => const FoldersPage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});

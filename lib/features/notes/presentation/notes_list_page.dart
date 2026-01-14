import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'notes_controller.dart';

class NotesListPage extends ConsumerWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Taskax Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Create note then open editor
          final noteId = await ref.read(createNoteProvider.future);
          if (context.mounted) context.go('/notes/$noteId');
        },
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet. Tap + to create one.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = notes[index];
              final title = n.title.trim().isEmpty ? 'Untitled note' : n.title.trim();

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('Updated: ${n.updatedAt}'),
                  onTap: () => context.go('/notes/${n.id}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final repo = ref.read(notesRepositoryProvider);
                      await repo.deleteNote(n.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

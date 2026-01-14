import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/note_entity.dart';
import 'notes_controller.dart';

class NoteEditorPage extends ConsumerWidget {
  final String? noteId; // null means "new" (not used now)
  const NoteEditorPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(noteId ?? '');
    if (id == null) {
      return const Scaffold(
        body: Center(child: Text('Invalid note id')),
      );
    }

    final noteAsync = ref.watch(noteByIdProvider(id));

    return noteAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (note) {
        if (note == null) {
          return const Scaffold(body: Center(child: Text('Note not found')));
        }
        return _Editor(note: note);
      },
    );
  }
}

class _Editor extends ConsumerWidget {
  final NoteEntity note;
  const _Editor({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(notesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          IconButton(
            tooltip: 'Add text block',
            icon: const Icon(Icons.subject),
            onPressed: () async {
              await addTextBlock(repo, note);
              ref.invalidate(noteByIdProvider(note.id));
            },
          ),
          IconButton(
            tooltip: 'Add checklist block',
            icon: const Icon(Icons.checklist),
            onPressed: () async {
              await addChecklistBlock(repo, note);
              ref.invalidate(noteByIdProvider(note.id));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: note.title),
            onChanged: (v) async {
              note.title = v;
              await repo.upsertNote(note);
            },
          ),
          const SizedBox(height: 12),
          ...List.generate(note.blocks.length, (index) {
            final block = note.blocks[index];

            if (block.type == 'text') {
              return _TextBlock(
                initial: block.text ?? '',
                onChanged: (v) async {
                  block.text = v;
                  await repo.upsertNote(note);
                },
              );
            }

            // checklist block
            final items = (block.items = List<ChecklistItemEntity>.from(block.items ?? []));

            return _ChecklistBlock(
              items: items,
              onToggle: (i, checked) async {
                items[i].checked = checked;
                await repo.upsertNote(note);
                ref.invalidate(noteByIdProvider(note.id)); // refresh immediately
              },
              onTextChanged: (i, text) async {
                items[i].text = text;
                await repo.upsertNote(note);
              },
              onAddItem: () async {
                items.add(ChecklistItemEntity()..text = '');
                await repo.upsertNote(note);
                ref.invalidate(noteByIdProvider(note.id)); // show new row instantly
              },
            );
          }),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String initial;
  final ValueChanged<String> onChanged;

  const _TextBlock({required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: TextEditingController(text: initial),
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Write…',
            border: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChecklistBlock extends StatelessWidget {
  final List<ChecklistItemEntity> items;
  final void Function(int index, bool checked) onToggle;
  final void Function(int index, String text) onTextChanged;
  final VoidCallback onAddItem;

  const _ChecklistBlock({
    required this.items,
    required this.onToggle,
    required this.onTextChanged,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++)
              Row(
                children: [
                  Checkbox(
                    value: items[i].checked,
                    onChanged: (v) => onToggle(i, v ?? false),
                  ),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: items[i].text),
                      decoration: const InputDecoration(
                        hintText: 'Checklist item',
                        border: InputBorder.none,
                      ),
                      onChanged: (t) => onTextChanged(i, t),
                    ),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

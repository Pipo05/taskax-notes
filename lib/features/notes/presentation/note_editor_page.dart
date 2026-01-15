import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskax_notes/features/notes/data/models/note_entity.dart';
import 'package:taskax_notes/features/notes/presentation/notes_controller.dart';

class NoteEditorPage extends ConsumerWidget {
  final String? noteId;
  const NoteEditorPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(noteId ?? '');
    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid note id')));
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
        // IMPORTANT: key editor by note.id so state/controllers don't bleed across notes
        return _Editor(key: ValueKey(note.id), note: note);
      },
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  final NoteEntity note;
  const _Editor({super.key, required this.note});

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late TextEditingController titleController;

  final Map<int, TextEditingController> textBlockControllers = {};
  final Map<String, TextEditingController> checklistControllers = {};

  // ✅ Added: scroll controller so we can force reliable scrolling + visible scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final c in textBlockControllers.values) {
      c.dispose();
    }
    for (final c in checklistControllers.values) {
      c.dispose();
    }
    _scrollController.dispose(); // ✅ Added
    super.dispose();
  }

  TextEditingController _textBlockController(int blockIndex, String initial) {
    return textBlockControllers.putIfAbsent(
      blockIndex,
      () => TextEditingController(text: initial),
    );
  }

  TextEditingController _checklistController(String key, String initial) {
    return checklistControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
  }

  void _removeTextBlockControllersFrom(int startIndex) {
    // When we delete a block, all following indices shift down by 1.
    // Simplest safe approach: dispose controllers for >= startIndex, and let them be recreated.
    final keys = textBlockControllers.keys.where((k) => k >= startIndex).toList();
    for (final k in keys) {
      textBlockControllers[k]?.dispose();
      textBlockControllers.remove(k);
    }
  }

  void _removeChecklistControllersForBlock(int blockIndex) {
    // Remove controllers whose key starts with "{blockIndex}_"
    final prefix = '${blockIndex}_';
    final keys = checklistControllers.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      checklistControllers[k]?.dispose();
      checklistControllers.remove(k);
    }
  }

  void _removeChecklistControllersFromBlockIndex(int startBlockIndex) {
    // After deleting a block, block indices shift. Safest: clear controllers for blocks >= startBlockIndex.
    final keys = checklistControllers.keys.toList();
    for (final k in keys) {
      final parts = k.split('_');
      if (parts.isEmpty) continue;
      final b = int.tryParse(parts.first);
      if (b != null && b >= startBlockIndex) {
        checklistControllers[k]?.dispose();
        checklistControllers.remove(k);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final repo = ref.watch(notesRepositoryProvider);

    return Scaffold(
      // ✅ Helps when keyboard shows/hides
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          IconButton(
            tooltip: 'Add text block',
            icon: const Icon(Icons.subject),
            onPressed: () async {
              // Optimistic UI update
              setState(() {
                note.blocks = List<NoteBlockEntity>.from(note.blocks);
                note.blocks.add(
                  NoteBlockEntity()
                    ..type = 'text'
                    ..text = '',
                );
              });

              await repo.upsertNote(note);
              ref.invalidate(noteByIdProvider(note.id));
            },
          ),
          IconButton(
            tooltip: 'Add checklist block',
            icon: const Icon(Icons.checklist),
            onPressed: () async {
              // Optimistic UI update
              setState(() {
                note.blocks = List<NoteBlockEntity>.from(note.blocks);
                note.blocks.add(
                  NoteBlockEntity()
                    ..type = 'checklist'
                    ..items = [ChecklistItemEntity()..text = 'First item'],
                );
              });

              await repo.upsertNote(note);
              ref.invalidate(noteByIdProvider(note.id));
            },
          ),
        ],
      ),

      // ✅ Keyboard-safe + always scrollable + drag-to-dismiss keyboard
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true, // ✅ always show on desktop/simulator
            interactive: true, // ✅ draggable scrollbar
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) async {
                    note.title = v;
                    await repo.upsertNote(note);
                  },
                ),
                const SizedBox(height: 12),
                ...List.generate(note.blocks.length, (blockIndex) {
                  final block = note.blocks[blockIndex];

                  if (block.type == 'text') {
                    final controller =
                        _textBlockController(blockIndex, block.text ?? '');

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ✅ Block header row with delete
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Text',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete block',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    setState(() {
                                      note.blocks = List<NoteBlockEntity>.from(note.blocks);
                                      note.blocks.removeAt(blockIndex);

                                      // dispose/recreate controllers safely after index shifts
                                      _removeTextBlockControllersFrom(blockIndex);
                                      _removeChecklistControllersFromBlockIndex(blockIndex);
                                    });

                                    await repo.upsertNote(note);
                                    ref.invalidate(noteByIdProvider(note.id));
                                  },
                                ),
                              ],
                            ),
                            TextField(
                              controller: controller,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'Write…',
                                border: InputBorder.none,
                              ),
                              onChanged: (v) async {
                                block.text = v;
                                await repo.upsertNote(note);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // checklist block: clone to growable (Isar may return fixed-length)
                  final items = (block.items = List<ChecklistItemEntity>.from(
                      block.items ?? const []));

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // ✅ Block header row with delete
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Checklist',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete block',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  setState(() {
                                    note.blocks = List<NoteBlockEntity>.from(note.blocks);
                                    note.blocks.removeAt(blockIndex);

                                    // dispose/recreate controllers safely after index shifts
                                    _removeTextBlockControllersFrom(blockIndex);
                                    _removeChecklistControllersFromBlockIndex(blockIndex);
                                  });

                                  await repo.upsertNote(note);
                                  ref.invalidate(noteByIdProvider(note.id));
                                },
                              ),
                            ],
                          ),

                          for (int itemIndex = 0; itemIndex < items.length; itemIndex++)
                            Row(
                              children: [
                                Checkbox(
                                  value: items[itemIndex].checked,
                                  onChanged: (v) async {
                                    items[itemIndex].checked = v ?? false;
                                    await repo.upsertNote(note);
                                    ref.invalidate(noteByIdProvider(note.id));
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _checklistController(
                                      '${blockIndex}_$itemIndex',
                                      items[itemIndex].text,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Checklist item',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (t) async {
                                      items[itemIndex].text = t;
                                      await repo.upsertNote(note);
                                    },
                                  ),
                                ),
                                // ✅ Delete item
                                IconButton(
                                  tooltip: 'Delete item',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    // Optional: prevent deleting the last remaining item
                                    if (items.length <= 1) return;

                                    setState(() {
                                      items.removeAt(itemIndex);

                                      // Drop controllers for this block so indices don't mismatch
                                      _removeChecklistControllersForBlock(blockIndex);
                                    });

                                    await repo.upsertNote(note);
                                    ref.invalidate(noteByIdProvider(note.id));
                                  },
                                ),
                              ],
                            ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                setState(() {
                                  items.add(ChecklistItemEntity()..text = '');
                                  // safer to clear controllers for this block so new indices align
                                  _removeChecklistControllersForBlock(blockIndex);
                                });
                                await repo.upsertNote(note);
                                ref.invalidate(noteByIdProvider(note.id));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add item'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

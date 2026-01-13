import 'package:flutter/material.dart';

class NoteEditorPage extends StatelessWidget {
  final String? noteId; // null means "new"
  const NoteEditorPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    final isNew = noteId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Note' : 'Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: const [
                    Text(
                      'Editor placeholder.\n\n'
                      'Next we build a block-based editor:\n'
                      '• Text blocks\n'
                      '• Checklist blocks (with checkboxes)\n\n'
                      'And we’ll save to Isar first (offline) then sync to Firestore.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

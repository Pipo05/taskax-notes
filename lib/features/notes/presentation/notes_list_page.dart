import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taskax Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/notes/new'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _NoteTile(
            title: 'Welcome to Taskax Notes',
            subtitle: 'Tap to edit (placeholder)',
            onTap: () => context.go('/notes/demo-note-id'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Next: we’ll replace this list with Isar-backed notes + sync.',
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NoteTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

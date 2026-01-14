import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/db/isar_provider.dart';
import '../data/models/note_entity.dart';
import '../data/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);

  final isar = isarAsync.maybeWhen(
    data: (db) => db,
    orElse: () => null,
  );

  if (isar == null) {
    throw StateError('Isar not ready yet');
  }

  return NotesRepository(isar);
});

final notesStreamProvider = StreamProvider<List<NoteEntity>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchAllNotes();
});

final noteByIdProvider =
    FutureProvider.family<NoteEntity?, int>((ref, id) async {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.getNoteById(id);
});

/// Creates a new note with starter blocks.
final createNoteProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);

  final note = NoteEntity()
    ..title = ''
    ..blocks = [
      NoteBlockEntity()
        ..type = 'text'
        ..text = '',
      NoteBlockEntity()
        ..type = 'checklist'
        ..items = [
          (ChecklistItemEntity()..text = 'First item'),
        ],
    ];

  return repo.upsertNote(note);
});

/// Helper: add a text block
Future<void> addTextBlock(NotesRepository repo, NoteEntity note) async {
  note.blocks.add(
    NoteBlockEntity()
      ..type = 'text'
      ..text = '',
  );
  await repo.upsertNote(note);
}

/// Helper: add a checklist block
Future<void> addChecklistBlock(NotesRepository repo, NoteEntity note) async {
  note.blocks.add(
    NoteBlockEntity()
      ..type = 'checklist'
      ..items = [(ChecklistItemEntity()..text = '')],
  );
  await repo.upsertNote(note);
}

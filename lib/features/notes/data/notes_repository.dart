import 'package:isar/isar.dart';

import 'models/note_entity.dart';

class NotesRepository {
  final Isar _isar;
  NotesRepository(this._isar);

  Stream<List<NoteEntity>> watchAllNotes() {
    return _isar.noteEntitys
        .where()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<NoteEntity?> getNoteById(int id) {
    return _isar.noteEntitys.get(id);
  }

  Future<int> upsertNote(NoteEntity note) async {
    note.updatedAt = DateTime.now();
    return _isar.writeTxn(() async {
      return _isar.noteEntitys.put(note);
    });
  }

  Future<void> deleteNote(int id) async {
    await _isar.writeTxn(() async {
      await _isar.noteEntitys.delete(id);
    });
  }
}

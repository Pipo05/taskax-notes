import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/notes/data/models/note_entity.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [NoteEntitySchema],
    directory: dir.path,
  );

  ref.onDispose(() async {
    if (isar.isOpen) {
      await isar.close();
    }
  });

  return isar;
});

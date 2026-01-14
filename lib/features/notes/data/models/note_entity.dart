import 'package:isar/isar.dart';

part 'note_entity.g.dart';

@collection
class NoteEntity {
  Id id = Isar.autoIncrement;

  late String title;

  /// Blocks are embedded and ordered.
  late List<NoteBlockEntity> blocks;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@embedded
class NoteBlockEntity {
  /// "text" or "checklist"
  late String type;

  /// For type == "text"
  String? text;

  /// For type == "checklist"
  List<ChecklistItemEntity>? items;
}

@embedded
class ChecklistItemEntity {
  late String text;
  bool checked = false;
}

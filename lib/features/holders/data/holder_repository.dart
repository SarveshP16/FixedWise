import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/holder.dart';

/// The single source of truth for holders (the app owner plus any family
/// members whose FDs are also tracked).
class HolderRepository {
  HolderRepository(this._box);

  final Box<Map> _box;

  List<Holder> getAll() {
    final holders = _box.values.map(Holder.fromMap).toList();
    holders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return holders;
  }

  Future<void> add(Holder holder) async {
    await _box.put(holder.id, holder.toMap());
  }

  Future<void> update(Holder holder) async {
    await _box.put(holder.id, holder.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Creates and returns the one auto-seeded "Self" holder if the box is
  /// still empty (first launch), otherwise returns the existing Self
  /// holder. Called once during app startup.
  Future<Holder> ensureSelfHolder({String selfName = 'Me'}) async {
    final existing = getAll();
    for (final holder in existing) {
      if (holder.isSelf) return holder;
    }

    final holder = Holder(id: generateId(), name: selfName, isSelf: true, createdAt: DateTime.now());
    await add(holder);
    return holder;
  }

  static HolderRepository openDefault() {
    return HolderRepository(Hive.box<Map>(HiveBoxes.holders));
  }
}

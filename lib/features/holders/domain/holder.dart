/// A person a Fixed Deposit can be tagged to — the app's own user, or a
/// family member whose FDs they're also tracking.
///
/// Stored in Hive as a plain `Map<String, dynamic>` via [toMap]/[fromMap]
/// rather than a generated `TypeAdapter` — same convention as Wardro's
/// `ClothingItem`, no build_runner step needed for a shape this simple.
class Holder {
  const Holder({required this.id, required this.name, required this.isSelf, required this.createdAt});

  final String id;
  final String name;

  /// True for the one auto-seeded holder representing the app's own user.
  /// Can be renamed but never deleted — every other holder can be both.
  final bool isSelf;

  final DateTime createdAt;

  Holder copyWith({String? name}) {
    return Holder(id: id, name: name ?? this.name, isSelf: isSelf, createdAt: createdAt);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'isSelf': isSelf, 'createdAt': createdAt.toIso8601String()};
  }

  factory Holder.fromMap(Map<dynamic, dynamic> map) {
    return Holder(
      id: map['id'] as String,
      name: map['name'] as String,
      isSelf: map['isSelf'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

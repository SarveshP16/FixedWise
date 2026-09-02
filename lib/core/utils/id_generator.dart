import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a new random id for a Holder or FixedDeposit record. One
/// place to change the id scheme later if it ever needs to.
String generateId() => _uuid.v4();

import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/fixed_deposit.dart';

/// The single source of truth for Fixed Deposits.
class FixedDepositRepository {
  FixedDepositRepository(this._box);

  final Box<Map> _box;

  List<FixedDeposit> getAll() {
    final deposits = _box.values.map(FixedDeposit.fromMap).toList();
    deposits.sort((a, b) => b.openedDate.compareTo(a.openedDate));
    return deposits;
  }

  Future<void> add(FixedDeposit deposit) async {
    await _box.put(deposit.id, deposit.toMap());
  }

  Future<void> update(FixedDeposit deposit) async {
    await _box.put(deposit.id, deposit.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Bank names already used by any existing FD, most-recently-used first
  /// and de-duplicated — feeds the New Deposit form's autocomplete without
  /// needing any separate storage of its own.
  List<String> distinctBankNames() {
    final seen = <String>{};
    final names = <String>[];
    for (final deposit in getAll()) {
      if (seen.add(deposit.bankName)) names.add(deposit.bankName);
    }
    return names;
  }

  /// `null` means "every holder".
  List<FixedDeposit> byHolder(String? holderId) {
    final all = getAll();
    if (holderId == null) return all;
    return all.where((deposit) => deposit.holderId == holderId).toList();
  }

  static FixedDepositRepository openDefault() {
    return FixedDepositRepository(Hive.box<Map>(HiveBoxes.fixedDeposits));
  }
}

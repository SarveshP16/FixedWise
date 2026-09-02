import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fixed_deposit_repository.dart';
import '../domain/fixed_deposit.dart';

final fixedDepositRepositoryProvider = Provider<FixedDepositRepository>((ref) {
  return FixedDepositRepository.openDefault();
});

/// The live list of every FD, newest-opened first. UI reads this provider;
/// mutations go through its notifier's methods so every screen (dashboard,
/// list, detail) stays in sync automatically.
final fixedDepositsProvider = StateNotifierProvider<FixedDepositsNotifier, List<FixedDeposit>>((ref) {
  return FixedDepositsNotifier(ref.watch(fixedDepositRepositoryProvider));
});

class FixedDepositsNotifier extends StateNotifier<List<FixedDeposit>> {
  FixedDepositsNotifier(this._repository) : super(_repository.getAll());

  final FixedDepositRepository _repository;

  Future<void> add(FixedDeposit deposit) async {
    await _repository.add(deposit);
    state = _repository.getAll();
  }

  Future<void> update(FixedDeposit deposit) async {
    await _repository.update(deposit);
    state = _repository.getAll();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}

/// `null` means "every holder" — the Deposits list's filter-chip row.
final holderFilterProvider = StateProvider<String?>((ref) => null);

/// The deposits matching the current [holderFilterProvider] selection.
final filteredFixedDepositsProvider = Provider<List<FixedDeposit>>((ref) {
  final deposits = ref.watch(fixedDepositsProvider);
  final holderId = ref.watch(holderFilterProvider);
  if (holderId == null) return deposits;
  return deposits.where((deposit) => deposit.holderId == holderId).toList();
});

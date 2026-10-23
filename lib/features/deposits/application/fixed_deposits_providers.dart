import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/calculations/maturity_calculator.dart';
import '../data/fixed_deposit_repository.dart';
import '../domain/deposit_sort.dart';
import '../domain/deposit_status_filter.dart';
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

/// The Deposits list's search box — matched against bank name and FD
/// number, case-insensitively. Empty means "no search filter".
final depositSearchQueryProvider = StateProvider<String>((ref) => '');

/// The Deposits list's chosen sort order — see [DepositSort].
final depositSortProvider = StateProvider<DepositSort>((ref) => DepositSort.recentlyAdded);

/// The Deposits list's All/Active/Matured/Closed-early view selector.
final depositStatusFilterProvider = StateProvider<DepositStatusFilter>((ref) => DepositStatusFilter.all);

/// The deposits matching the current [holderFilterProvider]/
/// [depositStatusFilterProvider]/[depositSearchQueryProvider], in
/// [depositSortProvider] order.
final filteredFixedDepositsProvider = Provider<List<FixedDeposit>>((ref) {
  final deposits = ref.watch(fixedDepositsProvider);
  final holderId = ref.watch(holderFilterProvider);
  final statusFilter = ref.watch(depositStatusFilterProvider);
  final query = ref.watch(depositSearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(depositSortProvider);

  var result = holderId == null ? deposits : deposits.where((deposit) => deposit.holderId == holderId).toList();

  if (statusFilter != DepositStatusFilter.all) {
    result = result.where((deposit) => depositStatusOf(deposit) == statusFilter).toList();
  }

  if (query.isNotEmpty) {
    result = result
        .where(
          (deposit) =>
              deposit.bankName.toLowerCase().contains(query) ||
              (deposit.fdNumber?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  switch (sort) {
    case DepositSort.recentlyAdded:
      break; // Already `fixedDepositsProvider`'s own newest-opened-first order.
    case DepositSort.maturityDate:
      result = [...result]..sort((a, b) => a.maturityDate.compareTo(b.maturityDate));
    case DepositSort.amount:
      result = [...result]..sort(
        (a, b) => MaturityCalculator.maturityValue(b).compareTo(MaturityCalculator.maturityValue(a)),
      );
    case DepositSort.bankName:
      result = [...result]..sort((a, b) => a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));
  }

  return result;
});

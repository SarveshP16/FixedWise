import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/fixedwise_field_shell.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/selectable_chip.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/deposit_sort.dart';
import '../../domain/deposit_status_filter.dart';
import '../../domain/fixed_deposit.dart';
import '../widgets/fd_card.dart';
import '../widgets/holder_filter_row.dart';
import '../widgets/summary_strip.dart';

/// FixedWise's Deposits tab — the mockup's "All deposits, at a glance"
/// screen.
class DepositsListScreen extends ConsumerStatefulWidget {
  const DepositsListScreen({super.key});

  @override
  ConsumerState<DepositsListScreen> createState() => _DepositsListScreenState();
}

class _DepositsListScreenState extends ConsumerState<DepositsListScreen> {
  // Owns its own controller rather than reading the provider straight into
  // a stateless TextField — same reasoning as ProfileScreen's name/currency
  // fields: a provider-driven rebuild while the user is mid-type would
  // otherwise never reach the field they're looking at.
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(depositSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deposits = ref.watch(filteredFixedDepositsProvider);
    final query = ref.watch(depositSearchQueryProvider);
    final statusFilter = ref.watch(depositStatusFilterProvider);
    final hasDeposits = ref.watch(fixedDepositsProvider).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deposits', style: AppTypography.screenTitle),
                  Row(
                    children: [
                      BorderedIconButton(icon: Icons.sort, onTap: () => _openSortSheet(context)),
                      const SizedBox(width: 8),
                      BorderedIconButton(icon: Icons.add, onTap: () => context.push('/deposits/new')),
                    ],
                  ),
                ],
              ),
            ),
            if (hasDeposits)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: FixedwiseInputBox(
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.inputText,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Search bank or FD number',
                      hintStyle: AppTypography.inputText.copyWith(color: AppColors.textSoft),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSoft),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 18),
                      suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 18),
                      suffixIcon: query.isEmpty
                          ? null
                          : InkWell(
                              onTap: () {
                                _searchController.clear();
                                ref.read(depositSearchQueryProvider.notifier).state = '';
                              },
                              child: Icon(Icons.close, size: 16, color: AppColors.textSoft),
                            ),
                    ),
                    onChanged: (value) => ref.read(depositSearchQueryProvider.notifier).state = value,
                  ),
                ),
              ),
            if (hasDeposits)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final filter in DepositStatusFilter.values) ...[
                        if (filter != DepositStatusFilter.values.first) const SizedBox(width: 8),
                        SelectableChip(
                          label: filter.label,
                          selected: statusFilter == filter,
                          onTap: () => ref.read(depositStatusFilterProvider.notifier).state = filter,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
              child: SummaryStrip(deposits: deposits),
            ),
            const SizedBox(height: 4),
            const HolderFilterRow(),
            const SizedBox(height: 6),
            Expanded(
              child: deposits.isEmpty
                  ? _EmptyState(searching: query.isNotEmpty, statusFilter: statusFilter)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
                      children: statusFilter == DepositStatusFilter.all
                          ? _buildSections(deposits)
                          : [for (final deposit in deposits) _cardTile(deposit)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardTile(FixedDeposit deposit) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: FdCard(deposit: deposit));

  /// Groups [deposits] into Active, Matured, and Closed early — in that
  /// order, each preserving the incoming (already sorted) order — and
  /// flattens them into one row list with a [SectionTitle] wherever more
  /// than one group is present. A single-group list (the common case,
  /// e.g. no closed deposits yet) shows no headers at all. Only used for
  /// [DepositStatusFilter.all] — the other filters are already
  /// single-group, so they render as a plain flat list instead.
  List<Widget> _buildSections(List<FixedDeposit> deposits) {
    final active = <FixedDeposit>[];
    final matured = <FixedDeposit>[];
    final closedEarly = <FixedDeposit>[];
    for (final deposit in deposits) {
      switch (depositStatusOf(deposit)) {
        case DepositStatusFilter.closedEarly:
          closedEarly.add(deposit);
        case DepositStatusFilter.matured:
          matured.add(deposit);
        case DepositStatusFilter.active:
        case DepositStatusFilter.all:
          active.add(deposit);
      }
    }

    final groupCount = [active, matured, closedEarly].where((group) => group.isNotEmpty).length;
    final sections = [
      (groupCount > 1 ? 'Active' : null, active),
      ('Matured', matured),
      ('Closed early', closedEarly),
    ];

    final rows = <Widget>[];
    for (final (title, items) in sections) {
      if (items.isEmpty) continue;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      if (title != null) rows.add(SectionTitle(title));
      rows.addAll(items.map(_cardTile));
    }
    return rows;
  }

  Future<void> _openSortSheet(BuildContext context) async {
    final current = ref.read(depositSortProvider);
    final chosen = await showModalBottomSheet<DepositSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final sort in DepositSort.values)
              ListTile(
                title: Text(sort.label),
                trailing: sort == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(sort),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) ref.read(depositSortProvider.notifier).state = chosen;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching, required this.statusFilter});

  /// Distinguishes "no deposits at all" from "no results for this
  /// search/filter" — the latter shouldn't tell you to tap + to add one,
  /// since you likely already have deposits that just don't match.
  final bool searching;

  /// When this is anything but [DepositStatusFilter.all] and the list is
  /// still empty, that's it working correctly (nothing in that bucket) —
  /// worth saying explicitly, since it'd otherwise look identical to "no
  /// deposits at all" and read as the filter being broken.
  final DepositStatusFilter statusFilter;

  String get _message {
    if (searching) return 'No deposits match your search.';
    if (statusFilter != DepositStatusFilter.all) {
      return 'No ${statusFilter.label.toLowerCase()} deposits.';
    }
    return 'No deposits yet. Tap + to add your first Fixed Deposit.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(_message, textAlign: TextAlign.center, style: AppTypography.dateLine),
      ),
    );
  }
}

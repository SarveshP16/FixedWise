import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../application/fixed_deposits_providers.dart';
import '../widgets/fd_card.dart';
import '../widgets/holder_filter_row.dart';
import '../widgets/summary_strip.dart';

/// FixedWise's Deposits tab — the mockup's "All deposits, at a glance"
/// screen.
class DepositsListScreen extends ConsumerWidget {
  const DepositsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deposits = ref.watch(filteredFixedDepositsProvider);

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
                  BorderedIconButton(icon: Icons.add, onTap: () => context.push('/deposits/new')),
                ],
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
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
                      itemCount: deposits.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FdCard(deposit: deposits[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No deposits yet. Tap + to add your first Fixed Deposit.',
          textAlign: TextAlign.center,
          style: AppTypography.dateLine,
        ),
      ),
    );
  }
}

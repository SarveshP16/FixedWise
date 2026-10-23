import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/fixedwise_card.dart';
import '../../../../core/widgets/initial_chip.dart';
import '../../../deposits/application/fixed_deposits_providers.dart';
import '../../application/holders_providers.dart';
import '../../domain/holder.dart';

/// Manage the people FDs can be tagged to — the app owner ("Self", which
/// can be renamed but never deleted) plus any family members — and mark
/// who's a senior citizen, which changes their TDS threshold.
class HoldersScreen extends ConsumerWidget {
  const HoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holders = ref.watch(holdersProvider);
    final deposits = ref.watch(fixedDepositsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Row(
                children: [
                  BorderedIconButton(icon: Icons.arrow_back, size: 32, onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  Text('Holders', style: AppTypography.screenTitle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                children: [
                  for (final holder in holders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HolderRow(
                        holder: holder,
                        fdCount: deposits.where((fd) => fd.holderId == holder.id).length,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHolderDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddHolderDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add holder'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(holdersProvider.notifier).add(name);
    }
  }
}

class _HolderRow extends ConsumerWidget {
  const _HolderRow({required this.holder, required this.fdCount});

  final Holder holder;
  final int fdCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FixedwiseCard(
      child: Row(
        children: [
          InitialChip(label: holder.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holder.name, style: AppTypography.bankName),
                Text(
                  [
                    if (holder.isSelf) 'You',
                    '$fdCount FD${fdCount == 1 ? '' : 's'}',
                    if (holder.isSeniorCitizen) 'Senior citizen',
                  ].join(' · '),
                  style: AppTypography.dateLine,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: holder.isSeniorCitizen ? 'Senior citizen (60+)' : 'Mark as senior citizen (60+)',
            icon: Icon(holder.isSeniorCitizen ? Icons.elderly : Icons.elderly_outlined, size: 18),
            color: holder.isSeniorCitizen ? AppColors.brassDeep : null,
            onPressed: () => ref.read(holdersProvider.notifier).setSeniorCitizen(holder.id, !holder.isSeniorCitizen),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _rename(context, ref)),
          if (!holder.isSelf)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: fdCount == 0 ? () => _delete(context, ref) : () => _blockedDeleteDialog(context),
            ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: holder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename holder'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(holdersProvider.notifier).rename(holder.id, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${holder.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(holdersProvider.notifier).delete(holder.id);
    }
  }

  void _blockedDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Can't remove this holder"),
        content: Text(
          '${holder.name} still has $fdCount FD${fdCount == 1 ? '' : 's'} tagged to them. '
          'Reassign or delete those first.',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../holders/application/holders_providers.dart';
import '../../application/fixed_deposits_providers.dart';

/// A row of holder filter chips above the deposits list — an addition the
/// mockup doesn't depict (it has no multi-holder concept). Deliberately
/// hidden when there's only one holder, so a single-holder user sees the
/// mockup's layout unchanged.
class HolderFilterRow extends ConsumerWidget {
  const HolderFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holders = ref.watch(holdersProvider);
    if (holders.length <= 1) return const SizedBox.shrink();

    final selected = ref.watch(holderFilterProvider);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => ref.read(holderFilterProvider.notifier).state = null,
          ),
          for (final holder in holders) ...[
            const SizedBox(width: 8),
            _Chip(
              label: holder.name,
              selected: selected == holder.id,
              onTap: () => ref.read(holderFilterProvider.notifier).state = holder.id,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.pillLabel.copyWith(color: selected ? AppColors.heroOnDark : AppColors.text),
        ),
      ),
    );
  }
}

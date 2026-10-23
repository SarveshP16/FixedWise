import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/selectable_chip.dart';
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
          SelectableChip(
            label: 'All',
            selected: selected == null,
            onTap: () => ref.read(holderFilterProvider.notifier).state = null,
          ),
          for (final holder in holders) ...[
            const SizedBox(width: 8),
            SelectableChip(
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

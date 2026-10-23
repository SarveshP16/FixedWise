import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/fixedwise_card.dart';

/// The dashboard's 3 quick-action buttons (`.quick .qbtn`): New deposit,
/// Calculator, and Interest & TDS — the per-financial-year interest, TDS
/// and DICGC-cover summary (`TaxSummaryScreen`).
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.add,
            label: 'New',
            onTap: () => context.push('/deposits/new'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.calculate_outlined,
            label: 'Calculator',
            onTap: () => context.go('/calculator'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.receipt_long_outlined,
            label: 'Tax & TDS',
            onTap: () => context.push('/tax'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FixedwiseCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.brassDeep, size: 20),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.quickActionLabel),
        ],
      ),
    );
  }
}

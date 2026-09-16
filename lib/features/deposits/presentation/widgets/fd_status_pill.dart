import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';

/// The colored status pill shown on `FdCard` and the detail screen for
/// anything other than a plain, comfortably-running deposit — "Maturing
/// soon" (within `FixedDeposit.maturingSoonWindow`) or "Matured"/"Closed
/// early" once it's done. Renders nothing for [FdCardStatus.active], so
/// call sites can drop it in unconditionally.
class FdStatusPill extends StatelessWidget {
  const FdStatusPill({super.key, required this.deposit});

  final FixedDeposit deposit;

  @override
  Widget build(BuildContext context) {
    final status = deposit.cardStatus;
    switch (status) {
      case FdCardStatus.active:
        return const SizedBox.shrink();
      case FdCardStatus.maturingSoon:
        return PillBadge(
          label: 'Maturing soon',
          background: AppColors.maturingSoonTint,
          textColor: AppColors.maturingSoonText,
        );
      case FdCardStatus.done:
        return PillBadge(
          label: deposit.status == FdStatus.closedEarly ? 'Closed early' : 'Matured',
          background: AppColors.doneTint,
          textColor: AppColors.textSoft,
        );
    }
  }
}

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
        final isClosedEarly = deposit.status == FdStatus.closedEarly;
        return PillBadge(
          label: isClosedEarly ? 'Closed early' : 'Matured',
          // Matured (ran its full term) reads as a small win, so it
          // borrows the sage "growth" treatment used elsewhere for
          // positive figures; closed early stays the neutral/muted
          // look — ending a term early isn't itself good or bad, but
          // it's clearly *different* from a deposit that matured.
          background: isClosedEarly ? AppColors.doneTint : AppColors.sageTint,
          textColor: isClosedEarly ? AppColors.textSoft : AppColors.growthText,
        );
    }
  }
}

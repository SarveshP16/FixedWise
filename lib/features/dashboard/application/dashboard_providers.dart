import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/calculations/maturity_calculator.dart';
import '../../deposits/application/fixed_deposits_providers.dart';
import '../../deposits/domain/fd_status.dart';
import '../../deposits/domain/fixed_deposit.dart';

/// Everything the dashboard's hero, ladder, and "Maturing soon" list need,
/// composed once here so the screen itself stays purely presentational.
class DashboardSummary {
  const DashboardSummary({
    required this.totalAccruedValue,
    required this.overallGrowthPercent,
    required this.ladderEntries,
    required this.maturingSoon,
  });

  /// Sum of every active deposit's value-so-far (see
  /// `MaturityCalculator.fdAccruedValue`) — the hero's "Total across
  /// deposits" figure.
  final double totalAccruedValue;

  /// The relabeled growth pill's percentage — see
  /// `MaturityCalculator.overallGrowthPercent`.
  final double overallGrowthPercent;

  /// Up to 4 soonest-maturing active deposits, feeding the ladder bars.
  final List<FixedDeposit> ladderEntries;

  /// The first 2 of [ladderEntries], feeding the "Maturing soon" mini-list.
  final List<FixedDeposit> maturingSoon;
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final deposits = ref.watch(fixedDepositsProvider);
  final active = deposits.where((fd) => fd.status == FdStatus.active).toList();

  final totalAccrued = active.fold<double>(0, (sum, fd) => sum + MaturityCalculator.fdAccruedValue(fd));
  final growth = MaturityCalculator.overallGrowthPercent(active);
  final ladder = MaturityCalculator.nextMaturingDeposits(deposits, count: 4);

  return DashboardSummary(
    totalAccruedValue: totalAccrued,
    overallGrowthPercent: growth,
    ladderEntries: ladder,
    maturingSoon: ladder.take(2).toList(),
  );
});

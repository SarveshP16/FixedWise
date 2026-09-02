import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/ghost_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/fd_status.dart';
import '../widgets/certificate_share.dart';
import '../widgets/close_early_dialog.dart';
import '../widgets/growth_curve_painter.dart';
import '../widgets/info_table.dart';

/// FixedWise's Deposit detail screen (the mockup's "Deposit detail &
/// growth" screen).
class DepositDetailScreen extends ConsumerWidget {
  const DepositDetailScreen({super.key, required this.depositId});

  final String depositId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deposits = ref.watch(fixedDepositsProvider);
    final matches = deposits.where((fd) => fd.id == depositId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('This deposit no longer exists.')),
      );
    }
    final deposit = matches.first;

    final isActive = deposit.status == FdStatus.active;
    final value = isActive ? MaturityCalculator.maturityValue(deposit) : (deposit.closedValue ?? 0);
    final growthAmount = value - deposit.principalAmount;
    final points = MaturityCalculator.growthCurvePoints(deposit);
    final progress = isActive ? MaturityCalculator.fdProgressFraction(deposit) : 1.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  children: [
                    BorderedIconButton(icon: Icons.arrow_back, size: 32, onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deposit.bankName, style: AppTypography.detailTitle),
                          Text(
                            'Fixed deposit${deposit.fdNumber != null ? ' · #${deposit.fdNumber}' : ''}',
                            style: AppTypography.detailSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isActive ? 'Value at maturity' : 'Value at closure', style: AppTypography.subtleLabel),
                    Text(formatCurrency(ref, value), style: AppTypography.bigFigure),
                    const SizedBox(height: 4),
                    Text(
                      '${growthAmount >= 0 ? '↑' : '↓'} ${formatCurrency(ref, growthAmount.abs())} '
                      '${growthAmount >= 0 ? 'above' : 'below'} principal · ${deposit.interestRatePercent.toStringAsFixed(1)}% p.a.',
                      style: AppTypography.growthNote,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                child: SizedBox(
                  height: 96,
                  child: CustomPaint(
                    painter: GrowthCurvePainter(points: points, progressFraction: progress),
                    size: Size.infinite,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: InfoTable(deposit: deposit),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Row(
                  children: [
                    if (isActive)
                      Expanded(
                        child: GhostButton(
                          label: 'Close early',
                          onPressed: () => showCloseEarlyDialog(context, ref, deposit),
                        ),
                      ),
                    if (isActive) const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Download certificate',
                        onPressed: () =>
                            shareDepositCertificate(deposit, currencySymbol: ref.read(currencySymbolProvider)),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.sageTint, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'This deposit was closed early on ${deposit.closedDate!.day}/${deposit.closedDate!.month}/${deposit.closedDate!.year}.',
                      style: AppTypography.rateLine,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/ghost_button.dart';
import '../../../../core/widgets/linear_progress_track.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';
import '../widgets/certificate_share.dart';
import '../widgets/close_early_dialog.dart';
import '../widgets/delete_deposit_dialog.dart';
import '../widgets/fd_status_pill.dart';
import '../widgets/growth_curve_painter.dart';
import '../widgets/info_table.dart';
import '../widgets/renew_deposit_flow.dart';

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
    final dateFormat = DateFormat('d MMM yyyy');

    // Still counting toward its own maturity date — the only state where
    // "Close early" makes sense and the growth curve isn't finished yet.
    // `isClosed` (closedEarly/matured) and a quietly-past-due-but-untouched
    // active deposit both count as "done" for display purposes.
    final isRunning = deposit.status == FdStatus.active && DateTime.now().isBefore(deposit.maturityDate);
    final isDone = !isRunning;
    final value = deposit.isClosed ? (deposit.closedValue ?? 0) : MaturityCalculator.maturityValue(deposit);
    final growthAmount = value - deposit.principalAmount;
    final points = MaturityCalculator.growthCurvePoints(deposit);
    final progress = isRunning ? MaturityCalculator.fdProgressFraction(deposit) : 1.0;

    // Both directions of the renewal chain: what this one was renewed
    // from (if anything), and what it was renewed into (if anything) —
    // scanning the whole list is cheap for a single holder's FDs.
    final renewedFromMatches = deposits.where((fd) => fd.id == deposit.renewedFromId);
    final renewedFrom = deposit.renewedFromId == null || renewedFromMatches.isEmpty ? null : renewedFromMatches.first;
    final renewedInto = findRenewalOf(deposits, deposit.id);

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
                    FdStatusPill(deposit: deposit),
                    const SizedBox(width: 8),
                    BorderedIconButton(
                      icon: Icons.delete_outline,
                      size: 32,
                      onTap: () async {
                        final deleted = await showDeleteDepositDialog(context, ref, deposit);
                        if (deleted && context.mounted) context.pop();
                      },
                    ),
                  ],
                ),
              ),
              if (renewedFrom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: _HistoryLink(
                    label: 'Renewed from a deposit opened ${dateFormat.format(renewedFrom.openedDate)} →',
                    onTap: () => context.push('/deposits/${renewedFrom.id}'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deposit.isClosed ? 'Value at closure' : 'Value at maturity', style: AppTypography.subtleLabel),
                    Text(formatCurrency(ref, value), style: AppTypography.bigFigure),
                    const SizedBox(height: 4),
                    Text(
                      '${growthAmount >= 0 ? '↑' : '↓'} ${formatCurrency(ref, growthAmount.abs())} '
                      '${growthAmount >= 0 ? 'above' : 'below'} principal · ${formatRatePercent(deposit.interestRatePercent)}% p.a.',
                      style: AppTypography.growthNote,
                    ),
                  ],
                ),
              ),
              if (isRunning)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressTrack(fraction: progress),
                      const SizedBox(height: 6),
                      Text(_timeRemaining(deposit.maturityDate), style: AppTypography.footNote),
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
                    if (isRunning) ...[
                      Expanded(
                        child: GhostButton(
                          label: 'Close early',
                          onPressed: () => showCloseEarlyDialog(context, ref, deposit),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (isDone && renewedInto == null) ...[
                      Expanded(
                        child: PrimaryButton(
                          label: 'Renew deposit',
                          onPressed: () => showRenewDepositFlow(context, ref, deposit),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: isRunning
                          ? PrimaryButton(
                              label: 'Download certificate',
                              onPressed: () =>
                                  shareDepositCertificate(deposit, currencySymbol: currencySymbol),
                            )
                          : GhostButton(
                              label: 'Download certificate',
                              onPressed: () =>
                                  shareDepositCertificate(deposit, currencySymbol: currencySymbol),
                            ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.sageTint, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_bannerText(deposit, dateFormat), style: AppTypography.rateLine),
                        if (renewedInto != null) ...[
                          const SizedBox(height: 8),
                          _HistoryLink(
                            label: 'View renewed deposit →',
                            onTap: () => context.push('/deposits/${renewedInto.id}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "1 year 2 months left" / "3 months left" / "45 days left" / "1 day
  /// left" — calendar-based (like [FixedDeposit.maturityDate] itself),
  /// not a raw day count divided by 30, so it agrees with the tenure the
  /// deposit was actually opened with.
  String _timeRemaining(DateTime maturityDate) {
    final now = DateTime.now();
    var months = (maturityDate.year - now.year) * 12 + (maturityDate.month - now.month);
    if (maturityDate.day < now.day) months -= 1;

    if (months <= 0) {
      final days = maturityDate.difference(now).inDays;
      if (days <= 0) return 'Maturing today';
      return days == 1 ? '1 day left' : '$days days left';
    }

    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (years == 0) {
      return remainingMonths == 1 ? '1 month left' : '$remainingMonths months left';
    }
    final yearPart = years == 1 ? '1 year' : '$years years';
    if (remainingMonths == 0) return '$yearPart left';
    final monthPart = remainingMonths == 1 ? '1 month' : '$remainingMonths months';
    return '$yearPart $monthPart left';
  }

  String _bannerText(FixedDeposit deposit, DateFormat dateFormat) {
    switch (deposit.status) {
      case FdStatus.closedEarly:
        return 'This deposit was closed early on ${dateFormat.format(deposit.closedDate!)}.';
      case FdStatus.matured:
        return 'This deposit matured on ${dateFormat.format(deposit.maturityDate)}.';
      case FdStatus.active:
        // Past its own maturity date but never formally closed/renewed.
        return "This deposit matured on ${dateFormat.format(deposit.maturityDate)} and hasn't been renewed yet.";
    }
  }
}

class _HistoryLink extends StatelessWidget {
  const _HistoryLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(label, style: AppTypography.rateLine.copyWith(decoration: TextDecoration.underline)),
    );
  }
}

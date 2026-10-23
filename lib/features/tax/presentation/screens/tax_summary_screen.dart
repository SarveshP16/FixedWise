import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/calculations/india_tax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/fixedwise_card.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/selectable_chip.dart';
import '../../../deposits/application/fixed_deposits_providers.dart';
import '../../../holders/application/holders_providers.dart';

/// "Interest & TDS": per financial year, the FD interest each holder
/// earns at each bank (what goes under "Income from other sources" in
/// their ITR), whether it crosses the bank's TDS threshold, and — as of
/// today — whether any holder has more at one bank than DICGC insures.
/// Reached from the dashboard's quick actions.
class TaxSummaryScreen extends ConsumerStatefulWidget {
  const TaxSummaryScreen({super.key});

  @override
  ConsumerState<TaxSummaryScreen> createState() => _TaxSummaryScreenState();
}

class _TaxSummaryScreenState extends ConsumerState<TaxSummaryScreen> {
  FinancialYear _year = FinancialYear.containing(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final current = FinancialYear.containing(DateTime.now());
    final summaries = summariseByHolderAndBank(
      deposits: ref.watch(fixedDepositsProvider),
      holders: ref.watch(holdersProvider),
      year: _year,
    );
    final withInterest = summaries.where((summary) => summary.interest > 0).toList();
    final overInsured = summaries.where((summary) => summary.exceedsDicgcCover).toList();
    final totalInterest = withInterest.fold(0.0, (sum, summary) => sum + summary.interest);
    final totalTds = withInterest.fold(0.0, (sum, summary) => sum + summary.estimatedTds);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            Row(
              children: [
                BorderedIconButton(icon: Icons.arrow_back, size: 32, onTap: () => context.pop()),
                const SizedBox(width: 12),
                Text('Interest & TDS', style: AppTypography.screenTitle),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final year in [current.previous, current, current.next])
                  SelectableChip(label: year.label, selected: year == _year, onTap: () => setState(() => _year = year)),
              ],
            ),
            const SizedBox(height: 16),
            FixedwiseCard(
              child: Row(
                children: [
                  Expanded(child: _Figure(label: 'Interest in ${_year.label}', value: formatCurrency(ref, totalInterest))),
                  Expanded(child: _Figure(label: 'Likely TDS', value: formatCurrency(ref, totalTds))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('By holder and bank'),
            if (withInterest.isEmpty)
              Text('No FD interest falls in ${_year.label}.', style: AppTypography.dateLine)
            else
              for (final summary in withInterest) _InterestRow(summary: summary),
            const SizedBox(height: 20),
            const SectionTitle('Deposit insurance (DICGC)'),
            Text(
              overInsured.isEmpty
                  ? 'Every holder is within the ₹5 lakh per-bank cover today.'
                  : 'DICGC insures up to ₹5 lakh per depositor per bank, principal and interest together. '
                        'Above that, consider splitting across banks or holders.',
              style: AppTypography.dateLine,
            ),
            const SizedBox(height: 8),
            for (final summary in overInsured)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FixedwiseCard(
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${summary.holder.name} · ${summary.bankName}', style: AppTypography.bankName),
                      ),
                      Text(formatCurrency(ref, summary.insuredExposure), style: AppTypography.valueSmall),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Estimates only, not tax advice. Interest is counted as it accrues, the way banks deduct TDS. '
              'TDS is $tdsRatePercent% (20% without PAN) once a bank pays you more than the threshold in a year — '
              '₹50,000, or ₹1 lakh for senior citizens, from FY 2025-26. If your total income is below the taxable '
              'limit, submit Form 15G (or 15H if 60+) to each bank at the start of the year to avoid TDS. Mark senior '
              'citizens in Profile → Holders. DICGC cover also counts savings and current accounts at the same bank.',
              style: AppTypography.footNote,
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.statLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.statFigure),
      ],
    );
  }
}

class _InterestRow extends ConsumerWidget {
  const _InterestRow({required this.summary});

  final HolderBankSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = formatCurrency(ref, summary.tdsThreshold);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FixedwiseCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.bankName, style: AppTypography.bankName),
                  Text(
                    [summary.holder.name, if (summary.holder.isSeniorCitizen) 'Senior citizen'].join(' · '),
                    style: AppTypography.dateLine,
                  ),
                  Text(
                    summary.tdsLikely
                        ? 'Over the $threshold threshold — TDS ≈ ${formatCurrency(ref, summary.estimatedTds)}'
                        : 'Under the $threshold TDS threshold',
                    style: AppTypography.dateLine.copyWith(color: summary.tdsLikely ? AppColors.brassDeep : null),
                  ),
                ],
              ),
            ),
            Text(formatCurrency(ref, summary.interest), style: AppTypography.valueSmall),
          ],
        ),
      ),
    );
  }
}

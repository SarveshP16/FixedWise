import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_title.dart';
import '../../application/dashboard_providers.dart';
import '../widgets/hero_header.dart';
import '../widgets/maturing_soon_list.dart';
import '../widgets/maturity_ladder_chart.dart';
import '../widgets/quick_actions_row.dart';

/// FixedWise's Home tab — the mockup's "Portfolio overview" screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroHeader(totalValue: summary.totalAccruedValue, growthPercent: summary.overallGrowthPercent),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Maturity ladder'),
                  MaturityLadderChart(deposits: summary.ladderEntries),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: const QuickActionsRow(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Maturing soon'),
                  MaturingSoonList(deposits: summary.maturingSoon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

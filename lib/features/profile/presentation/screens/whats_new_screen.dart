import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../data/whats_new.dart';
import '../../domain/whats_new_entry.dart';

/// About's "What's new" screen — user-facing highlights per release, not
/// the developer-facing `CHANGELOG.md`.
class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Row(
                children: [
                  BorderedIconButton(icon: Icons.arrow_back, size: 32, onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  Text("What's new", style: AppTypography.screenTitle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                children: [
                  for (var i = 0; i < whatsNewEntries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 24),
                    _EntrySection(entry: whatsNewEntries[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntrySection extends StatelessWidget {
  const _EntrySection({required this.entry});

  final WhatsNewEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Version ${entry.version} · ${entry.date}', style: AppTypography.sectionTitle),
        const SizedBox(height: 10),
        for (final highlight in entry.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(Icons.circle, size: 5, color: AppColors.brass),
                ),
                Expanded(child: Text(highlight, style: AppTypography.dateLine)),
              ],
            ),
          ),
      ],
    );
  }
}

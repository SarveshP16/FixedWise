import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../application/settings_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

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
                  Text('About', style: AppTypography.screenTitle),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FixedWise', style: AppTypography.bankName),
                  const SizedBox(height: 4),
                  packageInfo.when(
                    data: (info) => Text('Version ${info.version} (${info.buildNumber})', style: AppTypography.dateLine),
                    loading: () => const Text('Version —'),
                    error: (_, _) => const Text('Version unknown'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A fixed deposit tracker and maturity calculator — track every FD across your family, '
                    'see what\'s maturing soon, and get reminded before it does.',
                    style: AppTypography.dateLine,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

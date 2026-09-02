import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/fixedwise_card.dart';
import '../../application/settings_providers.dart';

/// The email feedback/bug reports go to — this is the developer's own
/// personal app; feedback from anyone using it (e.g. a family member
/// added as a Holder) should reach the person who built it.
const _feedbackEmail = 'crystaxitofc@gmail.com';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _feedbackEmail, queryParameters: {'subject': 'FixedWise feedback'});
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('No mail app found — email $_feedbackEmail directly')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            Row(
              children: [
                BorderedIconButton(icon: Icons.arrow_back, size: 32, onTap: () => context.pop()),
                const SizedBox(width: 12),
                Text('About', style: AppTypography.screenTitle),
              ],
            ),
            const SizedBox(height: 16),
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
              "see what's maturing soon, and get reminded before it does.",
              style: AppTypography.dateLine,
            ),
            const SizedBox(height: 16),
            FixedwiseCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, size: 18, color: AppColors.sage),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your data stays on this device unless you connect Google Drive backup. '
                      "FixedWise has no server of its own and doesn't share your information with anyone.",
                      style: AppTypography.dateLine,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FixedwiseCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.new_releases_outlined),
                    title: const Text("What's new"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/whats-new'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Send feedback'),
                    subtitle: const Text(_feedbackEmail),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _sendFeedback(context),
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

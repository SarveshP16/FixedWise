import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/app_lock_controller.dart';
import '../../../../core/security/pin_create_screen.dart';
import '../../../../core/security/pin_verify_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/fixedwise_card.dart';

/// Profile's "Security" card: set up / change / turn off the optional
/// app-wide lock PIN, plus a biometric-unlock shortcut once one's set.
/// Changing or removing an existing PIN requires proving you know it
/// first (or falling back to the device's own lock screen).
class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  Future<void> _setUpPin(BuildContext context) async {
    await showPinCreateFlow(context, title: 'Set an App Lock PIN');
  }

  Future<void> _changePin(BuildContext context) async {
    final verified = await showPinVerifyFlow(context, title: 'Enter current PIN');
    if (!verified || !context.mounted) return;
    await showPinCreateFlow(context, title: 'Set a new PIN');
  }

  Future<void> _turnOff(BuildContext context, WidgetRef ref) async {
    final verified = await showPinVerifyFlow(context, title: 'Enter current PIN');
    if (!verified) return;
    await ref.read(pinServiceProvider).clear();
    await ref.read(appLockProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);
    final deviceAuthAvailable = ref.watch(deviceAuthAvailableProvider).maybeWhen(data: (value) => value, orElse: () => false);

    return FixedwiseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: const Text('App lock'),
            subtitle: Text(lockState.pinConfigured ? 'Enabled' : 'Off — FixedWise opens directly'),
            trailing: lockState.pinConfigured
                ? null
                : FilledButton.tonal(onPressed: () => _setUpPin(context), child: const Text('Set up')),
          ),
          if (lockState.pinConfigured) ...[
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password_outlined),
              title: const Text('Change PIN'),
              onTap: () => _changePin(context),
            ),
            if (deviceAuthAvailable) ...[
              const Divider(height: 1),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Use biometric unlock'),
                subtitle: const Text("Quicker than typing your PIN each time"),
                value: lockState.biometricEnabled,
                onChanged: (value) => ref.read(appLockProvider.notifier).setBiometricEnabled(value),
              ),
            ],
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_open_outlined, color: AppColors.error),
              title: const Text('Turn off app lock', style: TextStyle(color: AppColors.error)),
              onTap: () => _turnOff(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

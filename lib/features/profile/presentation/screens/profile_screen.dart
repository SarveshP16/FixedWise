import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/backup/backup_models.dart';
import '../../../../core/backup/google_drive_backup_service.dart';
import '../../../../core/backup/local_backup_service.dart';
import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/fixedwise_card.dart';
import '../../../../core/widgets/fixedwise_field_shell.dart';
import '../../../deposits/application/fixed_deposits_providers.dart';
import '../../../holders/application/holders_providers.dart';
import '../../application/settings_providers.dart';

/// FixedWise's Profile tab: the app owner's own settings — the mockup's
/// bottom nav includes a Profile destination but designs no screen for
/// it, so this is built from scratch to hold everything app-wide that
/// isn't a specific deposit: display name, currency, reminder lead time,
/// Holders management, data backup, and About.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(displayNameProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final leadDays = ref.watch(notificationLeadDaysProvider);
    final driveEmail = ref.watch(googleDriveConnectedEmailProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            Text('Profile', style: AppTypography.screenTitle),
            const SizedBox(height: 16),
            FixedwiseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FixedwiseFieldShell(
                    label: 'Your name',
                    child: FixedwiseInputBox(
                      child: TextFormField(
                        initialValue: displayName,
                        style: AppTypography.inputText,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onFieldSubmitted: (value) =>
                            ref.read(displayNameProvider.notifier).setName(value.trim().isEmpty ? 'there' : value.trim()),
                      ),
                    ),
                  ),
                  FixedwiseFieldShell(
                    label: 'Currency symbol',
                    child: FixedwiseInputBox(
                      child: TextFormField(
                        initialValue: currencySymbol,
                        style: AppTypography.inputText,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onFieldSubmitted: (value) =>
                            ref.read(currencySymbolProvider.notifier).setSymbol(value.trim().isEmpty ? '\$' : value.trim()),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Maturity reminder'),
                    subtitle: Text('$leadDays day${leadDays == 1 ? '' : 's'} before each FD matures'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: leadDays > 1 ? () => _changeLeadDays(ref, leadDays - 1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _changeLeadDays(ref, leadDays + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FixedwiseCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.group_outlined),
                title: const Text('Holders'),
                subtitle: const Text('Manage who FDs are tagged to'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/holders'),
              ),
            ),
            const SizedBox(height: 16),
            FixedwiseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text('Export to a file'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportToFile(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Import from a file'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _importFromFile(context, ref),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Google Drive backup'),
                    subtitle: Text(driveEmail == null ? 'Not connected' : 'Connected as $driveEmail'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openGoogleDriveOptions(context, ref, driveEmail),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FixedwiseCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('About FixedWise'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/about'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLeadDays(WidgetRef ref, int days) async {
    await ref.read(notificationLeadDaysProvider.notifier).setLeadDays(days);
    await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: days);
  }

  Future<void> _exportToFile(BuildContext context) async {
    try {
      final saved = await LocalBackupService.exportToFile();
      if (!context.mounted || !saved) return;
      _showMessage(context, 'Backup saved');
    } catch (error) {
      if (context.mounted) _showMessage(context, 'Export failed: $error');
    }
  }

  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    ParsedBackup? backup;
    try {
      backup = await LocalBackupService.pickAndParseBackup();
    } catch (error) {
      if (context.mounted) _showMessage(context, '$error');
      return;
    }
    if (backup == null || !context.mounted) return;

    final dateText = backup.exportedAt == null
        ? 'an unknown date'
        : DateFormat('d MMM yyyy').format(backup.exportedAt!);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'This backup was exported on $dateText. Restoring replaces every holder and deposit currently in the app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    await backup.apply();
    ref
      ..invalidate(holdersProvider)
      ..invalidate(fixedDepositsProvider)
      ..invalidate(displayNameProvider)
      ..invalidate(currencySymbolProvider)
      ..invalidate(notificationLeadDaysProvider)
      ..invalidate(googleDriveConnectedEmailProvider);
    await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: ref.read(notificationLeadDaysProvider));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Backup restored')));
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGoogleDriveOptions(BuildContext context, WidgetRef ref, String? connectedEmail) async {
    if (connectedEmail == null) {
      try {
        final email = await GoogleDriveBackupService.instance.connect();
        await ref.read(googleDriveConnectedEmailProvider.notifier).setEmail(email);
      } catch (error) {
        if (context.mounted) _showMessage(context, '$error');
      }
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Back up now'),
              onTap: () => Navigator.of(context).pop('backup'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restore from Drive'),
              onTap: () => Navigator.of(context).pop('restore'),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Disconnect'),
              onTap: () => Navigator.of(context).pop('disconnect'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'backup':
        try {
          await GoogleDriveBackupService.instance.backup();
          if (context.mounted) _showMessage(context, 'Backed up to Google Drive');
        } catch (error) {
          if (context.mounted) _showMessage(context, '$error');
        }
      case 'restore':
        try {
          final backup = await GoogleDriveBackupService.instance.restore();
          if (backup == null) {
            if (context.mounted) _showMessage(context, 'No Drive backup found yet');
            return;
          }
          await backup.apply();
          ref
            ..invalidate(holdersProvider)
            ..invalidate(fixedDepositsProvider)
            ..invalidate(displayNameProvider)
            ..invalidate(currencySymbolProvider)
            ..invalidate(notificationLeadDaysProvider);
          await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: ref.read(notificationLeadDaysProvider));
          if (context.mounted) _showMessage(context, 'Restored from Google Drive');
        } catch (error) {
          if (context.mounted) _showMessage(context, '$error');
        }
      case 'disconnect':
        await GoogleDriveBackupService.instance.disconnect();
        await ref.read(googleDriveConnectedEmailProvider.notifier).setEmail(null);
    }
  }
}

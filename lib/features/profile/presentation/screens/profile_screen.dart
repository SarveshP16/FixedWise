import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/backup/backup_models.dart';
import '../../../../core/backup/google_drive_backup_service.dart';
import '../../../../core/backup/local_backup_service.dart';
import '../../../../core/notifications/maturity_reminder_service.dart';
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
///
/// A `ConsumerStatefulWidget` (not stateless) so the name/currency fields
/// can own real `TextEditingController`s — a `TextFormField`'s
/// `initialValue` is only read once at `initState`, so a stateless
/// rebuild after a provider change never gets reflected in a field the
/// user is looking at, and saving only `onFieldSubmitted` (keyboard
/// "done") meant tapping away without pressing it silently lost the
/// edit. Both fields now save on every keystroke instead, like every
/// other setting on this screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(displayNameProvider));
    _currencyController = TextEditingController(text: ref.read(currencySymbolProvider));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      child: TextField(
                        controller: _nameController,
                        style: AppTypography.inputText,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onChanged: (value) => ref
                            .read(displayNameProvider.notifier)
                            .setName(value.trim().isEmpty ? 'there' : value.trim()),
                      ),
                    ),
                  ),
                  FixedwiseFieldShell(
                    label: 'Currency symbol',
                    child: FixedwiseInputBox(
                      child: TextField(
                        controller: _currencyController,
                        style: AppTypography.inputText,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onChanged: (value) => ref
                            .read(currencySymbolProvider.notifier)
                            .setSymbol(value.trim().isEmpty ? '₹' : value.trim()),
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
                          onPressed: leadDays > 1 ? () => _changeLeadDays(leadDays - 1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _changeLeadDays(leadDays + 1),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Send test notification'),
                    subtitle: const Text('Fires in 10 seconds, the same way a real reminder does'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _sendTestNotification,
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
                    onTap: _exportToFile,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Import from a file'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _importFromFile,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Google Drive backup'),
                    subtitle: Text(driveEmail == null ? 'Not connected' : 'Connected as $driveEmail'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openGoogleDriveOptions(driveEmail),
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

  Future<void> _changeLeadDays(int days) async {
    await ref.read(notificationLeadDaysProvider.notifier).setLeadDays(days);
    await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: days);
  }

  Future<void> _sendTestNotification() async {
    try {
      await MaturityReminderService.instance.sendTestReminder();
      if (mounted) _showMessage('Test notification scheduled — watch for it in ~10 seconds');
    } catch (error) {
      if (mounted) _showMessage("Couldn't schedule it: $error");
    }
  }

  Future<void> _exportToFile() async {
    try {
      final saved = await LocalBackupService.exportToFile();
      if (!mounted || !saved) return;
      _showMessage('Backup saved');
    } catch (error) {
      if (mounted) _showMessage('Export failed: $error');
    }
  }

  Future<void> _importFromFile() async {
    ParsedBackup? backup;
    try {
      backup = await LocalBackupService.pickAndParseBackup();
    } catch (error) {
      if (mounted) _showMessage('$error');
      return;
    }
    if (backup == null || !mounted) return;

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
    _nameController.text = ref.read(displayNameProvider);
    _currencyController.text = ref.read(currencySymbolProvider);
    await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: ref.read(notificationLeadDaysProvider));

    if (!mounted) return;
    _showMessage('Backup restored');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGoogleDriveOptions(String? connectedEmail) async {
    if (connectedEmail == null) {
      try {
        final email = await GoogleDriveBackupService.instance.connect();
        await ref.read(googleDriveConnectedEmailProvider.notifier).setEmail(email);
      } catch (error) {
        if (mounted) _showMessage('$error');
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
    if (action == null || !mounted) return;

    switch (action) {
      case 'backup':
        try {
          await GoogleDriveBackupService.instance.backup();
          if (mounted) _showMessage('Backed up to Google Drive');
        } catch (error) {
          if (mounted) _showMessage('$error');
        }
      case 'restore':
        try {
          final backup = await GoogleDriveBackupService.instance.restore();
          if (backup == null) {
            if (mounted) _showMessage('No Drive backup found yet');
            return;
          }
          await backup.apply();
          ref
            ..invalidate(holdersProvider)
            ..invalidate(fixedDepositsProvider)
            ..invalidate(displayNameProvider)
            ..invalidate(currencySymbolProvider)
            ..invalidate(notificationLeadDaysProvider);
          _nameController.text = ref.read(displayNameProvider);
          _currencyController.text = ref.read(currencySymbolProvider);
          await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: ref.read(notificationLeadDaysProvider));
          if (mounted) _showMessage('Restored from Google Drive');
        } catch (error) {
          if (mounted) _showMessage('$error');
        }
      case 'disconnect':
        await GoogleDriveBackupService.instance.disconnect();
        await ref.read(googleDriveConnectedEmailProvider.notifier).setEmail(null);
    }
  }
}

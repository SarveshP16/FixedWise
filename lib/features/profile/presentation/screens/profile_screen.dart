import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/backup/auto_backup.dart';
import '../../../../core/backup/auto_backup_frequency.dart';
import '../../../../core/backup/backup_folder_service.dart';
import '../../../../core/backup/backup_models.dart';
import '../../../../core/backup/local_backup_service.dart';
import '../../../../core/notifications/maturity_reminder_service.dart';
import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_preference.dart';
import '../../../../core/utils/currency_formatter.dart' show settingsRepositoryProvider;
import '../../../../core/widgets/fixedwise_card.dart';
import '../../../../core/widgets/fixedwise_field_shell.dart';
import '../../../../core/widgets/fixedwise_segmented_control.dart';
import '../../../deposits/application/fixed_deposits_providers.dart';
import '../../../holders/application/holders_providers.dart';
import '../../application/settings_providers.dart';
import '../widgets/security_section.dart';

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

class _ProfileScreenState extends ConsumerState<ProfileScreen> with WidgetsBindingObserver {
  late final TextEditingController _nameController;

  /// `null` while the first check is still in flight. Re-checked whenever
  /// the app resumes, since granting it happens on the OS Settings screen
  /// — outside this widget entirely — and there's no other signal that
  /// tells us it changed.
  bool? _exactAlarmsGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController = TextEditingController(text: ref.read(displayNameProvider));
    _refreshExactAlarmStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshExactAlarmStatus();
  }

  Future<void> _refreshExactAlarmStatus() async {
    final granted = await MaturityReminderService.instance.canScheduleExactAlarms();
    if (mounted) setState(() => _exactAlarmsGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final leadDays = ref.watch(notificationLeadDaysProvider);
    final backupFolder = ref.watch(backupFolderProvider);

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
                    child: TextField(
                      controller: _nameController,
                      style: AppTypography.inputText,
                      onChanged: (value) =>
                          ref.read(displayNameProvider.notifier).setName(value.trim().isEmpty ? 'there' : value.trim()),
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
                  if (_exactAlarmsGranted == false)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.warning_amber_rounded, color: AppColors.brassDeep),
                      title: const Text('Reminders need one more permission'),
                      subtitle: const Text("Tap to allow \"Alarms & reminders\" — otherwise they won't fire"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _requestExactAlarmPermission,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SecuritySection(),
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
                  Text('Appearance', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  FixedwiseFieldShell(
                    label: 'Theme',
                    child: FixedwiseSegmentedControl<ThemePreference>(
                      options: ThemePreference.values,
                      labelBuilder: (value) => value.label,
                      value: ref.watch(themePreferenceProvider),
                      onChanged: (value) => ref.read(themePreferenceProvider.notifier).setPreference(value),
                    ),
                  ),
                ],
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
                  if (BackupFolderService.instance.isSupported) ...[
                    const Divider(height: 24),
                    Text('Automatic backups', style: AppTypography.sectionTitle),
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_outlined),
                      title: const Text('Backup folder'),
                      subtitle: Text(backupFolder?.name ?? 'Not set — tap to choose a folder'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _chooseBackupFolder,
                    ),
                    if (backupFolder != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: FixedwiseFieldShell(
                          label: 'Back up automatically',
                          child: FixedwiseSegmentedControl<AutoBackupFrequency>(
                            options: AutoBackupFrequency.values,
                            labelBuilder: (value) => value.label,
                            value: ref.watch(autoBackupFrequencyProvider),
                            onChanged: (value) => ref.read(autoBackupFrequencyProvider.notifier).setFrequency(value),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 4),
                        child: Text(_lastBackupLabel(), style: AppTypography.dateLine),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.save_outlined),
                        title: const Text('Back up now'),
                        onTap: _backUpNow,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.restore),
                        title: const Text('Restore from backup folder'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _restoreFromFolder,
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'FixedWise keeps the last $autoBackupsToKeep automatic backups in this folder. Pick a folder '
                        'your sync app mirrors (Nextcloud, Syncthing, Drive…) for an off-device copy. Android also '
                        'backs up app data to your Google account when device backup is on.',
                        style: AppTypography.dateLine,
                      ),
                    ),
                  ],
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

  Future<void> _requestExactAlarmPermission() async {
    await MaturityReminderService.instance.requestExactAlarmPermissionNow();
    // The OS Settings screen this opens is a separate Activity, so by the
    // time control returns here the user has already backed out of it —
    // safe to re-check immediately rather than waiting for
    // didChangeAppLifecycleState's resume signal.
    await _refreshExactAlarmStatus();
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

    await _confirmAndApply(backup);
  }

  /// Shared tail of every restore path: confirm (naming the backup's own
  /// date), apply, then refresh everything that reads the restored boxes.
  Future<void> _confirmAndApply(ParsedBackup backup) async {
    final dateText = backup.exportedAt == null
        ? 'an unknown date'
        : DateFormat('d MMM yyyy, h:mm a').format(backup.exportedAt!);
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
      ..invalidate(notificationLeadDaysProvider)
      ..invalidate(autoBackupFrequencyProvider)
      ..invalidate(themePreferenceProvider);
    _nameController.text = ref.read(displayNameProvider);
    await rescheduleAll(ref.read(fixedDepositsProvider), leadDays: ref.read(notificationLeadDaysProvider));

    if (!mounted) return;
    _showMessage('Backup restored');
  }

  String _lastBackupLabel() {
    final lastBackupAt = ref.watch(lastAutoBackupAtProvider);
    if (lastBackupAt == null) return 'No backup yet';
    return 'Last backup: ${DateFormat('d MMM yyyy, h:mm a').format(lastBackupAt)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseBackupFolder() async {
    final BackupFolder? folder;
    try {
      folder = await BackupFolderService.instance.pickFolder();
    } catch (error) {
      if (mounted) _showMessage("Couldn't use that folder: $error");
      return;
    }
    if (folder == null) return;

    final previous = ref.read(backupFolderProvider);
    if (previous != null && previous.treeUri != folder.treeUri) {
      await BackupFolderService.instance.release(previous.treeUri);
    }
    await ref.read(backupFolderProvider.notifier).setFolder(folder);
    // Choosing a folder is a clear signal backups are wanted — don't make
    // the user find a second switch before anything actually happens.
    if (ref.read(autoBackupFrequencyProvider) == AutoBackupFrequency.off) {
      await ref.read(autoBackupFrequencyProvider.notifier).setFrequency(AutoBackupFrequency.weekly);
    }
    await _backUpNow();
  }

  Future<void> _backUpNow() async {
    try {
      final at = await backUpToFolderNow(settings: ref.read(settingsRepositoryProvider));
      ref.read(lastAutoBackupAtProvider.notifier).record(at);
      if (mounted) _showMessage('Backed up to ${ref.read(backupFolderProvider)?.name ?? 'your folder'}');
    } catch (error) {
      if (mounted) _showMessage('Backup failed: $error');
    }
  }

  Future<void> _restoreFromFolder() async {
    final folder = ref.read(backupFolderProvider);
    if (folder == null) return;

    final List<BackupFolderFile> files;
    try {
      files =
          (await BackupFolderService.instance.listFiles(folder.treeUri))
              .where((file) => file.name.startsWith('fixedwise-') && file.name.endsWith('.json'))
              .toList()
            ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } catch (error) {
      if (mounted) _showMessage("Couldn't read the backup folder: $error");
      return;
    }
    if (!mounted) return;
    if (files.isEmpty) {
      _showMessage('No FixedWise backups in ${folder.name} yet');
      return;
    }

    final chosen = await showModalBottomSheet<BackupFolderFile>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final file in files)
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(file.name),
                subtitle: Text(DateFormat('d MMM yyyy, h:mm a').format(file.lastModified)),
                onTap: () => Navigator.of(context).pop(file),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    try {
      final backup = parseBackup(await BackupFolderService.instance.readText(chosen.uri));
      if (mounted) await _confirmAndApply(backup);
    } catch (error) {
      if (mounted) _showMessage('$error');
    }
  }
}

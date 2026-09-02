import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/deposits/domain/fd_status.dart';
import '../../features/deposits/domain/fixed_deposit.dart';

const _channelId = 'fd_maturity_reminders';
const _channelName = 'Maturity reminders';
const _channelDescription = "Reminders before a Fixed Deposit's maturity date";

/// Schedules and cancels exact-time local notifications for an FD's
/// upcoming maturity. One notification id per deposit (derived from its
/// own id), so re-scheduling — an edit, or a lead-time change — always
/// replaces the previous reminder rather than stacking a second one.
///
/// Uses [AndroidScheduleMode.exactAllowWhileIdle] (needs the separate
/// "Alarms & reminders" permission on Android 12+, requested below) —
/// an inexact alarm was found to silently never fire once the app's
/// process is frozen in the background, see
/// `pulse-app-notification-manifest-gotcha` in this app family's shared
/// engineering notes. Mirrors Pulse's `TaskReminderService` almost
/// exactly.
class MaturityReminderService {
  MaturityReminderService._();

  static final MaturityReminderService instance = MaturityReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Sets up the notification channel and local timezone every launch,
  /// and — only when [requestPermissions] is true — also requests the
  /// runtime notification + exact-alarm permissions. Safe to call more
  /// than once — later calls are a no-op.
  ///
  /// [requestPermissions] should be true at most once ever per install:
  /// Android's "Alarms & reminders" grant opens a full-screen Settings
  /// page rather than an in-app dialog, so asking on every app launch
  /// until the user grants it is a real "the app hijacks itself on open"
  /// complaint, not just noisy. The caller (`main.dart`) tracks whether
  /// it's already asked via `SettingsRepository.
  /// getNotificationPermissionsRequested`.
  ///
  /// Every plugin call in this class is wrapped in try/catch: a reminder
  /// is a nice-to-have layered on top of Deposits, never something that
  /// should be able to break creating/editing/closing an FD if the
  /// platform channel isn't there (as in widget tests, which run with no
  /// real plugin registered) or a device-specific notification quirk
  /// throws.
  Future<void> init({bool requestPermissions = false}) async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Timezone lookup can fail on some devices/emulators — falling back
      // to `timezone`'s UTC default beats crashing app startup over it.
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      await _androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      if (requestPermissions) {
        await _androidPlugin?.requestNotificationsPermission();

        // Android 12+ needs this granted separately from the notification
        // permission above before an exact alarm can be scheduled at all.
        await _androidPlugin?.requestExactAlarmsPermission();
      }
    } catch (error, stackTrace) {
      debugPrint('MaturityReminderService.init failed: $error\n$stackTrace');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Whether this app can currently schedule exact alarms — Android's
  /// "Alarms & reminders" special access, without which every
  /// `zonedSchedule` call throws `PlatformException(
  /// exact_alarms_not_permitted)`. `true` on platforms/OS versions where
  /// this isn't even a concept (iOS, pre-Android-12) rather than treating
  /// "not applicable" as "not granted".
  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _androidPlugin?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the OS's exact-alarm grant screen on demand — unlike [init]'s
  /// automatic, once-ever request, this is meant to be wired to a button
  /// the user explicitly taps (Profile's "Send test notification"/reminder
  /// settings), so it's fine to call every time regardless of whether
  /// permission was asked for before, and even if it's already granted
  /// (a no-op in that case).
  Future<void> requestExactAlarmPermissionNow() async {
    try {
      await _androidPlugin?.requestExactAlarmsPermission();
    } catch (error, stackTrace) {
      debugPrint('MaturityReminderService.requestExactAlarmPermissionNow failed: $error\n$stackTrace');
    }
  }

  int _notificationIdFor(String depositId) => depositId.hashCode & 0x7fffffff;

  /// Schedules (or replaces) [deposit]'s reminder to fire [leadDays] before
  /// its maturity date at 09:00 local time. No-ops if that time has
  /// already passed, or the deposit isn't active.
  Future<void> scheduleReminder(FixedDeposit deposit, {required int leadDays}) async {
    if (deposit.status != FdStatus.active) {
      await cancelReminder(deposit.id);
      return;
    }

    final maturityDate = deposit.maturityDate;
    final fireDate = DateTime(maturityDate.year, maturityDate.month, maturityDate.day - leadDays, 9);
    if (!fireDate.isAfter(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id: _notificationIdFor(deposit.id),
        title: '${deposit.bankName} matures soon',
        body: _bodyFor(deposit, maturityDate),
        scheduledDate: tz.TZDateTime.from(fireDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: deposit.id,
      );
    } catch (error, stackTrace) {
      debugPrint('MaturityReminderService.scheduleReminder failed: $error\n$stackTrace');
    }
  }

  /// Notification id reserved for [sendTestReminder] — outside the range
  /// `depositId.hashCode & 0x7fffffff` could ever collide with by
  /// construction (that mask always produces a non-negative int; this is
  /// negative), so a test reminder can never clash with, or get silently
  /// replaced by, a real FD's.
  static const _testNotificationId = -1;

  /// Schedules a one-off test reminder [delay] from now, through the
  /// exact same `zonedSchedule` + exact-alarm path a real maturity
  /// reminder uses — unlike firing a notification immediately via
  /// `.show()`, this actually exercises the fragile part (whether the OS
  /// will wake the app to deliver a *scheduled* alarm), which is what you
  /// want to verify on a real device rather than trusting it'll work in
  /// months when a real FD matures. See Profile's "Send test
  /// notification" action.
  Future<void> sendTestReminder({Duration delay = const Duration(seconds: 10)}) async {
    final fireDate = DateTime.now().add(delay);
    await _plugin.zonedSchedule(
      id: _testNotificationId,
      title: 'FixedWise test reminder',
      body: 'If you see this, maturity reminders will work.',
      scheduledDate: tz.TZDateTime.from(fireDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String depositId) async {
    try {
      await _plugin.cancel(id: _notificationIdFor(depositId));
    } catch (error, stackTrace) {
      debugPrint('MaturityReminderService.cancelReminder failed: $error\n$stackTrace');
    }
  }

  String _bodyFor(FixedDeposit deposit, DateTime maturityDate) {
    return 'Matures ${DateFormat('d MMM yyyy').format(maturityDate)}';
  }
}

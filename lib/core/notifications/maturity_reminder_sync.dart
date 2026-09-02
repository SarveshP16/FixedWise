import '../../features/deposits/domain/fd_status.dart';
import '../../features/deposits/domain/fixed_deposit.dart';
import 'maturity_reminder_service.dart';

/// Thin call sites that keep [MaturityReminderService] in sync with the
/// deposits repository — kept separate from `FixedDepositsNotifier` itself
/// so that notifier stays a plain repository-backed state holder, and from
/// the settings side so a lead-time change doesn't need to know about
/// every write path.

/// Call after creating or editing a deposit — (re)schedules its reminder,
/// replacing any previous one for the same FD.
Future<void> onDepositSaved(FixedDeposit deposit, {required int leadDays}) {
  return MaturityReminderService.instance.scheduleReminder(deposit, leadDays: leadDays);
}

/// Call after deleting a deposit, or marking it closed early.
Future<void> onDepositRemoved(String depositId) {
  return MaturityReminderService.instance.cancelReminder(depositId);
}

/// Call whenever the notification lead-time setting changes — every active
/// deposit's reminder moves, so all of them need re-scheduling at once.
Future<void> rescheduleAll(List<FixedDeposit> deposits, {required int leadDays}) async {
  for (final deposit in deposits) {
    if (deposit.status == FdStatus.active) {
      await MaturityReminderService.instance.scheduleReminder(deposit, leadDays: leadDays);
    }
  }
}

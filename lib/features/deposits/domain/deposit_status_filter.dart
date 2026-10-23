import 'fd_status.dart';
import 'fixed_deposit.dart';

/// The Deposits list's top-level view: everything, or narrowed to one
/// lifecycle bucket. [all] preserves the list's default Active/Matured/
/// Closed-early grouping; the other three narrow to just that bucket.
enum DepositStatusFilter {
  all(label: 'All'),
  active(label: 'Active'),
  matured(label: 'Matured'),
  closedEarly(label: 'Closed early');

  const DepositStatusFilter({required this.label});

  final String label;
}

/// Which non-[DepositStatusFilter.all] bucket [deposit] belongs in — the
/// single source of truth shared by [DepositStatusFilter] filtering and
/// the Deposits list's section grouping, so "closed early" vs "matured"
/// is defined in exactly one place.
DepositStatusFilter depositStatusOf(FixedDeposit deposit) {
  if (deposit.status == FdStatus.closedEarly) return DepositStatusFilter.closedEarly;
  if (deposit.cardStatus == FdCardStatus.done) return DepositStatusFilter.matured;
  return DepositStatusFilter.active;
}

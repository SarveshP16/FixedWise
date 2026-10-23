/// An FD's lifecycle state. Note this only covers *formal* closure —
/// `active` still covers a deposit that has quietly sailed past its own
/// maturity date but hasn't been renewed or closed out yet (see
/// `FixedDeposit.isMaturedAsOf`); nothing flips it automatically.
enum FdStatus {
  active(storageKey: 'active'),
  closedEarly(storageKey: 'closedEarly'),

  /// Ran its full term and was then formally closed — either via "Renew"
  /// (see `showRenewDepositFlow`) or a plain manual close-out after
  /// maturity. Distinct from [closedEarly] so history/detail text can say
  /// "matured" rather than "closed early", and so [closedValue] can hold
  /// the full maturity value rather than a pro-rata one.
  matured(storageKey: 'matured');

  const FdStatus({required this.storageKey});

  final String storageKey;

  static FdStatus fromStorageKey(String key) {
    return FdStatus.values.firstWhere((value) => value.storageKey == key, orElse: () => FdStatus.active);
  }
}

/// The three "looks" a deposit can render with on cards/badges — coarser
/// than [FdStatus], since cards don't distinguish *why* a deposit is done
/// (matured vs. closed early), only that it is. See
/// `FixedDeposit.cardStatusAsOf`.
enum FdCardStatus {
  /// Still running, with more than [FixedDeposit.maturingSoonWindow] left.
  active,

  /// Still running (status still [FdStatus.active]), but due within
  /// [FixedDeposit.maturingSoonWindow].
  maturingSoon,

  /// Nothing left to track: matured (whether or not it's been formally
  /// closed/renewed yet) or closed early.
  done,
}

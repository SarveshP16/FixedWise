/// An FD's lifecycle state. `matured` is not a separate stored value — it's
/// derived (see `FixedDeposit.isMatured`) from `active` plus today's date
/// versus the maturity date, so nothing has to remember to flip it.
enum FdStatus {
  active(storageKey: 'active'),
  closedEarly(storageKey: 'closedEarly');

  const FdStatus({required this.storageKey});

  final String storageKey;

  static FdStatus fromStorageKey(String key) {
    return FdStatus.values.firstWhere((value) => value.storageKey == key, orElse: () => FdStatus.active);
  }
}

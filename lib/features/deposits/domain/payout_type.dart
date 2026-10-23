/// Whether an FD's interest is reinvested (compounds toward a bigger
/// maturity value) or paid out to the holder each compounding period
/// (principal alone is returned at maturity). See
/// `core/calculations/maturity_calculator.dart` for how this changes every
/// formula.
enum PayoutType {
  cumulative(storageKey: 'cumulative', label: 'Cumulative'),
  payout(storageKey: 'payout', label: 'Non-Cumulative');

  const PayoutType({required this.storageKey, required this.label});

  final String storageKey;
  final String label;

  static PayoutType fromStorageKey(String key) {
    return PayoutType.values.firstWhere((value) => value.storageKey == key, orElse: () => PayoutType.cumulative);
  }
}

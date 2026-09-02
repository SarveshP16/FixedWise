/// How often a cumulative FD's interest compounds per year. Stored by
/// [storageKey] rather than enum index, so reordering this enum can never
/// silently corrupt already-saved records.
enum CompoundingFrequency {
  monthly(periodsPerYear: 12, storageKey: 'monthly', label: 'Monthly'),
  quarterly(periodsPerYear: 4, storageKey: 'quarterly', label: 'Quarterly'),
  annually(periodsPerYear: 1, storageKey: 'annually', label: 'Annually');

  const CompoundingFrequency({required this.periodsPerYear, required this.storageKey, required this.label});

  /// `n` in the compound-interest formula `P(1+r/n)^(nt)`.
  final int periodsPerYear;
  final String storageKey;
  final String label;

  static CompoundingFrequency fromStorageKey(String key) {
    return CompoundingFrequency.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => CompoundingFrequency.quarterly,
    );
  }
}

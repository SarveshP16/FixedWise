/// How the Deposits list orders its entries — chosen from a bottom sheet
/// off the list's sort button.
enum DepositSort {
  /// The list's default — matches `FixedDepositRepository.getAll`'s own
  /// ordering, so picking this after switching away restores exactly
  /// what you'd see having never touched sort at all.
  recentlyAdded(label: 'Recently added'),

  maturityDate(label: 'Maturity date'),
  amount(label: 'Amount'),
  bankName(label: 'Bank name');

  const DepositSort({required this.label});

  final String label;
}

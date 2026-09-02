/// Central registry of Hive box names, so a typo can't silently open a
/// second box instead of the one every other file uses.
class HiveBoxes {
  HiveBoxes._();

  static const holders = 'holders';
  static const fixedDeposits = 'fixed_deposits';
  static const settings = 'settings';
}

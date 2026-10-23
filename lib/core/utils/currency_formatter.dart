import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/profile/data/settings_repository.dart';

/// FixedWise's currency symbol — Fixed Deposits are predominantly an
/// Indian banking product, so this is a fixed rupee rather than trying to
/// infer one from the device's locale (which is unreliable on many
/// phones/emulators regardless of the user's actual region) or offering
/// it as a user setting — FixedWise shows a single symbol only; it never
/// converts between currencies.
const currencySymbol = '₹';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository.openDefault();
});

/// The [NumberFormat] used for every money figure in the app — whole
/// units only (no decimal places), matching the mockup's rounded figures,
/// with [currencySymbol] and Indian lakh/crore grouping (₹12,34,567, not
/// ₹1,234,567).
final currencyFormatProvider = Provider<NumberFormat>((ref) {
  return NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol, decimalDigits: 0);
});

/// Formats [amount] with the app's currency symbol. Uses `ref.watch`, so
/// calling this from a `build()` method subscribes that widget to the
/// (fixed) format provider like any other provider read.
String formatCurrency(WidgetRef ref, num amount) => ref.watch(currencyFormatProvider).format(amount);

/// An interest rate as Indian banks quote it — up to two decimals, no
/// trailing zeros (7.25, 7.5, 7), since rounding 7.25% to "7.3%" would
/// misstate the booked rate.
String formatRatePercent(double ratePercent) => NumberFormat('0.##').format(ratePercent);

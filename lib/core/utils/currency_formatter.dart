import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/profile/data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository.openDefault();
});

/// The currency symbol shown throughout the app (e.g. `$`, `₹`, `€`) —
/// defaults once from the device's locale the first time the app runs
/// (FD products are common well beyond USD locales), then is fully
/// user-editable in Profile. FixedWise shows a single symbol only; it
/// never converts between currencies (deliberate MVP simplification — no
/// FX, no per-currency digit-grouping rules).
final currencySymbolProvider = StateNotifierProvider<CurrencySymbolNotifier, String>((ref) {
  return CurrencySymbolNotifier(ref.watch(settingsRepositoryProvider));
});

class CurrencySymbolNotifier extends StateNotifier<String> {
  CurrencySymbolNotifier(this._repository) : super(_repository.getCurrencySymbol() ?? _deviceDefaultSymbol());

  final SettingsRepository _repository;

  Future<void> setSymbol(String symbol) async {
    state = symbol;
    await _repository.setCurrencySymbol(symbol);
  }

  static String _deviceDefaultSymbol() {
    final localeName = PlatformDispatcher.instance.locale.toString();
    try {
      return NumberFormat.simpleCurrency(locale: localeName).currencySymbol;
    } catch (_) {
      return '\$';
    }
  }
}

/// The [NumberFormat] used for every money figure in the app — whole
/// units only (no decimal places), matching the mockup's rounded figures,
/// with the currently selected currency symbol and standard comma
/// grouping.
final currencyFormatProvider = Provider<NumberFormat>((ref) {
  final symbol = ref.watch(currencySymbolProvider);
  return NumberFormat.currency(locale: 'en_US', symbol: symbol, decimalDigits: 0);
});

/// Formats [amount] with the app's current currency symbol. Uses
/// `ref.watch`, so calling this from a `build()` method subscribes that
/// widget to currency changes.
String formatCurrency(WidgetRef ref, num amount) => ref.watch(currencyFormatProvider).format(amount);

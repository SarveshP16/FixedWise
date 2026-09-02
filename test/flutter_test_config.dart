import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file. Without this, `google_fonts` tries to
/// fetch Fraunces/IBM Plex Sans over the network the first time
/// `AppTypography` builds a style, which has no network access in the
/// test sandbox and made widget tests hang for minutes instead of failing
/// fast. Disabling runtime fetching makes it fall back to the platform's
/// default font immediately — text still renders, just not in the real
/// typeface, which doesn't matter for a widget test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}

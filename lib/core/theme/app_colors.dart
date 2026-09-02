import 'package:flutter/material.dart';

/// Every color used anywhere in FixedWise, named after the source mockup's
/// CSS custom properties (and the mockup-only literals it used directly
/// without a variable). No screen should ever write a raw hex — reach for
/// a constant here instead, adding one if a new need shows up.
abstract final class AppColors {
  // ---- mockup `:root` custom properties ----
  static const ink = Color(0xFF101A2E);
  static const ink2 = Color(0xFF18274A);
  static const paper = Color(0xFFF6F2E8);
  static const card = Color(0xFFFFFDF8);
  static const brass = Color(0xFFB8863B);
  static const brassDeep = Color(0xFF8A611F);
  static const brassTint = Color(0xFFEFE0C2);
  static const sage = Color(0xFF4F7A5C);
  static const sageTint = Color(0xFFDDE8DE);
  static const text = Color(0xFF1B2430);
  static const textSoft = Color(0xFF69707E);
  static const line = Color(0xFFE5DDC9);
  static const lineDark = Color(0xFF2A3A63);

  /// The mockup's outer page background behind the phone frames — only
  /// relevant if we ever render a device-frame preview, never used inside
  /// the real app UI itself.
  static const outerBackdrop = Color(0xFFEAE5D8);

  // ---- literals the mockup used directly, not hoisted to `:root` ----
  /// Hero header's muted secondary text ("Good morning, …", stat labels)
  /// on the dark `--ink` background.
  static const heroMuted = Color(0xFF9AA6C4);

  /// Hero header's primary text color on the dark `--ink` background
  /// (also used by the dark `.calc-out` panel).
  static const heroOnDark = Color(0xFFF4EFE2);

  /// Text color inside the hero's growth-delta pill.
  static const deltaPillText = Color(0xFFA9D3B3);

  /// Background of the hero's growth-delta pill — `rgba(79,122,92,0.28)`,
  /// i.e. `sage` at 28% opacity.
  static const deltaPillBackground = Color(0x474F7A5C);

  /// The four ascending shades used by the dashboard's maturity-ladder
  /// bars, lightest (soonest/smallest) to darkest (`brassDeep`, the
  /// furthest-out/largest).
  static const ladderStep1 = Color(0xFFE8D2A6);
  static const ladderStep2 = Color(0xFFD9B877);
  static const ladderStep3 = Color(0xFFC49C4D);
  static const ladderStep4 = brassDeep;

  /// Text color for the deposits-list summary strip's "cell" figures and
  /// the sage-colored rate/growth annotations (`Corinthian`-style green,
  /// darker than plain `sage` for contrast on the paper background).
  static const growthText = Color(0xFF2E4D38);

  /// Text on the brass CTA button (`.cta`, "Create deposit").
  static const ctaText = Color(0xFF3A2705);
}

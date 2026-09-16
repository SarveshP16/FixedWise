import 'package:flutter/material.dart';

/// FixedWise's full color palette — every screen reaches for [AppColors.x],
/// never a raw hex. Each getter resolves against whichever of
/// [AppPalette.light]/[AppPalette.dark] matches [AppColors.brightness],
/// which `FixedWiseApp`'s `MaterialApp.builder` keeps in sync with the
/// active [ThemeData] once per frame — by the time any widget below it
/// builds, [AppColors.x] already reflects what's actually on screen.
///
/// [AppTheme] itself doesn't go through these dynamic getters — building a
/// `ThemeData` that's unconditionally light or unconditionally dark needs
/// [AppPalette.light]/[AppPalette.dark] directly, not "whatever the current
/// brightness happens to be".
abstract final class AppColors {
  static Brightness brightness = Brightness.light;

  static AppPalette get _p => brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

  static Color get ink => _p.ink;
  static Color get ink2 => _p.ink2;
  static Color get paper => _p.paper;
  static Color get card => _p.card;
  static Color get brass => _p.brass;
  static Color get brassDeep => _p.brassDeep;
  static Color get brassTint => _p.brassTint;
  static Color get sage => _p.sage;
  static Color get sageTint => _p.sageTint;
  static Color get text => _p.text;
  static Color get textSoft => _p.textSoft;
  static Color get line => _p.line;

  /// Hero header's muted secondary text ("Good morning, …", stat labels)
  /// and the calculator output panel's labels — both on the always-dark
  /// `ink` surface, in either theme (see [AppPalette]'s doc comment).
  static Color get heroMuted => _p.heroMuted;

  /// Hero header's primary text color, and the live-calculator's output
  /// figure — both on the always-dark `ink` surface, in either theme.
  static Color get heroOnDark => _p.heroOnDark;

  /// Text inside the hero's growth-delta pill.
  static Color get deltaPillText => _p.deltaPillText;

  /// Background of the hero's growth-delta pill.
  static Color get deltaPillBackground => _p.deltaPillBackground;

  /// The four ascending shades used by the dashboard's maturity-ladder
  /// bars, lightest/least-emphasized (soonest/smallest) to
  /// darkest/most-saturated (furthest-out/largest) — `ladderStep4`'s bar is
  /// always dark enough that its on-bar label reads in [heroOnDark], same
  /// as [ink]'s panels, regardless of theme.
  static Color get ladderStep1 => _p.ladderStep1;
  static Color get ladderStep2 => _p.ladderStep2;
  static Color get ladderStep3 => _p.ladderStep3;
  static Color get ladderStep4 => _p.ladderStep4;

  /// Text color for the deposits-list summary strip's "cell" figures and
  /// the sage-colored rate/growth annotations.
  static Color get growthText => _p.growthText;

  /// Text on the brass CTA button.
  static Color get ctaText => _p.ctaText;

  static Color get error => _p.error;

  // ---- FD status pill (FdCard / Deposit detail) ----

  static Color get maturingSoonText => _p.maturingSoonText;
  static Color get maturingSoonTint => _p.maturingSoonTint;

  /// Background of the "Matured"/"Closed early" pill once an FD is done —
  /// deliberately muted/neutral rather than green/red, since being done
  /// isn't itself good or bad. Paired with [textSoft].
  static Color get doneTint => _p.doneTint;

  /// The mockup's outer page background behind the phone frames — only
  /// relevant if we ever render a device-frame preview, never used inside
  /// the real app UI, and mockup-only so it doesn't need a dark variant.
  static const outerBackdrop = Color(0xFFEAE5D8);
}

/// One full set of [AppColors]' values. [light] mirrors the source
/// mockup's CSS custom properties (and the mockup-only literals it used
/// directly) 1:1; [dark] is FixedWise's own design — not a mechanical
/// inversion, but the same warm brass/sage/serif identity re-tuned for a
/// dark base. See [AppColors] for what each token is used for.
class AppPalette {
  const AppPalette({
    required this.ink,
    required this.ink2,
    required this.paper,
    required this.card,
    required this.brass,
    required this.brassDeep,
    required this.brassTint,
    required this.sage,
    required this.sageTint,
    required this.text,
    required this.textSoft,
    required this.line,
    required this.heroMuted,
    required this.heroOnDark,
    required this.deltaPillText,
    required this.deltaPillBackground,
    required this.ladderStep1,
    required this.ladderStep2,
    required this.ladderStep3,
    required this.ladderStep4,
    required this.growthText,
    required this.ctaText,
    required this.error,
    required this.maturingSoonText,
    required this.maturingSoonTint,
    required this.doneTint,
  });

  /// Always-dark accent surface: hero header, CTA button fill, the
  /// calculator's output panel, a selected segmented-control/filter chip.
  /// Not "the page's dark color" — a deliberate panel that reads as dark
  /// regardless of which theme is active, which is why it isn't simply
  /// inverted for [dark].
  final Color ink;
  final Color ink2;

  /// Scaffold/page background.
  final Color paper;

  /// Card/surface fill.
  final Color card;

  final Color brass;
  final Color brassDeep;
  final Color brassTint;
  final Color sage;
  final Color sageTint;

  /// Primary text/icon color on [paper]/[card].
  final Color text;
  final Color textSoft;

  /// Hairline borders/dividers on [paper]/[card].
  final Color line;

  final Color heroMuted;
  final Color heroOnDark;
  final Color deltaPillText;
  final Color deltaPillBackground;
  final Color ladderStep1;
  final Color ladderStep2;
  final Color ladderStep3;
  final Color ladderStep4;
  final Color growthText;
  final Color ctaText;
  final Color error;
  final Color maturingSoonText;
  final Color maturingSoonTint;
  final Color doneTint;

  // ---- mockup `:root` custom properties (+ mockup-only literals) ----
  static const light = AppPalette(
    ink: Color(0xFF101A2E),
    ink2: Color(0xFF18274A),
    paper: Color(0xFFF6F2E8),
    card: Color(0xFFFFFDF8),
    brass: Color(0xFFB8863B),
    brassDeep: Color(0xFF8A611F),
    brassTint: Color(0xFFEFE0C2),
    sage: Color(0xFF4F7A5C),
    sageTint: Color(0xFFDDE8DE),
    text: Color(0xFF1B2430),
    textSoft: Color(0xFF69707E),
    line: Color(0xFFE5DDC9),
    heroMuted: Color(0xFF9AA6C4),
    heroOnDark: Color(0xFFF4EFE2),
    deltaPillText: Color(0xFFA9D3B3),
    deltaPillBackground: Color(0x474F7A5C), // sage @ 28%
    ladderStep1: Color(0xFFE8D2A6),
    ladderStep2: Color(0xFFD9B877),
    ladderStep3: Color(0xFFC49C4D),
    ladderStep4: Color(0xFF8A611F), // brassDeep
    growthText: Color(0xFF2E4D38),
    ctaText: Color(0xFF3A2705),
    error: Color(0xFFB3261E),
    maturingSoonText: Color(0xFFB5541F),
    maturingSoonTint: Color(0xFFF1DAC4),
    doneTint: Color(0xFFE7E2D3),
  );

  static const dark = AppPalette(
    // Lighter and more saturated than `paper`/`card` on purpose — in light
    // mode `ink` pops by being the one *darker* thing on a light page; in
    // dark mode it instead pops by being the one more-saturated/lighter
    // navy panel floating on a near-black page.
    ink: Color(0xFF26325A),
    ink2: Color(0xFF34447F),
    paper: Color(0xFF0B0F17),
    card: Color(0xFF161E2C),
    brass: Color(0xFFD3A35E),
    brassDeep: Color(0xFFE3B876),
    brassTint: Color(0xFF2C2313),
    sage: Color(0xFF83AC90),
    sageTint: Color(0xFF1C2A20),
    text: Color(0xFFEDEAE1),
    textSoft: Color(0xFF9BA2B0),
    // The light palette's unused `--line-dark` mockup token — this is
    // exactly the dark hairline it was reserved for.
    line: Color(0xFF2A3A63),
    heroMuted: Color(0xFF9AA6C4),
    heroOnDark: Color(0xFFF4EFE2),
    deltaPillText: Color(0xFFA9D3B3),
    deltaPillBackground: Color(0x474F7A5C),
    // Deliberately decoupled from `brassDeep` (unlike the light palette) —
    // `brassDeep` needs to be light/vivid here (chip-initial text, accent
    // icons on a dark tint), but the ladder's last bar needs to stay dark
    // enough for its on-bar `heroOnDark` label to read.
    ladderStep1: Color(0xFF362B1C),
    ladderStep2: Color(0xFF5C4322),
    ladderStep3: Color(0xFF87611F),
    ladderStep4: Color(0xFF9C6F1E),
    growthText: Color(0xFFA9D3B3),
    ctaText: Color(0xFF3A2705),
    error: Color(0xFFE5626B),
    maturingSoonText: Color(0xFFE0864A),
    maturingSoonTint: Color(0xFF3A2A1C),
    doneTint: Color(0xFF262B22),
  );
}

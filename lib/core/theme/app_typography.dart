import 'package:flutter/material.dart';

import 'app_colors.dart';

/// FixedWise's full set of named text styles, mapped 1:1 from the mockup's
/// CSS type roles. The mockup mixes ~30 distinct role/size/weight/color
/// combinations that don't collapse cleanly into Material's 6 [TextTheme]
/// slots, so — like Wardro's `app_typography.dart` — this exposes a typed
/// getter per role instead. Screens should always reach for one of these
/// rather than building a raw [TextStyle].
///
/// Two families only: 'Fraunces' (serif, headings and big figures) and
/// 'IBM Plex Sans' (everything else), both bundled under `assets/fonts/`
/// (see pubspec.yaml) as static per-weight instances — Fraunces' variable
/// "opsz" optical-size axis from the mockup's `@import` is approximated by
/// picking a weight/size per role rather than reproducing the axis.
///
/// Every size below is still written as the mockup's literal CSS px value
/// (so it stays traceable to the source), but scaled up by [_scale] before
/// use — the mockup itself is a ~296px-wide miniature demo graphic, not a
/// real phone's ~390-430dp logical width, so mapping its px values 1:1 to
/// Flutter's logical pixels rendered every real device's text far smaller
/// than intended (reported as "font looks very small" on an actual phone).
abstract final class AppTypography {
  static const double _scale = 1.3;

  static TextStyle _fraunces({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size * _scale,
    fontWeight: weight,
    color: color,
    height: 1.15,
  );

  static TextStyle _plexSans({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => TextStyle(fontFamily: 'IBM Plex Sans', fontSize: size * _scale, fontWeight: weight, color: color);

  // ---- Fraunces (serif): headings, big figures, chip initials ----

  /// Dashboard hero's "Total across deposits" figure (`.hero .total`, 32px).
  static TextStyle get displayTotal =>
      _fraunces(size: 32, color: AppColors.heroOnDark, weight: FontWeight.w500).copyWith(letterSpacing: -0.2);

  /// Screen headers styled as serif titles (`.h-title`/`.listhead h2`, 22px).
  static TextStyle get screenTitle => _fraunces(size: 22, color: AppColors.text);

  /// A single large digit on the app-lock PIN keypad — not from the
  /// mockup (which has no lock-screen concept), sized to feel like a
  /// natural extension of the same serif/big-figure language.
  static TextStyle get keypadDigit => _fraunces(size: 28, color: AppColors.text);

  /// Summary-strip figures and fd-card amounts (`.summary-strip .cell .n`,
  /// `.fd-card .top .amt`, 16px).
  static TextStyle get statFigure => _fraunces(size: 16, color: AppColors.text);

  /// Deposit detail's "Value at maturity" headline figure
  /// (`.maturity-block .v`, 30px).
  static TextStyle get bigFigure => _fraunces(size: 30, color: AppColors.text);

  /// Live-calculator output figure on the dark `.calc-out` panel (26px).
  static TextStyle get calcFigure => _fraunces(size: 26, color: AppColors.heroOnDark);

  /// Bank-initial avatar letter (`.chip`, 13px).
  static TextStyle get chipInitial => _fraunces(size: 13, color: AppColors.brassDeep);

  // ---- IBM Plex Sans (body/UI) ----

  /// Hero's muted "Good morning, …" / "Total across deposits" labels
  /// (`.hero .greet`/`.total-label`, 12px).
  static TextStyle get heroLabel => _plexSans(size: 12, color: AppColors.heroMuted);

  /// Growth-delta / status pill text (`.pill`, 11px medium).
  static TextStyle get pillLabel => _plexSans(size: 11, weight: FontWeight.w500, color: AppColors.growthText);

  /// Bottom-nav item label (`.bottom-nav .item span`, 10px medium).
  static TextStyle get navLabel => _plexSans(size: 10, weight: FontWeight.w500);

  /// Section headers like "Maturity ladder" / "Maturing soon"
  /// (`.sec-title`, 12px medium, muted).
  static TextStyle get sectionTitle => _plexSans(size: 12, weight: FontWeight.w500, color: AppColors.textSoft);

  /// Maturity-ladder bar's amount label above each bar (`.ladder .bar .amt`,
  /// 9.5px medium).
  static TextStyle get ladderAmount => _plexSans(size: 9.5, weight: FontWeight.w500, color: AppColors.text);

  /// Maturity-ladder month/year label under each bar (`.ladder-labels div`,
  /// 9.5px, muted).
  static TextStyle get ladderDateLabel =>
      _plexSans(size: 9.5, color: AppColors.textSoft).copyWith(height: 1.35);

  /// Quick-action button label ("New" / "Calculator" / "Statements",
  /// `.quick .qbtn span`, 10.5px medium).
  static TextStyle get quickActionLabel => _plexSans(size: 10.5, weight: FontWeight.w500, color: AppColors.text);

  /// Bank name wherever it appears as a row's primary text (`.bank`,
  /// mini-row/fd-card/detail-top, 13.5px medium).
  static TextStyle get bankName => _plexSans(size: 13.5, weight: FontWeight.w500, color: AppColors.text);

  /// Muted date line under a bank name (`.date`/`.foot`, 11px, muted).
  static TextStyle get dateLine => _plexSans(size: 11, color: AppColors.textSoft);

  /// Small trailing value text on a compact row (`.mini-row .value`, 13px
  /// medium).
  static TextStyle get valueSmall => _plexSans(size: 13, weight: FontWeight.w500, color: AppColors.text);

  /// Summary-strip cell caption under a [statFigure] (`.summary-strip .cell
  /// .l`, 10.5px, muted).
  static TextStyle get statLabel => _plexSans(size: 10.5, color: AppColors.textSoft);

  /// Interest-rate + payout-type line under a bank name (`.rate`, 11px
  /// medium, sage).
  static TextStyle get rateLine => _plexSans(size: 11, weight: FontWeight.w500, color: AppColors.sage);

  /// Footer meta row under an fd-card's progress bar (`.foot`, 10.5px,
  /// muted).
  static TextStyle get footNote => _plexSans(size: 10.5, color: AppColors.textSoft);

  /// Detail screen's top title (bank name, `.detail-top .t`, 14px medium).
  static TextStyle get detailTitle => _plexSans(size: 14, weight: FontWeight.w500, color: AppColors.text);

  /// Detail screen's top subtitle (FD number, `.detail-top .t .sub`, 11px,
  /// muted).
  static TextStyle get detailSubtitle => _plexSans(size: 11, color: AppColors.textSoft);

  /// A subtle label above a headline figure (`.maturity-block .l`, 12px,
  /// muted).
  static TextStyle get subtleLabel => _plexSans(size: 12, color: AppColors.textSoft);

  /// Growth annotation under a headline figure (`.maturity-block .growth`,
  /// 11.5px medium, sage).
  static TextStyle get growthNote => _plexSans(size: 11.5, weight: FontWeight.w500, color: AppColors.sage);

  /// Info-table key column (`.table .r .k`, 12.5px, muted).
  static TextStyle get tableKey => _plexSans(size: 12.5, color: AppColors.textSoft);

  /// Info-table value column (`.table .r .v`, 12.5px medium).
  static TextStyle get tableValue => _plexSans(size: 12.5, weight: FontWeight.w500, color: AppColors.text);

  /// Button label, both primary and ghost (`.btn`, 12px medium).
  static TextStyle get buttonLabel => _plexSans(size: 12, weight: FontWeight.w500);

  /// Primary CTA label on the brass button (`.cta`, 14px medium).
  static TextStyle get ctaLabel => _plexSans(size: 14, weight: FontWeight.w500, color: AppColors.ctaText);

  /// A form field's caption label (`.field label`, 11.5px medium, muted).
  static TextStyle get fieldLabel => _plexSans(size: 11.5, weight: FontWeight.w500, color: AppColors.textSoft);

  /// Text typed/shown inside a form field's input shell (`.field .input`,
  /// 14px).
  static TextStyle get inputText => _plexSans(size: 14, color: AppColors.text);

  /// An unselected segmented-control option (`.seg div`, 11.5px, muted).
  static TextStyle get segmentLabel => _plexSans(size: 11.5, color: AppColors.textSoft);

  /// The selected segmented-control option (`.seg div.sel`, 11.5px medium,
  /// on the dark `--ink` fill).
  static TextStyle get segmentLabelSelected =>
      _plexSans(size: 11.5, weight: FontWeight.w500, color: AppColors.heroOnDark);

  /// Tenure slider's live "N months" readout (`.tenure-val`, 12px medium).
  static TextStyle get tenureValue => _plexSans(size: 12, weight: FontWeight.w500, color: AppColors.text);

  /// Live-calculator panel's muted labels (`.calc-out .l`/`.l2`, 11px, on
  /// the dark `--ink` fill).
  static TextStyle get calcLabel => _plexSans(size: 11, color: AppColors.heroMuted);
}

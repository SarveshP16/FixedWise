import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// FixedWise's two themes, built from [AppPalette.light]/[AppPalette.dark]
/// directly rather than the dynamic [AppColors] getters — a `ThemeData`
/// needs to be unconditionally light or unconditionally dark, not "whatever
/// [AppColors.brightness] currently is".
abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.brass,
      onPrimary: p.ctaText,
      secondary: p.sage,
      onSecondary: Colors.white,
      surface: p.card,
      onSurface: p.text,
      outline: p.line,
      error: p.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.paper,
      fontFamily: AppTypography.inputText.fontFamily,

      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: p.line),
        ),
      ),

      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.heroOnDark,
          textStyle: AppTypography.buttonLabel,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // Text/icon on an outline sitting on `paper`/`card`, not on an
          // `ink` panel — needs `text`'s per-theme contrast, not `ink`'s
          // fixed accent-surface tone.
          foregroundColor: p.text,
          textStyle: AppTypography.buttonLabel,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          side: BorderSide(color: p.line),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),

      iconTheme: IconThemeData(color: p.text, size: 18),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: p.brass, width: 1.5),
        ),
        hintStyle: AppTypography.inputText.copyWith(color: p.textSoft),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? p.text : p.textSoft, size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.navLabel.copyWith(color: selected ? p.text : p.textSoft);
        }),
      ),

      // Explicit .copyWith(color: p.x) below rather than trusting each
      // AppTypography style's own baked-in color: those read the *dynamic*
      // AppColors getters, which resolve whatever AppColors.brightness
      // happens to be at the moment this ThemeData is built — not
      // necessarily `brightness`. Widgets that call AppTypography.x
      // directly (the vast majority) are unaffected — they build after
      // MaterialApp.builder has already synced AppColors.brightness to
      // match the theme actually in effect — but anything that falls back
      // to Theme.of(context).textTheme (e.g. an unstyled ListTile Text)
      // would otherwise risk baking in the wrong theme's colors.
      textTheme: TextTheme(
        displayLarge: AppTypography.displayTotal.copyWith(color: p.heroOnDark),
        headlineMedium: AppTypography.bigFigure.copyWith(color: p.text),
        titleLarge: AppTypography.screenTitle.copyWith(color: p.text),
        titleMedium: AppTypography.bankName.copyWith(color: p.text),
        bodyLarge: AppTypography.inputText.copyWith(color: p.text),
        bodyMedium: AppTypography.dateLine.copyWith(color: p.textSoft),
        labelLarge: AppTypography.buttonLabel,
        labelMedium: AppTypography.fieldLabel.copyWith(color: p.textSoft),
      ),
    );
  }
}

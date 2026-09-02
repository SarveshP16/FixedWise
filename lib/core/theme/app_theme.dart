import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// FixedWise's single theme. The mockup is light-only — no dark palette
/// was designed for it — so this deliberately builds only a light
/// [ThemeData] for MVP; a dark mode is an explicit later decision, not an
/// oversight.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brass,
      onPrimary: AppColors.ctaText,
      secondary: AppColors.sage,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.text,
      outline: AppColors.line,
      error: Color(0xFFB3261E),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: AppTypography.inputText.fontFamily,

      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.line),
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.heroOnDark,
          textStyle: AppTypography.buttonLabel,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppTypography.buttonLabel,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          side: const BorderSide(color: AppColors.line),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.ink, size: 18),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.brass, width: 1.5),
        ),
        hintStyle: AppTypography.inputText.copyWith(color: AppColors.textSoft),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.ink : AppColors.textSoft, size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.navLabel.copyWith(color: selected ? AppColors.ink : AppColors.textSoft);
        }),
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.displayTotal,
        headlineMedium: AppTypography.bigFigure,
        titleLarge: AppTypography.screenTitle,
        titleMedium: AppTypography.bankName,
        bodyLarge: AppTypography.inputText,
        bodyMedium: AppTypography.dateLine,
        labelLarge: AppTypography.buttonLabel,
        labelMedium: AppTypography.fieldLabel,
      ),
    );
  }
}

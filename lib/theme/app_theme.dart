import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema global sin cambiar las preferencias almacenadas de Mariana.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final foreground = dark ? AppColors.white : AppColors.navy;
    final background = dark ? AppColors.navy : AppColors.white;
    final accent = dark ? AppColors.yellow : AppColors.cobalt;
    final onAccent = dark ? AppColors.navy : AppColors.white;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.cobalt,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: onAccent,
          secondary: AppColors.yellow,
          onSecondary: AppColors.navy,
          surface: background,
          surfaceContainerLowest: background,
          surfaceContainerLow: background,
          surfaceContainer: background,
          surfaceContainerHigh: background,
          surfaceContainerHighest: background,
          onSurfaceVariant: foreground,
          onSurface: foreground,
          primaryContainer: dark ? AppColors.cobalt : const Color(0xFFEAF2FF),
          onPrimaryContainer: dark ? AppColors.white : AppColors.navy,
        );

    final original = ThemeData(brightness: brightness, useMaterial3: true);
    final dm = original.textTheme.apply(
      fontFamily: 'DMSans',
      bodyColor: foreground,
      displayColor: foreground,
    );
    final headings = dm
        .copyWith(
          displayLarge: const TextStyle(fontFamily: 'CalSans', fontSize: 44),
          displayMedium: const TextStyle(fontFamily: 'CalSans', fontSize: 36),
          headlineLarge: const TextStyle(fontFamily: 'CalSans', fontSize: 32),
          headlineMedium: const TextStyle(fontFamily: 'CalSans', fontSize: 27),
          headlineSmall: const TextStyle(fontFamily: 'CalSans', fontSize: 24),
          titleLarge: const TextStyle(fontFamily: 'CalSans', fontSize: 22),
          titleMedium: const TextStyle(fontFamily: 'DMSans', fontSize: 17),
          bodyLarge: const TextStyle(fontFamily: 'DMSans', fontSize: 16),
          bodyMedium: const TextStyle(fontFamily: 'DMSans', fontSize: 14),
          labelLarge: const TextStyle(fontFamily: 'DMSans', fontSize: 15),
        )
        .apply(bodyColor: foreground, displayColor: foreground);

    RoundedRectangleBorder shape(double radius) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'DMSans',
      textTheme: headings,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.cobalt, width: 2),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'CalSans',
          fontSize: 26,
          color: AppColors.navy,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 16,
          color: AppColors.navy,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cobalt,
        contentTextStyle: const TextStyle(
          fontFamily: 'DMSans',
          color: AppColors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: background,
        textStyle: TextStyle(fontFamily: 'DMSans', color: foreground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'CalSans',
          fontSize: 22,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: dark
            ? AppColors.cobalt.withValues(alpha: 0.18)
            : AppColors.white,
        elevation: 0,
        shape: shape(22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: shape(15),
          textStyle: const TextStyle(fontFamily: 'CalSans', fontSize: 17),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: dark ? AppColors.white : AppColors.navy),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: shape(15),
          textStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? AppColors.cobalt.withValues(alpha: 0.18)
            : AppColors.cobalt.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.yellow : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.cobalt : null,
        ),
      ),
    );
  }
}

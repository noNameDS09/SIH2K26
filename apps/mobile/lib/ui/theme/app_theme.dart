import 'package:flutter/material.dart';
import 'ks_colors.dart';
import 'ks_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: KsColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: KsColors.terracotta,
          brightness: Brightness.light,
          surface: KsColors.background,
        ),
        textTheme: TextTheme(
          bodyMedium: KsTextStyles.body(),
          titleMedium: KsTextStyles.section,
        ),
        splashFactory: InkSparkle.splashFactory,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KsColors.ink,
        ),
      );

  static ThemeData get dark => ThemeData.dark(useMaterial3: true);
}

ThemeData buildKsTheme() => AppTheme.light;

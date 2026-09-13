import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ks_colors.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: KsColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: KsColors.terracotta,
          surface: KsColors.background,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
}

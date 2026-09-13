import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ks_colors.dart';

abstract class KsTextStyles {
  // --- Plus Jakarta Sans (UI text) ---

  static TextStyle label({Color? color, double size = 10, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.plusJakartaSans(
        color: color ?? KsColors.brown2,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.5,
      );

  static TextStyle body({Color? color, double size = 12}) =>
      GoogleFonts.plusJakartaSans(
        color: color ?? KsColors.brown1,
        fontSize: size,
        height: 1.6,
      );

  static TextStyle bodyMedium({Color? color, double size = 13}) =>
      GoogleFonts.plusJakartaSans(
        color: color ?? KsColors.mainText,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle cta({Color? color, double size = 13}) =>
      GoogleFonts.plusJakartaSans(
        color: color ?? KsColors.white,
        fontSize: size,
        fontWeight: FontWeight.w600,
      );

  static TextStyle cardTitle({Color? color, double size = 16}) =>
      GoogleFonts.plusJakartaSans(
        color: color ?? KsColors.mainText,
        fontSize: size,
        fontWeight: FontWeight.w600,
      );

  static TextStyle appBarTitle() =>
      GoogleFonts.plusJakartaSans(
        color: KsColors.mainText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle price({Color? color, double size = 22}) =>
      GoogleFonts.plusJakartaSans(
        color: color ?? KsColors.mainText,
        fontSize: size,
        fontWeight: FontWeight.w700,
      );

  // --- Playfair Display (editorial / heritage headlines) ---

  static TextStyle editorial({Color? color, double size = 28}) =>
      GoogleFonts.playfairDisplay(
        color: color ?? KsColors.mainText,
        fontSize: size,
        height: 1.28,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w700,
      );

  static TextStyle editorialItalic({Color? color, double size = 28}) =>
      GoogleFonts.playfairDisplay(
        color: color ?? KsColors.orange,
        fontSize: size,
        height: 1.28,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      );
}

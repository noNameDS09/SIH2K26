import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ks_colors.dart';

abstract final class KsTextStyles {
  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 25,
        height: 1.08,
        fontWeight: FontWeight.w700,
        color: KsColors.ink,
      );

  static TextStyle get displayAccent => display.copyWith(
        color: KsColors.terracotta,
        fontStyle: FontStyle.italic,
      );

  static TextStyle get section => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: KsColors.ink,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        height: 1.5,
        color: KsColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 9,
        letterSpacing: .5,
        fontWeight: FontWeight.w700,
        color: KsColors.terracotta,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        height: 1.3,
        color: KsColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: KsColors.white,
      );
}

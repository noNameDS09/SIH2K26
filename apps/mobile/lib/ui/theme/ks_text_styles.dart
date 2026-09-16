import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ks_colors.dart';

abstract final class KsTextStyles {
  // ── Static getters (backward-compatible) ──────────────────────────────────

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: KsColors.ink,
        height: 1.2,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: KsColors.ink,
        height: 1.3,
      );

  static TextStyle get buttonLabel => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: KsColors.white,
      );

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

  // NOTE: 'body' and 'label' getters have been replaced by method versions
  // below to avoid the conflict; callers that used the getter form
  // (KsTextStyles.body) should migrate to KsTextStyles.body().

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

  // ── Method versions (used by screen files) ───────────────────────────────

  static TextStyle body({Color? color, double? size}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size ?? 11.5,
        height: 1.5,
        color: color ?? KsColors.textSecondary,
      );

  static TextStyle label({Color? color, double? size}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size ?? 9,
        letterSpacing: .5,
        fontWeight: FontWeight.w700,
        color: color ?? KsColors.terracotta,
      );

  static TextStyle editorial({double? size}) => GoogleFonts.playfairDisplay(
        fontSize: size ?? 24,
        height: 1.12,
        fontWeight: FontWeight.w600,
        color: KsColors.ink,
      );

  static TextStyle editorialItalic({double? size}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size ?? 24,
        height: 1.12,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: KsColors.terracotta,
      );

  static TextStyle bodyMedium({Color? color, double? size}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size ?? 12,
        fontWeight: FontWeight.w600,
        color: color ?? KsColors.ink,
      );

  static TextStyle cta({Color? color, double? size}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size ?? 13,
        fontWeight: FontWeight.w700,
        color: color ?? KsColors.white,
      );

  static TextStyle price({Color? color, double? size}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size ?? 22,
        fontWeight: FontWeight.w800,
        color: color ?? KsColors.ink,
      );
}

import 'package:flutter/material.dart';

abstract final class KsColors {
  // ── Base surfaces ─────────────────────────────────────────────────────────
  static const background   = Color(0xFFFCF9F5);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceWarm  = Color(0xFFF4ECE5);
  static const surfaceMuted = Color(0xFFEDE4DC);

  // Surface aliases used by screens
  static const surface1 = Color(0xFFF4ECE5); // == surfaceWarm
  static const surface2 = Color(0xFFEDE4DC); // == surfaceMuted
  static const surface3 = Color(0xFFF3EDE9); // slightly lighter muted

  // ── Brand – terracotta ────────────────────────────────────────────────────
  static const terracotta     = Color(0xFFAD3E05);
  static const terracottaDark = Color(0xFF873006);
  static const terracottaSoft = Color(0xFFF3DED2);
  static const orange         = Color(0xFFE05A1A);

  // ── Peach scale ───────────────────────────────────────────────────────────
  static const peach1 = Color(0xFFE8C5A8);
  static const peach2 = Color(0xFFD9A882);
  static const peach3 = Color(0xFFF1DBD1);

  // ── Green scale ───────────────────────────────────────────────────────────
  static const green     = Color(0xFF476A35);
  static const greenSoft = Color(0xFFDCECCB);
  static const greenDark = Color(0xFF29481F);

  // Green aliases used by screens
  static const paleGreen = Color(0xFFDCECCB); // == greenSoft
  static const deepGreen = Color(0xFF29481F); // == greenDark

  // ── Text / ink ────────────────────────────────────────────────────────────
  static const ink           = Color(0xFF262321);
  static const textSecondary = Color(0xFF716760);
  static const textMuted     = Color(0xFF9A8D84);
  static const border        = Color(0xFFE4D9D1);
  static const white         = Colors.white;

  // Text aliases used by screens
  static const mainText  = Color(0xFF262321); // == ink
  static const brown3    = Color(0xFF716760); // == textSecondary
  static const brown4    = Color(0xFF9A8D84); // == textMuted
  static const darkBrown = Color(0xFF32302E);
}

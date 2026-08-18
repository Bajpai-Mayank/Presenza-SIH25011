import 'package:flutter/material.dart';

/// Premium monochrome color palette for Smart Circular.
///
/// Primary identity: black + white + glassmorphism.
/// Status colors used sparingly for semantic meaning only.
class AppColors {
  AppColors._();

  // ── Pure Monochrome ──────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ── Dark Surfaces ────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color elevatedDark = Color(0xFF222222);

  // ── Light Surfaces ───────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF0F0F2);
  static const Color elevatedLight = Color(0xFFE8E8EA);

  // ── Grays ────────────────────────────────────────────────────────
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF262626);
  static const Color gray900 = Color(0xFF171717);

  // ── Glass Overlays ───────────────────────────────────────────────
  static Color glassDark = white.withAlpha(13);       // ~5%
  static Color glassDarkBorder = white.withAlpha(25);  // ~10%
  static Color glassLight = black.withAlpha(8);        // ~3%
  static Color glassLightBorder = black.withAlpha(20); // ~8%

  // ── Status Colors (sparingly used) ───────────────────────────────
  static const Color success = Color(0xFF22C55E);      // Green — present
  static const Color error = Color(0xFFEF4444);         // Red — absent/error
  static const Color warning = Color(0xFFF59E0B);       // Amber — warning
  static const Color info = Color(0xFF3B82F6);          // Blue — information

  // Muted status variants for backgrounds
  static const Color successMuted = Color(0xFF0A2E1A);
  static const Color errorMuted = Color(0xFF2E0A0A);
  static const Color warningMuted = Color(0xFF2E2A0A);
  static const Color infoMuted = Color(0xFF0A1A2E);

  // Light mode muted variants
  static const Color successMutedLight = Color(0xFFDCFCE7);
  static const Color errorMutedLight = Color(0xFFFEE2E2);
  static const Color warningMutedLight = Color(0xFFFEF3C7);
  static const Color infoMutedLight = Color(0xFFDBEAFE);

  // ── Attendance Ring Colors ───────────────────────────────────────
  static const Color ringBackground = Color(0xFF2A2A2A);
  static const Color ringForeground = white;
  static const Color ringBackgroundLight = Color(0xFFE0E0E0);
}

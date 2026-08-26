import 'package:flutter/material.dart';

/// Presenza V2 Academic Design System Color Palette.
///
/// Brand identity:
/// - Academic Navy / Indigo (Primary)
/// - Teal / Mint (Secondary & Attendance Positive)
/// - High accessibility contrast for Light and Dark modes
class AppColors {
  AppColors._();

  // ── Brand Identity ────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5);       // Indigo 600
  static const Color primaryDark = Color(0xFF818CF8);   // Indigo 400 (for Dark mode)
  static const Color primaryNavy = Color(0xFF1E3A8A);   // Academic Navy 900
  static const Color primaryDeep = Color(0xFF312E81);   // Indigo 900
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color primaryContainerDark = Color(0xFF1E1B4B);

  static const Color secondary = Color(0xFF0D9488);     // Teal 600
  static const Color secondaryDark = Color(0xFF2DD4BF); // Teal 400 (for Dark mode)
  static const Color secondaryMint = Color(0xFF14B8A6); // Mint
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color secondaryContainerDark = Color(0xFF134E4A);

  // ── Light Surfaces (Eye-Comfort Cream Off-White & Crisp Clean Cards) ──
  static const Color backgroundLight = Color(0xFFF6F8FA); // Soothing Warm Cream-Slate
  static const Color surfaceLight = Color(0xFFFCFCFD);    // Soft Cream White
  static const Color cardLight = Color(0xFFFFFFFF);       // Clean Crisp White Card
  static const Color cardBorderLight = Color(0xFFE2E8F0); // Slate 200 Border
  static const Color elevatedLight = Color(0xFFEEF2F6);   // Soft Elevated Container
  static const Color creamWhite = Color(0xFFFAF9F6);      // Warm Cream White

  // ── Dark Surfaces (Deep Navy / Charcoal, Never Pure Black) ───────
  static const Color backgroundDark = Color(0xFF0B1120); // Deep Navy Midnight
  static const Color surfaceDark = Color(0xFF111827);    // Dark Charcoal / Slate 900
  static const Color cardDark = Color(0xFF1E293B);       // Slate 800
  static const Color cardBorderDark = Color(0xFF334155); // Slate 700
  static const Color elevatedDark = Color(0xFF243248);   // Elevated Slate

  // ── Typography Colors ─────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Deep Slate Navy 900 (High Contrast)
  static const Color textSecondaryLight = Color(0xFF334155); // Slate 700 (Clean, Readable)
  static const Color textMutedLight = Color(0xFF64748B);     // Slate 500 (Legible Muted)

  static const Color textPrimaryDark = Color(0xFFF8FAFC);   // Slate 50 (Crisp Warm White)
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B);     // Slate 500

  // ── Monochromes & Slates ─────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Backward compatibility alias
  static const Color gray50 = slate50;
  static const Color gray100 = slate100;
  static const Color gray200 = slate200;
  static const Color gray300 = slate300;
  static const Color gray400 = slate400;
  static const Color gray500 = slate500;
  static const Color gray600 = slate600;
  static const Color gray700 = slate700;
  static const Color gray800 = slate800;
  static const Color gray900 = slate900;

  // ── Status Colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);      // Emerald 500 — Present / Approved
  static const Color error = Color(0xFFEF4444);        // Red 500 — Absent / Urgent / Reject
  static const Color warning = Color(0xFFF59E0B);      // Amber 500 — Late / Pending
  static const Color info = Color(0xFF0284C7);         // Sky 600 — Info / Excused

  // Muted status backgrounds for Dark Mode
  static const Color successMuted = Color(0xFF064E3B);
  static const Color errorMuted = Color(0xFF7F1D1D);
  static const Color warningMuted = Color(0xFF78350F);
  static const Color infoMuted = Color(0xFF0C4A6E);

  // Muted status backgrounds for Light Mode
  static const Color successMutedLight = Color(0xFFD1FAE5);
  static const Color errorMutedLight = Color(0xFFFEE2E2);
  static const Color warningMutedLight = Color(0xFFFEF3C7);
  static const Color infoMutedLight = Color(0xFFE0F2FE);

  // ── Attendance Visualizer Colors ─────────────────────────────────
  static const Color ringBackground = Color(0xFF1E293B);
  static const Color ringBackgroundLight = Color(0xFFE2E8F0);
  static const Color ringForeground = Color(0xFF10B981);

  // ── Lightweight Border & Overlay Accents ──────────────────────────
  static Color overlayDark = Colors.white.withAlpha(12);
  static Color overlayLight = Colors.black.withAlpha(6);
  static Color glassDark = Color(0xFF1E293B).withAlpha(200);
  static Color glassDarkBorder = Color(0xFF334155);
  static Color glassLight = Colors.white.withAlpha(240);
  static Color glassLightBorder = Color(0xFFE2E8F0);
}

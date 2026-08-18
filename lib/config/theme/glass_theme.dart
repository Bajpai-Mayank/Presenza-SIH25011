import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphism configuration for both light and dark modes.
class GlassTheme {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double blurSigma;
  final double borderRadius;
  final List<BoxShadow> shadows;

  const GlassTheme({
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 1.0,
    this.blurSigma = 20.0,
    this.borderRadius = 20.0,
    this.shadows = const [],
  });

  /// Premium glass effect for dark mode.
  static GlassTheme dark = GlassTheme(
    fillColor: AppColors.white.withAlpha(13),
    borderColor: AppColors.white.withAlpha(25),
    borderWidth: 0.8,
    blurSigma: 24.0,
    borderRadius: 20.0,
    shadows: [
      BoxShadow(
        color: AppColors.black.withAlpha(80),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Glass effect for light mode.
  static GlassTheme light = GlassTheme(
    fillColor: AppColors.white.withAlpha(178),
    borderColor: AppColors.white.withAlpha(230),
    borderWidth: 1.0,
    blurSigma: 16.0,
    borderRadius: 20.0,
    shadows: [
      BoxShadow(
        color: AppColors.black.withAlpha(13),
        blurRadius: 24,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Get the appropriate glass theme for the current brightness.
  static GlassTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Create a BoxDecoration from this glass theme.
  BoxDecoration get decoration => BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      );

  /// Create a BoxDecoration with a custom border radius.
  BoxDecoration decorationWith({double? radius, Color? color}) => BoxDecoration(
        color: color ?? fillColor,
        borderRadius: BorderRadius.circular(radius ?? borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      );

  /// The ImageFilter for BackdropFilter usage.
  ImageFilter get blurFilter =>
      ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
}

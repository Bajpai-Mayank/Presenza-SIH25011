import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';

/// Helper to determine status color based on attendance percentage.
Color getAttendanceStatusColor(double pct) {
  if (pct >= 90) return AppColors.success;      // Emerald
  if (pct >= 75) return AppColors.primary;      // Indigo / Good
  if (pct >= 60) return AppColors.warning;      // Amber / Warning
  return AppColors.error;                       // Coral / Critical
}

/// A modern circular attendance gauge.
class AttendanceRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final String? subtitle;

  const AttendanceRing({
    super.key,
    required this.percentage,
    this.size = 130,
    this.strokeWidth = 10,
    this.foregroundColor,
    this.backgroundColor,
    this.textStyle,
    this.subtitle = 'Overall Attendance',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = foregroundColor ?? getAttendanceStatusColor(percentage);
    final bg = backgroundColor ??
        (isDark ? AppColors.ringBackground : AppColors.ringBackgroundLight);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: bg,
              color: fg,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: textStyle ??
                    Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Linear attendance progress indicator.
class AttendanceProgressBar extends StatelessWidget {
  final double percentage;
  final double height;
  final double threshold;

  const AttendanceProgressBar({
    super.key,
    required this.percentage,
    this.height = 7,
    this.threshold = 75,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;
    final fg = getAttendanceStatusColor(percentage);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: bg,
          color: fg,
        ),
      ),
    );
  }
}

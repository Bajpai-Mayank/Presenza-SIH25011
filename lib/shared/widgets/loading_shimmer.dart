import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:presenza/config/theme/app_colors.dart';

/// Shimmer skeleton loader for Presenza V2.
class LoadingShimmer extends StatelessWidget {
  final Widget child;

  const LoadingShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.cardDark : AppColors.slate200;
    final highlightColor = isDark ? AppColors.elevatedDark : AppColors.slate100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1000),
      child: child,
    );
  }
}

/// A rectangular skeleton box.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.slate200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer card for dashboard and list items.
class CardShimmer extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const CardShimmer({
    super.key,
    this.height = 100,
    this.borderRadius = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.slate200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Full dashboard skeleton loader.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 56, height: 56, borderRadius: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 14, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 180, height: 20, borderRadius: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const CardShimmer(height: 140),
            const SizedBox(height: 20),
            const SkeletonBox(width: 140, height: 18, borderRadius: 4),
            const SizedBox(height: 12),
            const CardShimmer(height: 80),
            const SizedBox(height: 12),
            const CardShimmer(height: 80),
          ],
        ),
      ),
    );
  }
}

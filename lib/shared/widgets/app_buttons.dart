import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

/// Standardized high-performance button widget for Presenza V2.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
    this.padding,
  });

  factory AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    EdgeInsetsGeometry? padding,
  }) =>
      AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        variant: AppButtonVariant.primary,
        fullWidth: fullWidth,
        padding: padding,
      );

  factory AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    EdgeInsetsGeometry? padding,
  }) =>
      AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        variant: AppButtonVariant.secondary,
        fullWidth: fullWidth,
        padding: padding,
      );

  factory AppButton.outlined({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    EdgeInsetsGeometry? padding,
  }) =>
      AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        variant: AppButtonVariant.outlined,
        fullWidth: fullWidth,
        padding: padding,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? (isDark ? AppColors.slate950 : AppColors.white)
                  : (isDark ? AppColors.primaryDark : AppColors.primary),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ],
    );

    Widget btn;

    switch (variant) {
      case AppButtonVariant.primary:
        btn = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(padding: padding),
          child: childContent,
        );
        break;
      case AppButtonVariant.secondary:
        btn = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.secondaryContainerDark : AppColors.secondaryContainer,
            foregroundColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
            padding: padding,
          ),
          child: childContent,
        );
        break;
      case AppButtonVariant.outlined:
        btn = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(padding: padding),
          child: childContent,
        );
        break;
      case AppButtonVariant.text:
        btn = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(padding: padding),
          child: childContent,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

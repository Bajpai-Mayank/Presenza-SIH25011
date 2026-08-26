import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/providers/app_providers.dart';

/// Shown when a user is authenticated via Firebase Auth but
/// their Firestore profile has not been initialized.
class NoProfileScreen extends ConsumerWidget {
  const NoProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                      border: Border.all(
                        color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                      ),
                    ),
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      size: 38,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Profile Not Found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account authentication was verified, but your academic profile record is missing or deleted.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 28),

                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 22,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Administrator',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Please contact the university administration to configure your profile manually. Auto-provisioning is disabled for security reasons.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(authStatusProvider.notifier).refreshProfile(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh Status'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => ref.read(authStatusProvider.notifier).logout(),
                          child: const Text('Sign Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

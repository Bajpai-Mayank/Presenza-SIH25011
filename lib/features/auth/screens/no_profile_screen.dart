import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/providers/app_providers.dart';

/// Shown when a user is authenticated via Firebase Auth but
/// their Firestore profile does not exist.
///
/// This means the user's account has not been provisioned by
/// the institution administrator.
class NoProfileScreen extends ConsumerWidget {
  const NoProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    const Color(0xFF0F0F0F),
                    const Color(0xFF111111),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFEAEAEC),
                    AppColors.backgroundLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.white.withAlpha(13)
                            : AppColors.black.withAlpha(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.white.withAlpha(25)
                              : AppColors.black.withAlpha(15),
                        ),
                      ),
                      child: Icon(
                        Icons.person_off_rounded,
                        size: 40,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Profile Not Found',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your account has been authenticated, but your '
                      'institutional profile has not been set up yet.\n\n'
                      'Please contact your institution administrator to '
                      'provision your account.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                isDark ? AppColors.gray400 : AppColors.gray600,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 32),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.gray400
                                    : AppColors.gray600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your administrator needs to create your '
                                  'profile in the system before you can access '
                                  'the application.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? AppColors.gray400
                                            : AppColors.gray600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassButton(
                      label: 'Sign Out',
                      onPressed: () {
                        ref.read(authStateProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/core/security/attendance_security_controller.dart';
import 'package:presenza/config/theme/app_colors.dart';

class SecurityOverlay extends ConsumerWidget {
  final Widget child;

  const SecurityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(attendanceSecurityProvider);

    if (securityState == SecurityState.compromised) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 64, color: AppColors.error),
                SizedBox(height: 24),
                Text(
                  'Security Violation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Screen recording, casting, or multi-window usage is not allowed during attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}

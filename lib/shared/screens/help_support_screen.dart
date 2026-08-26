import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            if (user?.role == UserRole.student) ..._buildStudentFaqs(context),
            if (user?.role == UserRole.teacher) ..._buildTeacherFaqs(context),
            if (user?.role == UserRole.admin) ..._buildAdminFaqs(context),
            const SizedBox(height: 32),
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Need further assistance? Contact your institution administrator or the IT Helpdesk.'),
                  const SizedBox(height: 16),
                  AppButton.primary(
                    label: 'Email Support',
                    icon: Icons.email_outlined,
                    onPressed: () {
                      // Launch email intent
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentFaqs(BuildContext context) {
    return [
      _buildFaqItem(
        context,
        'How do I mark my attendance?',
        'Navigate to the Home tab and tap the large QR scanner button. Scan the QR code displayed by your teacher. Make sure you are physically inside the classroom and your GPS is enabled.',
      ),
      _buildFaqItem(
        context,
        'My location is not verifying. What should I do?',
        'Ensure that location services are enabled on your device. Stand closer to the front of the classroom and allow a few seconds for the GPS accuracy to improve.',
      ),
      _buildFaqItem(
        context,
        'I forgot my password.',
        'Please contact the Admin office to reset your credentials. For security, self-service resets are currently disabled.',
      ),
    ];
  }

  List<Widget> _buildTeacherFaqs(BuildContext context) {
    return [
      _buildFaqItem(
        context,
        'How do I start an attendance session?',
        'Go to the Dashboard or Attendance tab, select your subject, configure the expiration time, and tap "Generate Session QR Code". Display this QR to the class.',
      ),
      _buildFaqItem(
        context,
        'How do I manually correct a student\'s attendance?',
        'Navigate to the Students tab, tap on a student\'s profile, and select "Correct Attendance". You must provide a reason for the audit log.',
      ),
    ];
  }

  List<Widget> _buildAdminFaqs(BuildContext context) {
    return [
      _buildFaqItem(
        context,
        'How do I view system audit logs?',
        'Audit logs for attendance corrections and circular creation are accessible in the backend Firebase Console under the "audit_logs" collection.',
      ),
      _buildFaqItem(
        context,
        'How do I publish a circular to specific students?',
        'Go to the Circulars tab, create a new post, and select the specific target course and section (batch) from the dropdowns.',
      ),
    ];
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/activity_model.dart';

/// Semantic status badge for attendance, priority, and post statuses.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;
  final bool filled;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
    this.filled = false,
  });

  factory StatusBadge.present({bool small = false}) =>
      StatusBadge(label: 'Present', color: AppColors.success, icon: Icons.check_circle_outline, small: small);
  factory StatusBadge.absent({bool small = false}) =>
      StatusBadge(label: 'Absent', color: AppColors.error, icon: Icons.cancel_outlined, small: small);
  factory StatusBadge.late({bool small = false}) =>
      StatusBadge(label: 'Late', color: AppColors.warning, icon: Icons.schedule_outlined, small: small);
  factory StatusBadge.excused({bool small = false}) =>
      StatusBadge(label: 'Excused', color: AppColors.info, icon: Icons.info_outline, small: small);

  factory StatusBadge.urgent({bool small = false}) =>
      StatusBadge(label: 'Urgent', color: AppColors.error, icon: Icons.priority_high_rounded, small: small, filled: true);
  factory StatusBadge.important({bool small = false}) =>
      StatusBadge(label: 'Important', color: AppColors.warning, icon: Icons.star_border_rounded, small: small);
  factory StatusBadge.official({bool small = false}) =>
      StatusBadge(label: 'Official', color: AppColors.primary, icon: Icons.verified_outlined, small: small);
  factory StatusBadge.pending({bool small = false}) =>
      StatusBadge(label: 'Pending', color: AppColors.warning, icon: Icons.hourglass_empty_rounded, small: small);
  factory StatusBadge.approved({bool small = false}) =>
      StatusBadge(label: 'Approved', color: AppColors.success, icon: Icons.check_rounded, small: small);

  @override
  Widget build(BuildContext context) {
    final bg = filled ? color : color.withAlpha(25);
    final textCol = filled ? Colors.white : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(filled ? 255 : 60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 11 : 13, color: textCol),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textCol,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category chip for campus activity posts.
class CategoryBadge extends StatelessWidget {
  final ActivityCategory category;
  final bool small;

  const CategoryBadge({
    super.key,
    required this.category,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: category.color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: category.color.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: small ? 12 : 14, color: category.color),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: TextStyle(
              color: category.color,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// User role badge.
class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color col;
    String label;
    IconData icon;

    switch (role) {
      case UserRole.student:
        col = AppColors.secondary;
        label = 'Student';
        icon = Icons.school_outlined;
        break;
      case UserRole.teacher:
        col = AppColors.primary;
        label = 'Faculty';
        icon = Icons.person_outline;
        break;
      case UserRole.admin:
        col = const Color(0xFF7C3AED);
        label = 'Administrator';
        icon = Icons.admin_panel_settings_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: col),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: col,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

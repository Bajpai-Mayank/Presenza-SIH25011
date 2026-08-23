import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/features/student/screens/qr_scanner_screen.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Attendance',
    'Activities',
    'Academic Insights',
    'Profile',
  ];

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final notifs = ref.watch(notificationsProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (notifs.isNotEmpty)
                        TextButton(
                          onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
                          child: const Text('Mark all as read'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: notifs.isEmpty
                      ? const Center(
                          child: Text('No new notifications'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: notifs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final n = notifs[index];
                            return GlassCard(
                              padding: const EdgeInsets.all(14),
                              onTap: () {
                                if (!n.isRead) {
                                  ref.read(notificationsProvider.notifier).markAsRead(n.id);
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    n.isRead ? Icons.notifications_none : Icons.notifications_active,
                                    color: n.isRead ? AppColors.gray400 : AppColors.info,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final pages = [
      const _StudentHomeTab(),
      const _StudentAttendanceTab(),
      const _StudentActivitiesTab(),
      const _StudentInsightsTab(),
      const _StudentProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.white.withAlpha(20) : AppColors.black.withAlpha(10),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 0: HOME
// ══════════════════════════════════════════════════════════════════════
class _StudentHomeTab extends ConsumerWidget {
  const _StudentHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProfileProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final schedule = scheduleAsync.value ?? [];
    final circulars = ref.watch(circularsProvider).take(2).toList();
    final streak = ref.watch(attendanceStreakProvider);

    if (student == null) return const LoadingState();

    final subjects = ref.watch(subjectAttendanceProvider);
    final totalPresent = subjects.fold(0, (sum, sa) => sum + sa.present);
    final totalAbsent = subjects.fold(0, (sum, sa) => sum + sa.absent);
    final totalLate = subjects.fold(0, (sum, sa) => sum + sa.late);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.white.withAlpha(20),
                child: Text(
                  student.user.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    student.user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${student.studentId} • Semester ${student.semester}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Attendance Summary Ring Card
          GlassCard(
            child: Row(
              children: [
                AttendanceRing(
                  percentage: overallAttendance,
                  size: 110,
                  strokeWidth: 8,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistency Stat',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            '$streak Day Streak!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Present: ${totalPresent + totalLate}d | Absent: ${totalAbsent}d',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Scanner CTA Card
          GlassCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan QR Attendance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Mark attendance securely in class',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gray400),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Low Attendance Warning Card
          const _AttendanceWarningBanner(),

          // Today's Classes Section
          Text(
            "Today's Classes",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (schedule.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined, color: AppColors.gray400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No classes scheduled for today.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray400),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedule.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = schedule[index];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subjectName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${item.teacherName} • ${item.room}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.startTime.hour}:${item.startTime.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          if (item.attendanceStatus != null)
                            StatusBadge.present(small: true)
                          else
                            Text(
                              'Pending',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),

          // Latest Notices/Circulars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Circulars',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Icon(Icons.chevron_right, color: AppColors.gray400),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: circulars.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = circulars[index];
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(
                          label: c.category.displayName,
                          color: c.isUrgent ? AppColors.error : AppColors.info,
                          small: true,
                        ),
                        Text(
                          '${c.publishDate.day}/${c.publishDate.month}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceWarningBanner extends ConsumerWidget {
  const _AttendanceWarningBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(subjectAttendanceProvider);
    final warnings = list.where((sa) => sa.percentage < 75.0).toList();

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorMuted.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Warning',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 4),
                ...warnings.map(
                  (w) => Text(
                    '• ${w.subjectName} is at ${w.percentage.toStringAsFixed(1)}% (below required 75%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 1: ATTENDANCE OVERVIEW
// ══════════════════════════════════════════════════════════════════════
class _StudentAttendanceTab extends ConsumerWidget {
  const _StudentAttendanceTab();

  void _showSubjectDetail(BuildContext context, SubjectAttendance sa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubjectDetailSheet(subjectAttendance: sa),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(subjectAttendanceProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
    final totalClasses = list.fold(0, (sum, sa) => sum + sa.totalClasses);
    final totalPresent = list.fold(0, (sum, sa) => sum + sa.present + sa.late);
    final totalAbsent = list.fold(0, (sum, sa) => sum + sa.absent);

    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No Subjects Enrolled',
        subtitle: 'Your enrolled subjects will appear here once your course and batch are assigned.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Summary Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AttendanceRing(
                  percentage: overallAttendance,
                  size: 96,
                  strokeWidth: 8,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Standing',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallAttendance >= 75.0
                            ? 'Good Standing'
                            : 'Attendance Alert',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: overallAttendance >= 75.0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total Sessions: $totalClasses • Present: $totalPresent • Absent: $totalAbsent',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum required attendance is 75%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.gray400,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Enrolled Subjects Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrolled Subjects (${list.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Tap for session history',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.gray400,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subject Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sa = list[index];
              final isAboveThreshold = sa.percentage >= 75.0 || sa.totalClasses == 0;

              return GlassCard(
                onTap: () => _showSubjectDetail(context, sa),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sa.subjectName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${sa.subjectCode}${sa.teacherName != null && sa.teacherName!.isNotEmpty ? ' • ${sa.teacherName}' : ''}${sa.credits != null ? ' • ${sa.credits} Credits' : ''}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.gray400,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              sa.totalClasses > 0
                                  ? '${sa.percentage.toStringAsFixed(1)}%'
                                  : 'N/A',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: isAboveThreshold
                                        ? (sa.totalClasses > 0 ? AppColors.white : AppColors.gray400)
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (sa.totalClasses > 0)
                              Text(
                                '${sa.present + sa.late}/${sa.totalClasses} Attended',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AttendanceProgressBar(percentage: sa.percentage),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            sa.getStatusMessage(threshold: 75.0),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isAboveThreshold
                                      ? (sa.totalClasses > 0 ? AppColors.success : AppColors.gray400)
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'History',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.info,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Detailed Session History Modal Sheet for a specific subject
class _SubjectDetailSheet extends ConsumerWidget {
  final SubjectAttendance subjectAttendance;

  const _SubjectDetailSheet({required this.subjectAttendance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
    final allRecords = recordsAsync.value ?? [];
    final subjectRecords = allRecords
        .where((r) => r.subjectId == subjectAttendance.subjectId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subjectAttendance.subjectName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  '${subjectAttendance.subjectCode} • ${subjectAttendance.teacherName ?? 'Assigned Faculty'} • Total Classes: ${subjectAttendance.totalClasses}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Percentage', style: Theme.of(context).textTheme.labelSmall),
                            Text(
                              subjectAttendance.totalClasses > 0
                                  ? '${subjectAttendance.percentage.toStringAsFixed(1)}%'
                                  : 'N/A',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: subjectAttendance.percentage >= 75
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Present / Absent', style: Theme.of(context).textTheme.labelSmall),
                            Text(
                              '${subjectAttendance.present + subjectAttendance.late} P / ${subjectAttendance.absent} A',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requirement', style: Theme.of(context).textTheme.labelSmall),
                            Text(
                              subjectAttendance.getStatusMessage(threshold: 75.0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: subjectAttendance.percentage >= 75
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Session Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Individual Class Sessions (${subjectRecords.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: subjectRecords.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No class attendance records logged yet for this subject.\nScan your teacher\'s QR code in class to record attendance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.gray400),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: subjectRecords.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = subjectRecords[index];
                      final isPresent = record.status.name == 'present' || record.status.name == 'late';

                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isPresent ? AppColors.success : AppColors.error).withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
                                color: isPresent ? AppColors.success : AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('EEE, dd MMM yyyy').format(record.timestamp),
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      StatusBadge(
                                        label: record.status.name.toUpperCase(),
                                        color: isPresent ? AppColors.success : AppColors.error,
                                        small: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Time: ${DateFormat('hh:mm a').format(record.timestamp)}${record.room != null && record.room!.isNotEmpty ? ' • ${record.room}' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        record.verificationMethod == VerificationMethod.qr
                                            ? Icons.qr_code
                                            : Icons.pin_drop_outlined,
                                        size: 12,
                                        color: AppColors.gray400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        record.verificationMethod.displayName,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.gray400,
                                            ),
                                      ),
                                      if (record.locationVerified) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.verified_outlined,
                                          size: 12,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'GPS Verified',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: AppColors.success,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 2: ACADEMIC ACTIVITIES & EVENTS
// ══════════════════════════════════════════════════════════════════════
class _StudentActivitiesTab extends ConsumerStatefulWidget {
  const _StudentActivitiesTab();

  @override
  ConsumerState<_StudentActivitiesTab> createState() => _StudentActivitiesTabState();
}

class _StudentActivitiesTabState extends ConsumerState<_StudentActivitiesTab> {
  String _filter = 'all'; // 'all', 'official', 'events', 'clubs'

  void _showCreateStudentActivityDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final organizerCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    CircularCategory selectedCategory = CircularCategory.event;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Share Student Activity / Event'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Activity Title',
                      hintText: 'e.g. Hackathon Team Formation / AI Club Meetup',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CircularCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Activity Type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: CircularCategory.event, child: Text('Hackathon / Competition')),
                      DropdownMenuItem(value: CircularCategory.holiday, child: Text('Club Meetup / Workshop')),
                      DropdownMenuItem(value: CircularCategory.general, child: Text('Study Group / Project')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: organizerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Club / Student Organizer',
                      hintText: 'e.g. Presenza Robotics Club',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Venue / Online Link',
                      hintText: 'e.g. CS Lab 2 / Google Meet',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details & Description',
                      hintText: 'Describe agenda, prerequisites, or contact info...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final student = ref.read(studentProfileProvider);
                      if (student == null) return;

                      setDialogState(() => isSaving = true);

                      final now = DateTime.now();
                      final uuid = const Uuid().v4().substring(0, 8);
                      final circular = CircularModel(
                        id: 'act-$uuid',
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        category: selectedCategory,
                        priority: CircularPriority.low,
                        authorId: student.user.id,
                        authorName: student.user.name,
                        authorRole: 'student',
                        isOfficial: false,
                        eventType: selectedCategory.name,
                        location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                        organizer: organizerCtrl.text.trim(),
                        publishDate: now,
                        eventDate: now.add(const Duration(days: 2)),
                        createdAt: now,
                        updatedAt: now,
                      );

                      final firestoreService = FirestoreService();
                      await firestoreService.saveCircular(circular);

                      if (mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student activity shared with peers.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Share Activity'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(circularsProvider);
    final filtered = list.where((c) {
      if (_filter == 'official') return c.isOfficial;
      if (_filter == 'events') return !c.isOfficial || c.category == CircularCategory.event;
      if (_filter == 'clubs') return !c.isOfficial;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Chips & Share Button Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filter == 'all',
                        onSelected: (_) => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Official Notices'),
                        selected: _filter == 'official',
                        onSelected: (_) => setState(() => _filter = 'official'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Events & Hackathons'),
                        selected: _filter == 'events',
                        onSelected: (_) => setState(() => _filter = 'events'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Clubs & Meetups'),
                        selected: _filter == 'clubs',
                        onSelected: (_) => setState(() => _filter = 'clubs'),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Share Student Activity',
                onPressed: _showCreateStudentActivityDialog,
              ),
            ],
          ),
        ),

        // Activities List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No activities or notices found in this category.',
                      style: TextStyle(color: AppColors.gray400),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  StatusBadge(
                                    label: c.isOfficial ? 'OFFICIAL ACADEMIC' : 'STUDENT ACTIVITY',
                                    color: c.isOfficial ? AppColors.info : AppColors.secondary,
                                    small: true,
                                  ),
                                  if (c.isUrgent) ...[
                                    const SizedBox(width: 6),
                                    const StatusBadge(
                                      label: 'URGENT',
                                      color: AppColors.error,
                                      small: true,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(c.publishDate),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            c.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.content,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (c.location != null && c.location!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.pin_drop_outlined, size: 14, color: AppColors.gray400),
                                const SizedBox(width: 4),
                                Text(
                                  c.location!,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.organizer != null && c.organizer!.isNotEmpty
                                    ? 'Organized by: ${c.organizer}'
                                    : 'By: ${c.authorName}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray500),
                              ),
                              Text(
                                c.category.displayName,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 3: ACADEMIC INSIGHTS & ATTENDANCE ANALYTICS
// ══════════════════════════════════════════════════════════════════════
class _StudentInsightsTab extends ConsumerStatefulWidget {
  const _StudentInsightsTab();

  @override
  ConsumerState<_StudentInsightsTab> createState() => _StudentInsightsTabState();
}

class _StudentInsightsTabState extends ConsumerState<_StudentInsightsTab> {
  double _extraClassesToSimulate = 3;

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentProfileProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
    final subjects = ref.watch(subjectAttendanceProvider);
    final streak = ref.watch(attendanceStreakProvider);

    final totalClasses = subjects.fold(0, (sum, sa) => sum + sa.totalClasses);
    final totalPresent = subjects.fold(0, (sum, sa) => sum + sa.present + sa.late);
    final totalAbsent = subjects.fold(0, (sum, sa) => sum + sa.absent);

    // Subject Performance Buckets
    final strongSubjects = subjects.where((s) => s.percentage >= 75.0 && s.totalClasses > 0).toList();
    final atRiskSubjects = subjects.where((s) => s.percentage < 75.0 && s.totalClasses > 0).toList();

    // Projected Attendance Math
    final projectedClasses = totalClasses + _extraClassesToSimulate.toInt();
    final projectedPresent = totalPresent + _extraClassesToSimulate.toInt();
    final projectedPercentage = projectedClasses > 0 ? (projectedPresent / projectedClasses) * 100 : 0.0;

    // Badges Data
    final has75Benchmark = overallAttendance >= 75.0 && totalClasses > 0;
    final hasPerfectSubject = subjects.any((s) => s.percentage == 100.0 && s.totalClasses >= 3);
    final hasStreakBadge = streak >= 3;
    final hasFullCurriculum = subjects.length >= 3;
    final hasZeroAbsence = totalAbsent == 0 && totalClasses > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Academic Standing Scorecard
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Health Index',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(
                      label: overallAttendance >= 75.0 ? 'GOOD STANDING' : 'ATTENDANCE ALERT',
                      color: overallAttendance >= 75.0 ? AppColors.success : AppColors.error,
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AttendanceRing(
                      percentage: overallAttendance,
                      size: 90,
                      strokeWidth: 8,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalClasses > 0
                                ? '${overallAttendance.toStringAsFixed(1)}% Overall'
                                : 'No Data Yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalPresent Attended • $totalAbsent Missed • $totalClasses Total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 16, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                '$streak Day Attendance Streak',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Subject Performance Breakdown
          Text(
            'Subject Analysis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          if (atRiskSubjects.isNotEmpty) ...[
            Text(
              '⚠️ Needs Focus (< 75% Attendance)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...atRiskSubjects.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GlassCard(
                    borderColor: AppColors.error.withAlpha(80),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.subjectName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${s.subjectCode} • ${s.present}/${s.totalClasses} Attended', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${s.percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Need ${s.classesNeededForThreshold(75.0)} class(es)',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          if (strongSubjects.isNotEmpty) ...[
            Text(
              '✅ Strong Standing (>= 75% Attendance)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...strongSubjects.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.subjectName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${s.subjectCode} • ${s.present}/${s.totalClasses} Attended', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${s.percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Buffer: ${s.classesCanMiss(75.0)} missable',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 24),

          // Section 3: Academic Milestone Badges
          Text(
            'Academic Milestones & Badges',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _MilestoneBadgeCard(
                icon: Icons.verified_outlined,
                title: '75% Benchmark',
                subtitle: 'Overall attendance >= 75%',
                isUnlocked: has75Benchmark,
                accentColor: AppColors.success,
              ),
              _MilestoneBadgeCard(
                icon: Icons.star_border_outlined,
                title: 'Perfect Record',
                subtitle: '100% in a subject (>=3 classes)',
                isUnlocked: hasPerfectSubject,
                accentColor: Colors.amber,
              ),
              _MilestoneBadgeCard(
                icon: Icons.local_fire_department_outlined,
                title: '3-Day Streak',
                subtitle: 'Consecutive active streak',
                isUnlocked: hasStreakBadge,
                accentColor: Colors.deepOrange,
              ),
              _MilestoneBadgeCard(
                icon: Icons.shield_outlined,
                title: 'Zero Absences',
                subtitle: 'No unexcused absences',
                isUnlocked: hasZeroAbsence,
                accentColor: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 4: What-If Attendance Target Simulator
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Simulator',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '+${_extraClassesToSimulate.toInt()} Classes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Simulate how attending next consecutive classes will boost your overall percentage:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                ),
                Slider(
                  value: _extraClassesToSimulate,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '+${_extraClassesToSimulate.toInt()} classes',
                  onChanged: (val) => setState(() => _extraClassesToSimulate = val),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Projected Attendance:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${projectedPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: projectedPercentage >= 75.0 ? AppColors.success : AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneBadgeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUnlocked;
  final Color accentColor;

  const _MilestoneBadgeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderColor: isUnlocked ? accentColor.withAlpha(100) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 24,
                color: isUnlocked ? accentColor : AppColors.gray500,
              ),
              StatusBadge(
                label: isUnlocked ? 'EARNED' : 'LOCKED',
                color: isUnlocked ? accentColor : AppColors.gray500,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppColors.white : AppColors.gray400,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.gray400,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 4: PROFILE & SETTINGS
// ══════════════════════════════════════════════════════════════════════
class _StudentProfileTab extends ConsumerWidget {
  const _StudentProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProfileProvider);
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];

    if (student == null) return const LoadingState();

    final course = courses.where((c) => c.id == student.courseId).firstOrNull;
    final batch = batches.where((b) => b.id == student.batchId).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Student Profile Card
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.white.withAlpha(20),
                  child: Text(
                    student.user.initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  student.user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  student.user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _ProfileRow(label: 'Student ID', value: student.studentId),
                _ProfileRow(label: 'Course', value: course?.name ?? (student.courseId.isNotEmpty ? student.courseId : 'Not Assigned')),
                _ProfileRow(label: 'Batch / Section', value: batch?.name ?? (student.batchId.isNotEmpty ? student.batchId : 'Not Assigned')),
                _ProfileRow(label: 'Semester', value: student.semester > 0 ? student.semester.toString() : '1'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Out Button
          GlassButton(
            label: 'Logout',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
            filled: false,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

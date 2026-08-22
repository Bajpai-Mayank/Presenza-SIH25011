import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/features/student/screens/mock_camera_screen.dart';

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
    'Circulars',
    'Leaderboard',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      const _StudentHomeTab(),
      const _StudentAttendanceTab(),
      const _StudentCircularsTab(),
      const _StudentLeaderboardTab(),
      const _StudentProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MockCameraScreen()),
              );
            },
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
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Circulars',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
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
    final schedule = ref.watch(todayScheduleProvider);
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
              // TODO: Replace mock with real camera QR scanning implementation.
              // For now, navigate to a placeholder QR scanner screen.
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
                          '${item.startTime.hour}:${item.startTime.minute.toString().padLeft(2, '0')} AM',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(subjectAttendanceProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final sa = list[index];
        final canMiss = sa.classesCanMiss(75.0);
        final needed = sa.classesNeededForThreshold(75.0);

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sa.subjectName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          sa.subjectCode,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${sa.percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: sa.percentage >= 75 ? AppColors.white : AppColors.error,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AttendanceProgressBar(percentage: sa.percentage),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Classes: ${sa.totalClasses} (P: ${sa.present} / A: ${sa.absent})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (sa.percentage >= 75.0)
                    Text(
                      'Can miss $canMiss more class(es)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success),
                    )
                  else
                    Text(
                      'Need $needed class(es) to pass',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 2: CIRCULARS
// ══════════════════════════════════════════════════════════════════════
class _StudentCircularsTab extends ConsumerStatefulWidget {
  const _StudentCircularsTab();

  @override
  ConsumerState<_StudentCircularsTab> createState() => _StudentCircularsTabState();
}

class _StudentCircularsTabState extends ConsumerState<_StudentCircularsTab> {
  CircularCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(circularsProvider);
    final filtered = _selectedCategory == null
        ? list
        : list.where((c) => c.category == _selectedCategory).toList();

    return Column(
      children: [
        // Horizontal Categories List
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              ...CircularCategory.values.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat.displayName),
                    selected: _selectedCategory == cat,
                    onSelected: (sel) => setState(() => _selectedCategory = sel ? cat : null),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notices List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final c = filtered[index];
              return GlassCard(
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
                          '${c.publishDate.day}/${c.publishDate.month}/${c.publishDate.year}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (c.attachmentUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16, color: AppColors.gray400),
                          const SizedBox(width: 6),
                          Text(
                            c.attachmentUrls.first,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                    ],
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
// TAB 3: LEADERBOARD
// ══════════════════════════════════════════════════════════════════════
class _StudentLeaderboardTab extends ConsumerWidget {
  const _StudentLeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(leaderboardProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = list[index];
        final isMe = entry.studentName == 'Arun Kumar';

        return GlassCard(
          borderColor: isMe ? AppColors.white.withAlpha(100) : null,
          child: Row(
            children: [
              Text(
                entry.rank.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: entry.rank == 1 ? Colors.yellow : AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.studentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                    Text(
                      'Streak: ${entry.streak} days',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.attendancePercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        );
      },
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

    if (student == null) return const LoadingState();

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
                _ProfileRow(label: 'Course', value: 'B.Tech CSE'),
                _ProfileRow(label: 'Year & Section', value: '2024 - Sec A'),
                _ProfileRow(label: 'Semester', value: student.semester.toString()),
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

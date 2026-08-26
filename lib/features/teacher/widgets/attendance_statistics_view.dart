import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class AttendanceStatisticsView extends ConsumerStatefulWidget {
  const AttendanceStatisticsView({super.key});

  @override
  ConsumerState<AttendanceStatisticsView> createState() => _AttendanceStatisticsViewState();
}

class _AttendanceStatisticsViewState extends ConsumerState<AttendanceStatisticsView> {
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(teacherSubjectsProvider);
    final teacher = ref.watch(teacherProfileProvider);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Attendance Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Icon(Icons.analytics_outlined, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : null),
            decoration: const InputDecoration(
              labelText: 'Filter by Subject',
              prefixIcon: Icon(Icons.filter_list_rounded, size: 20),
            ),
            items: subjects.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text('${s.code} — ${s.name}', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedSubjectId = val);
            },
          ),
          const SizedBox(height: 20),

          // We'd ideally stream only the selected subject's past sessions/records here.
          // For now, we will compute expected vs present vs absent if we have the data.
          StreamBuilder<List<AttendanceSessionModel>>(
            stream: ref.read(firestoreServiceProvider).streamSessionHistory(teacher?.user.id ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CardShimmer(height: 100);
              }
              final allSessions = snapshot.data ?? [];
              final filtered = _selectedSubjectId != null 
                ? allSessions.where((s) => s.subjectId == _selectedSubjectId).toList()
                : allSessions;

              if (filtered.isEmpty) {
                return const Text('No data for this subject.');
              }

              final totalSessions = filtered.length;
              // Just a dummy representation of expected vs actual for the UI requirement
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatCard(
                    label: 'Sessions',
                    value: totalSessions.toString(),
                    icon: Icons.history,
                    iconColor: AppColors.primary,
                  ),
                  StatCard(
                    label: 'Avg Turnout',
                    value: 'N/A', // This would require querying all records per session
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.success,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

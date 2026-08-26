import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class AttendanceCorrectionModal extends ConsumerStatefulWidget {
  final StudentModel student;

  const AttendanceCorrectionModal({super.key, required this.student});

  static void show(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceCorrectionModal(student: student),
    );
  }

  @override
  ConsumerState<AttendanceCorrectionModal> createState() => _AttendanceCorrectionModalState();
}

class _AttendanceCorrectionModalState extends ConsumerState<AttendanceCorrectionModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Correction',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            'Modifying records for ${widget.student.user.name}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final firestoreService = ref.watch(firestoreServiceProvider);
                return StreamBuilder(
                  stream: firestoreService.streamStudentAttendanceRecords(widget.student.user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading records'));
                    }
                    final records = snapshot.data ?? [];
                    if (records.isEmpty) {
                      return const Center(child: Text('No attendance records found.'));
                    }

                    // Sort by newest first
                    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    return ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('MMM d, yyyy - hh:mm a').format(record.timestamp),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subject: ${record.subjectId}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              DropdownButton<AttendanceStatus>(
                                value: record.status,
                                underline: const SizedBox(),
                                items: AttendanceStatus.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: StatusBadge(
                                      label: s.name.toUpperCase(),
                                      color: _getStatusColor(s),
                                      small: true,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null && newStatus != record.status) {
                                    _confirmCorrection(context, ref, record.id, newStatus);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return AppColors.success;
      case AttendanceStatus.absent: return AppColors.error;
      case AttendanceStatus.late: return AppColors.warning;
      case AttendanceStatus.excused: return AppColors.info;
    }
  }

  void _confirmCorrection(BuildContext context, WidgetRef ref, String recordId, AttendanceStatus newStatus) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Correction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You are changing this record to ${newStatus.name.toUpperCase()}. Provide a reason for this audit log:'),
            const SizedBox(height: 12),
            AppTextField(
              controller: reasonCtrl,
              hintText: 'e.g. System glitch, Medical leave...',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              final user = ref.read(currentUserProvider);
              final firestoreService = ref.read(firestoreServiceProvider);
              
              await firestoreService.correctAttendanceRecord(
                recordId: recordId,
                studentId: widget.student.user.id,
                newStatus: newStatus,
                reason: reasonCtrl.text.trim(),
                correctedByUid: user?.id ?? 'unknown',
                correctedByName: user?.name ?? 'Unknown Admin',
              );
              
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance corrected securely.')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

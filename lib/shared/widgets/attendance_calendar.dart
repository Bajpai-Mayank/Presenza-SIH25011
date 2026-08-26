import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/core/enums/attendance_status.dart';

class AttendanceCalendar extends StatefulWidget {
  final List<AttendanceRecordModel> records;
  final void Function(DateTime selectedDate, List<AttendanceRecordModel> dayRecords)? onDaySelected;

  const AttendanceCalendar({
    super.key,
    required this.records,
    this.onDaySelected,
  });

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  DateTime _currentMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<AttendanceRecordModel> _getRecordsForDay(DateTime day) {
    return widget.records.where((r) {
      return r.timestamp.year == day.year &&
          r.timestamp.month == day.month &&
          r.timestamp.day == day.day;
    }).toList();
  }

  Color _getColorForDay(List<AttendanceRecordModel> dayRecords, bool isDark) {
    if (dayRecords.isEmpty) {
      return isDark ? AppColors.elevatedDark : AppColors.slate100;
    }
    
    // If any present, mark as green for the day overview, else red/yellow
    bool anyPresent = dayRecords.any((r) => r.status == AttendanceStatus.present);
    bool anyLate = dayRecords.any((r) => r.status == AttendanceStatus.late);
    bool anyExcused = dayRecords.any((r) => r.status == AttendanceStatus.excused);

    if (anyPresent) return AppColors.success.withAlpha(isDark ? 80 : 150);
    if (anyLate) return AppColors.warning.withAlpha(isDark ? 80 : 150);
    if (anyExcused) return AppColors.primary.withAlpha(isDark ? 80 : 150);
    return AppColors.error.withAlpha(isDark ? 80 : 150); // Absent
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    // Adjust so Sunday is the first column (if desired) or Monday. 
    // Let's stick to standard DateTime weekdays (1=Mon..7=Sun), but display Sun..Sat
    // To display Sun..Sat, Sunday = 0
    int startingOffset = firstWeekday == 7 ? 0 : firstWeekday;

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _previousMonth,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Days of week row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42, // 6 weeks
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            if (index < startingOffset || index >= startingOffset + daysInMonth) {
              // Empty cells
              return const SizedBox.shrink();
            }

            final day = index - startingOffset + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final dayRecords = _getRecordsForDay(date);
            final cellColor = _getColorForDay(dayRecords, isDark);
            
            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            return GestureDetector(
              onTap: () {
                if (widget.onDaySelected != null) {
                  widget.onDaySelected!(date, dayRecords);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        day.toString(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday ? AppColors.primary : null,
                            ),
                      ),
                    ),
                    if (dayRecords.isNotEmpty)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

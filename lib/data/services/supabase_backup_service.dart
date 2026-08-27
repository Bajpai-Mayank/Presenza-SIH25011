import 'package:presenza/data/models/attendance_model.dart';
import 'package:flutter/foundation.dart';

/// Supabase backup service — currently DISABLED.
/// This is a no-op stub. Supabase backup can be re-enabled later
/// by restoring the Supabase initialization in main.dart and
/// uncommenting the backup logic here.
class SupabaseBackupService {
  /// No-op: Supabase backup is disabled.
  Future<void> backupAttendanceRecord(AttendanceRecordModel record) async {
    debugPrint('Supabase backup disabled. Skipping backup for record: ${record.id}');
  }
}

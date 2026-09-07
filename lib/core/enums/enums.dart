/// Priority level for circulars / notices.
enum CircularPriority {
  normal,
  important,
  urgent;

  String get displayName {
    switch (this) {
      case CircularPriority.normal:
        return 'Normal';
      case CircularPriority.important:
        return 'Important';
      case CircularPriority.urgent:
        return 'Urgent';
    }
  }

  static CircularPriority fromString(String value) {
    return CircularPriority.values.firstWhere(
      (p) => p.name == value.toLowerCase(),
      orElse: () => CircularPriority.normal,
    );
  }
}

/// Category for circulars / notices.
enum CircularCategory {
  academic,
  examination,
  attendance,
  events,
  general,
  emergency,
  fees,
  assignment,
  department;

  String get displayName {
    switch (this) {
      case CircularCategory.academic:
        return 'Academic';
      case CircularCategory.examination:
        return 'Examination';
      case CircularCategory.attendance:
        return 'Attendance';
      case CircularCategory.events:
        return 'Events';
      case CircularCategory.general:
        return 'General';
      case CircularCategory.emergency:
        return 'Emergency';
      case CircularCategory.fees:
        return 'Fees';
      case CircularCategory.assignment:
        return 'Assignment';
      case CircularCategory.department:
        return 'Department';
    }
  }

  static CircularCategory fromString(String value) {
    return CircularCategory.values.firstWhere(
      (c) => c.name == value.toLowerCase(),
      orElse: () => CircularCategory.general,
    );
  }
}

/// Verification method used for attendance.
enum VerificationMethod {
  qr,
  manual,
  faceRecognition,
  biometric;

  String get displayName {
    switch (this) {
      case VerificationMethod.qr:
        return 'QR Code';
      case VerificationMethod.manual:
        return 'Manual';
      case VerificationMethod.faceRecognition:
        return 'Face Recognition';
      case VerificationMethod.biometric:
        return 'Biometric';
    }
  }

  static VerificationMethod fromString(String value) {
    return VerificationMethod.values.firstWhere(
      (v) => v.name == value,
      orElse: () => VerificationMethod.manual,
    );
  }
}

/// Face verification requirement mode.
enum FaceVerificationMode {
  disabled,
  optional,
  required;

  String get displayName {
    switch (this) {
      case FaceVerificationMode.disabled:
        return 'Disabled';
      case FaceVerificationMode.optional:
        return 'Optional';
      case FaceVerificationMode.required:
        return 'Required';
    }
  }

  static FaceVerificationMode fromString(String value) {
    return FaceVerificationMode.values.firstWhere(
      (m) => m.name == value.toLowerCase(),
      orElse: () => FaceVerificationMode.disabled,
    );
  }
}

/// Event type categories.
enum EventType {
  exam,
  assignment,
  meeting,
  academic,
  institutional,
  holiday,
  other;

  String get displayName {
    switch (this) {
      case EventType.exam:
        return 'Exam';
      case EventType.assignment:
        return 'Assignment';
      case EventType.meeting:
        return 'Meeting';
      case EventType.academic:
        return 'Academic';
      case EventType.institutional:
        return 'Institutional';
      case EventType.holiday:
        return 'Holiday';
      case EventType.other:
        return 'Other';
    }
  }

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => EventType.other,
    );
  }
}

/// Notification type.
enum NotificationType {
  circular,
  attendance,
  event,
  academic,
  system;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (n) => n.name == value.toLowerCase(),
      orElse: () => NotificationType.system,
    );
  }
}

/// Conceptual lifecycle state of an attendance session.
enum AttendanceSessionStatus {
  scheduled,
  active,
  expired,
  closed;

  String get displayName {
    switch (this) {
      case AttendanceSessionStatus.scheduled:
        return 'Scheduled';
      case AttendanceSessionStatus.active:
        return 'Live';
      case AttendanceSessionStatus.expired:
        return 'Expired';
      case AttendanceSessionStatus.closed:
        return 'Closed';
    }
  }

  bool get isAcceptingAttendance => this == AttendanceSessionStatus.active;
}

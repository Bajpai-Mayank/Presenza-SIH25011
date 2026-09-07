# PRESENZA — BUG FIX REPORT

**Project:** Presenza (Smart Campus & QR Attendance Platform)  
**Date:** September 7, 2026  
**Auditor / Engineer:** Antigravity AI Engineering  
**Revision:** 2.0  

---

## 1. Executive Summary

This report documents all defect resolutions implemented during the comprehensive engineering audit of **Presenza**. Fixes were focused strictly on identified functional, architectural, security, and responsive defects without rebuilding the application or altering working core subsystems.

---

## 2. Bug Fix Index

| Bug ID | Component | Issue Name | Severity | Status |
|---|---|---|---|---|
| **BUG-01** | Teacher Attendance | Live Session Expiry Lifecycle, Countdown & UI Transitions | **Critical** | **VERIFIED FIXED** |
| **BUG-02** | Student QR Scanner | QR Expiry Detection, Warning UX & Action Recovery | **High** | **VERIFIED FIXED** |
| **BUG-03** | Student QR Scanner | Camera Permission Denial & Torch Stability | **Medium** | **VERIFIED FIXED** |
| **BUG-04** | Core Data / Firestore | Non-Atomic Duplicate Attendance Check in Transaction | **Critical** | **VERIFIED FIXED** |
| **BUG-05** | Security Rules | Unrestricted Expiry in `attendance_records` Creation | **High** | **VERIFIED FIXED** |
| **BUG-06** | Location Service | Error Messaging & Mock Location Guidance | **Medium** | **VERIFIED FIXED** |
| **BUG-07** | Notifications / FCM | Push Notification Missing Android Permissions & Sync Pipeline | **High** | **VERIFIED FIXED** |
| **BUG-08** | Student UI / Home | RenderFlex Overflow on Narrow Screens (320px–360px) | **Medium** | **VERIFIED FIXED** |
| **BUG-09** | Admin UI / Circulars | Dropdown Overflow on Narrow Screens (<360px) | **Low** | **VERIFIED FIXED** |

---

## 3. Detailed Bug Fix Records

### BUG-01: Live Session Expiry Lifecycle, Countdown & Auto-Closure

- **Severity:** Critical
- **Affected Files:**
  - `lib/core/enums/enums.dart`
  - `lib/data/models/attendance_model.dart`
  - `lib/providers/app_providers.dart`
  - `lib/features/teacher/tabs/teacher_attendance_tab.dart`
- **Root Cause:**
  1. `AttendanceSessionModel` lacked real-time status properties and clamped countdown calculation.
  2. The teacher UI card displayed a static `"Active"` chip with no live `MM:SS` ticking countdown.
  3. When time expired, the UI remained in the active state displaying a scannable QR code indefinitely until manual dismissal.
- **Fix Details:**
  1. Added `AttendanceSessionStatus` enum (`scheduled`, `active`, `expired`, `closed`) with `displayName` and `isAcceptingAttendance`.
  2. Added computed properties to `AttendanceSessionModel`:
     - `status`: evaluates `!isActive -> closed`, `DateTime.now().isAfter(endTime) -> expired`, else `active`.
     - `remainingDuration`: clamps non-negative `Duration` (never negative).
     - `remainingSeconds`: `remainingDuration.inSeconds`.
     - `isExpired`: boolean flag.
  3. In `AttendanceSessionNotifier`: added `markExpired()`, `clearSession()`, and `teacherActiveSessionStreamProvider`.
  4. In `TeacherAttendanceTab`:
     - Initialized a 1-second periodic `Timer` tracking the active session.
     - When `remainingSeconds == 0`, auto-invokes `firestoreService.closeSession(session.id)` and `markExpired()`.
     - UI split into two distinct states:
       - **LIVE:** Shows live countdown badge (`MM:SS`), active QR code, check-in stream counter, and export CSV button.
       - **EXPIRED:** Shows amber alert banner (*"Attendance session expired. This attendance session is no longer accepting attendance."*), blurred/watermarked QR code, export CSV button, and `[Dismiss & Create New Session]`.
- **Regression Risk:** Minimal. Backward compatible with all existing sessions.

---

### BUG-02: Student QR Scanner Expiry Detection & Batch Rejection

- **Severity:** High
- **Affected Files:**
  - `lib/features/student/screens/qr_scanner_screen.dart`
  - `lib/data/services/firestore_service.dart`
- **Root Cause:**
  1. When a student scanned an expired QR code, the scanner either hung on `"Processing..."` or threw an ambiguous generic error snackbar.
  2. No dedicated expired overlay or faculty contact path was provided.
  3. Wrong batch error messages were mismatched between Firestore service and the scanner screen.
- **Fix Details:**
  1. Introduced `_isExpiredError` and `_showExpired(String msg)` in `qr_scanner_screen.dart`.
  2. When expired, the camera pauses, and an amber dialog appears:
     - Title: **"QR CODE EXPIRED"**
     - Description: *"This attendance session has ended. Please ask your faculty to generate a new attendance QR code."*
     - Action Buttons: `[Scan New QR]` (resumes camera) and `[Contact Faculty]` (navigates to `/help`).
  3. Aligned wrong batch message: *"This attendance session is not assigned to your batch/section."*.
- **Regression Risk:** None. Improves user feedback and recovery paths.

---

### BUG-03: Mobile Scanner Camera Permission & Torch Stability

- **Severity:** Medium
- **Affected Files:**
  - `lib/features/student/screens/qr_scanner_screen.dart`
- **Root Cause:**
  1. If camera permission was denied, `MobileScanner` threw a black screen with no recovery action.
  2. `_toggleTorch` did not wrap hardware controller calls in try-catch, causing unhandled exceptions on devices lacking a physical flash unit.
- **Fix Details:**
  1. Implemented `errorBuilder` on `MobileScanner` with permission denial detection.
  2. Added direct buttons `[Allow Camera]` (re-requests permission) and `[Open Settings]` (`Geolocator.openAppSettings()`).
  3. Wrapped `_cameraController.toggleTorch()` in try-catch displaying an informative user notice if flash hardware is unsupported.
- **Regression Risk:** None.

---

### BUG-04: Non-Atomic Duplicate Attendance Check in Firestore Transaction

- **Severity:** Critical
- **Affected Files:**
  - `lib/data/services/firestore_service.dart`
- **Root Cause:**
  - In `markAttendanceWithTransaction`, duplicate checking previously used:
    ```dart
    final existingRecords = await _db.collection('attendance_records')
        .where('attendanceSessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: studentUid)
        .limit(1).get();
    ```
    In Cloud Firestore, collection queries inside `runTransaction` are **untracked reads** that do not lock documents or prevent write race conditions!
- **Fix Details:**
  - Leveraged the deterministic composite record ID format `${sessionId}_$studentUid`:
    ```dart
    final recordId = '${sessionId}_$studentUid';
    final existingDoc = await txn.get(_db.collection('attendance_records').doc(recordId));
    if (existingDoc.exists) {
      return const AttendanceResult.failure('Attendance already recorded for this session.');
    }
    ```
  - This executes a transactional document `get()` that is tracked by Firestore's optimistic concurrency control.
- **Regression Risk:** Zero. Idempotent key pattern was already used in `txn.set`.

---

### BUG-05: Cloud Firestore Security Rules Attendance Expiry Enforcement

- **Severity:** High
- **Affected Files:**
  - `firestore.rules`
- **Root Cause:**
  - The security rule for `match /attendance_records/{id}` only checked `request.auth.uid == studentId` and ID formatting, allowing stale or malicious clients to forge check-ins after a session had expired.
- **Fix Details:**
  - Updated rules to enforce session validity server-side:
    ```rules
    match /attendance_records/{id} {
      allow read: if signedIn();
      allow create: if signedIn() && (
        (request.resource.data.studentId == request.auth.uid && 
         id == request.resource.data.attendanceSessionId + '_' + request.auth.uid &&
         exists(/databases/$(database)/documents/sessions/$(request.resource.data.attendanceSessionId)) &&
         get(/databases/$(database)/documents/sessions/$(request.resource.data.attendanceSessionId)).data.isActive == true &&
         request.time <= get(/databases/$(database)/documents/sessions/$(request.resource.data.attendanceSessionId)).data.endTime) ||
        isTeacherOrAdmin()
      );
      allow update, delete: if isTeacherOrAdmin();
    }
    ```
- **Regression Risk:** None. Legitimate check-ins are verified and allowed; late check-ins are rejected at the database layer.

---

### BUG-06: Location Service Error Messaging & Fake GPS Detection

- **Severity:** Medium
- **Affected Files:**
  - `lib/data/services/location_service.dart`
- **Root Cause:**
  - Inconsistent error strings across GPS disabled, permission denied, fake GPS, and distance calculations.
- **Fix Details:**
  - Aligned exact user-facing error strings:
    - GPS Disabled: `"Location services are disabled. Please enable GPS to continue."`
    - Permission Denied: `"Location permission is required for attendance verification."`
    - Mock Location: `"Mock/fake location detected. Please disable mock location and try again."`
    - Radius Check: `"You are approximately ${distance.toStringAsFixed(0)}m away (maximum allowed: ${allowedRadiusMeters.toStringAsFixed(0)}m)."`
- **Regression Risk:** None.

---

### BUG-07: Push Notifications / FCM Permission & Foreground Token Sync

- **Severity:** High
- **Affected Files:**
  - `android/app/src/main/AndroidManifest.xml`
  - `lib/data/services/notification_service.dart`
  - `lib/providers/app_providers.dart`
- **Root Cause:**
  - `POST_NOTIFICATIONS` permission was missing from AndroidManifest.xml (causing notification suppression on Android 13+).
  - FCM device tokens were never synced into the Firestore `users/{uid}` collection.
  - Channel IDs differed between manifest and Dart code.
  - Incoming Firestore notifications in foreground were not bridged to local notifications.
- **Fix Details:**
  - Added `android.permission.POST_NOTIFICATIONS` and default notification channel meta-data to `AndroidManifest.xml`.
  - Harmonized channel ID to `presenza_high_importance_channel`.
  - Added `syncUserToken(String uid)` to store `fcmToken` and `fcmTokenUpdatedAt` in `users/{uid}` with `onTokenRefresh` subscription.
  - Subscribed clients to `all_announcements` and `batch_$batchId` topics.
  - Enhanced `NotificationsNotifier` to deduplicate and bridge incoming notifications into `NotificationService().showInAppNotification()`.
- **Regression Risk:** None. Client-safe; no private keys in client code.

---

### BUG-08: RenderFlex Overflow on Narrow Mobile Viewports (320px–360px)

- **Severity:** Medium
- **Affected Files:**
  - `lib/features/student/tabs/student_home_tab.dart`
- **Root Cause:**
  - On 320px–360px screens, the attendance summary card placed an `AttendanceRing` (110px) and an `Expanded` column containing 4 metrics in a single horizontal `Row`, triggering RenderFlex overflow.
- **Fix Details:**
  - Wrapped card content in a `LayoutBuilder`.
  - When `constraints.maxWidth < 360`, the layout adapts gracefully:
    - `AttendanceRing` shrinks slightly to 96px and centers.
    - Status text and metrics row stack vertically with space-around padding.
  - When `>= 360px`, standard side-by-side row is preserved.
- **Regression Risk:** None.

---

### BUG-09: Dropdown Form Fields Overflow in Admin Circulars Modal

- **Severity:** Low
- **Affected Files:**
  - `lib/features/admin/tabs/admin_circulars_tab.dart`
- **Root Cause:**
  - Two `DropdownButtonFormField` widgets (Category and Priority) sat in an unconstrained `Row`, which clipped text or overflowed on narrow devices.
- **Fix Details:**
  - Wrapped dropdowns in `LayoutBuilder`: if `maxWidth < 360`, fields stack vertically; otherwise they display in a horizontal row.
- **Regression Risk:** None.

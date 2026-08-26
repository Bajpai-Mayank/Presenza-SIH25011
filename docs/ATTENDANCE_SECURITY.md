# Presenza Secure Attendance Architecture

## Overview
Presenza implements a defense-in-depth security model to prevent attendance fraud (proxy attendance). The system leverages native Android/iOS APIs combined with Flutter state management to create a tamper-evident, secure check-in flow.

## 1. Hardware-Level Screen Capture Protection
- **Android `FLAG_SECURE`**: The application requests `WindowManager.LayoutParams.FLAG_SECURE` via a native `MethodChannel` (`SecurityService`). This blocks OS-level screenshots, screen recording, and casting.
- **Android 14+ Callbacks**: We utilize `Activity.ScreenCaptureCallback` to detect if the user attempts to bypass `FLAG_SECURE` via hardware/external means.
- **Flutter Overlay**: When a violation is detected (`compromised` state), a full-screen `SecurityOverlay` blocks interaction, blacking out the screen to prevent QR code leakage.

## 2. Multi-Window & Split-Screen Detection
- **`onMultiWindowModeChanged`**: The native `MainActivity.kt` overrides this method. If a user attempts to open the app in split-screen (often used for cheating while keeping a chat app open), the app detects this.
- **Strict Enforcement**: The `AttendanceSecurityController` listens to these events and immediately locks the UI via the `SecurityOverlay` if multi-window is active.

## 3. Deterministic Idempotency & Firestore Rules
- **Problem**: Previously, attendance records used `uuid.v4()` for the document ID. A user could potentially spam the API and create duplicate check-ins.
- **Solution**: The document ID is now a composite key: `"${sessionId}_${studentUid}"`.
- **Firestore Rule**: 
  ```javascript
  allow create: if signedIn() && (
    (request.resource.data.studentId == request.auth.uid && 
     id == request.resource.data.attendanceSessionId + '_' + request.auth.uid) ||
    isTeacherOrAdmin()
  );
  ```
  This absolutely guarantees that a student can only ever have exactly one record per session, enforced at the database level.

## 4. Short-Lived QR Tokens & Geolocation
- **Expiration**: QR codes are generated with a strict TTL (5-30 minutes). The server rejects check-ins for expired sessions.
- **GPS Verification**: (Optional per session) The app checks the device's latitude/longitude against the classroom's coordinates within a predefined radius (default 100m) before allowing the transaction to proceed.

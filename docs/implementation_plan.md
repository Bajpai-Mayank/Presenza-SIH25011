# Presenza v2 — Performance, Android Build & SIH25011 Enhancement Implementation Plan

**Branch**: `feature/presenza-v2`  
**Problem Statement**: SIH25011 — Smart Curriculum Activity & Attendance App  
**Status**: Ready for Review & Execution  

---

## Executive Summary

This plan outlines the architecture and tasks required to bring **Presenza** to production-grade quality for the SIH25011 problem statement. We are working strictly on the dedicated branch `feature/presenza-v2` without modifying `main`/production directly.

The plan addresses:
1. **Android APK Release Build**: Tooling compatibility upgrades (Gradle wrapper, Android Gradle Plugin, Kotlin DSL) and clean release APK generation.
2. **Startup Lag Elimination & Fast Web Preloader**: Branded dark-mode splash/loader in `web/index.html`, deferred/lazy initialization of expensive services, and elimination of unnecessary re-renders.
3. **Firestore & State Optimizations**: Eliminating excessive collections fetches, scoping streams to active queries, adding robust error/empty/retry states.
4. **Attendance System Upgrades**: Rich teacher session context (Class, Subject, Time, Room, Teacher, Method, Enrolled, Present, Absent, Pending, Rate %) and dynamic "Other / Enter subject manually" support.
5. **Academic Insights & Milestones**: Personal attendance health index, subject-wise strengths vs priority alerts, what-if simulator, and 100% Firestore-backed milestone badges.
6. **Circulars & Activity Hub**: Categorized dual-tier feed distinguishing verified official notices from student-proposed hackathons/workshops with moderation.
7. **Platform Security & Android `FLAG_SECURE`**: Native Kotlin `MethodChannel` preventing screenshot and screen recording abuse on sensitive views, with platform-safe fallbacks.

---

## User Review Required

> [!IMPORTANT]
> **Android Build Tooling**: We are upgrading the Kotlin Gradle plugin version to `2.1.10` / `2.2.20` and Gradle wrapper to `8.9` / `8.11.1` in the Kotlin DSL configuration (`android/settings.gradle.kts` and `android/gradle/wrapper/gradle-wrapper.properties`).
> 
> **Web Screenshot Protection Disclaimer**: Web browsers do not provide hardware-level screenshot prevention APIs equivalent to Android `FLAG_SECURE`. The app implements native Android `FLAG_SECURE` and handles web/desktop environments with safe non-blocking fallbacks.

---

## Proposed Changes by Module

### 1. Android Build Tooling & Release APK
- [android/gradle/wrapper/gradle-wrapper.properties](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/android/gradle/wrapper/gradle-wrapper.properties): Gradle 8.9 / 8.11.1 wrapper verification.
- [android/settings.gradle.kts](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/android/settings.gradle.kts): Configure AGP `8.7.3` / `8.9.0` and Kotlin `2.1.10` / `2.2.20`.
- [android/app/build.gradle.kts](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/android/app/build.gradle.kts): Configure JVM 17 target compatibility.
- **Verification**: Run `flutter build apk --release` and verify `build/app/outputs/flutter-apk/app-release.apk`.

### 2. Startup Performance & Web Fast Loading Screen
- [web/index.html](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/web/index.html): Add styled CSS dark-theme splash screen (`#loading-container`) with Presenza branding and animated pulse spinner so users never see a blank white screen during bundle loading.
- [lib/main.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/main.dart): Ensure Firebase initialization is efficient, with graceful fallback loaders.
- **Verification**: Run `flutter build web --release` and inspect web load sequence.

### 3. Teacher Subject Management & Flexible Session Attendance Dashboard
- [lib/features/teacher/screens/teacher_shell.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/teacher/screens/teacher_shell.dart):
  - Add "+ Enter Subject Manually / Other" option inside the subject selection dropdown and session creator modal.
  - Live session dashboard displaying:
    - Subject Name & Code
    - Class / Batch
    - Date and time
    - Room / Location
    - Teacher name
    - Attendance Method: QR Code / GPS Geofenced / Manual
    - 3-Stat Live Grid: Present Count, Absent Count, Pending Count, Live Attendance %
    - Live verified student attendee roster with timestamps and verification mode badges.

### 4. Student Academic Insights & Milestone Badges
- [lib/features/student/screens/student_shell.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/student/screens/student_shell.dart):
  - Attendance Health index with streak count.
  - Subject performance split: Strong Standing vs Priority Attention (with exact classes needed).
  - Target attendance simulator (1-15 classes simulation).
  - 4 Milestone badges (75% Benchmark, Perfect Record, 3-Day Streak, Zero Absences) tied to live data.

### 5. Circulars & Academic Activity Hub
- [lib/data/models/app_models.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/data/models/app_models.dart): Dual-tier metadata (`isOfficial`, `authorRole`, `eventType`, `location`, `organizer`).
- [lib/features/student/screens/student_shell.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/student/screens/student_shell.dart) & [lib/features/teacher/screens/teacher_shell.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/teacher/screens/teacher_shell.dart):
  - Filter chips (`All`, `Official Notices`, `Events & Hackathons`, `Clubs & Meetups`).
  - Peer activity sharing modal for students and verified announcement creator for faculty.

### 6. Android Platform Screenshot Protection (`FLAG_SECURE`)
- [android/app/src/main/kotlin/com/example/presenza/MainActivity.kt](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/android/app/src/main/kotlin/com/example/presenza/MainActivity.kt): Native Kotlin `MethodChannel` (`com.example.presenza/security`).
- [lib/core/services/security_service.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/core/services/security_service.dart): Safe Dart wrapper with `enableScreenshotProtection()` and `disableScreenshotProtection()`.
- [lib/features/student/screens/qr_scanner_screen.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/student/screens/qr_scanner_screen.dart) & [lib/features/teacher/screens/teacher_shell.dart](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/teacher/screens/teacher_shell.dart): Protect active QR code displays and scanner.

### 7. Cloud Firestore Hardened Security Rules
- [firestore.rules](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/firestore.rules): Role-based access control, restricting attendance creation to faculty and check-ins to authenticated students.

---

## Verification Plan

### Automated Tests
- Run `flutter test` (12 unit and regression tests covering attendance math, models, security services, and session lifecycle).
- Run `dart analyze` to ensure zero compilation warnings or errors.

### Build Verification
- Run `flutter build apk --release` to verify Android release APK generation.
- Run `flutter build web --release` to verify Web production release bundle.

### Manual / Browser Verification
- Test Student flow at `http://127.0.0.1:8080`: Dashboard, Attendance Drilldown Sheet, Activities Hub, Academic Insights.
- Test Teacher flow at `http://127.0.0.1:8080`: Manual Subject Creation, QR Session Generator, Live Attendance Monitor.

# Implementation Plan — Presenza V2 Complete UI & Frontend Redesign

Presenza is an SIH25011 Smart Curriculum Activity & Attendance Management platform. This plan details the transition from the legacy prototype into **Presenza V2**: a modern, mobile-first academic platform featuring an original Navy & Teal design system, full Light/Dark/System theme support, modular architecture, responsive layouts (mobile & tablet/web), and interactive attendance and campus activity experiences.

---

## GPS & Geolocation Verification Architecture

### How GPS Verification Works in Presenza V2:
1. **Conditional Activation**: GPS is only invoked when an attendance session or institution policy requires `locationRequired == true`. On standard sessions or when opening the app, no background location tracking or battery drain occurs.
2. **Permission Workflow**:
   - `LocationService.verifyLocation()` verifies `isLocationServiceEnabled()`.
   - Checks and requests `checkPermission()` / `requestPermission()` (`ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`).
   - If permanently denied, guides the student with a clear action sheet.
3. **High-Accuracy Geodesic Distance**:
   - Uses `Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)))`.
   - Computes distance in meters via the WGS84 ellipsoidal model with `Geolocator.distanceBetween(studentLat, studentLng, sessionCampusLat, sessionCampusLng)`.
   - If `distance <= allowedRadiusMeters` (configured per session/policy, default ~100m), verification succeeds and records coordinates atomically in Firestore.
   - If outside radius, student receives an immediate, human-readable notification: *"You are 240m away from class (maximum allowed: 100m)"*.

---

## Design System & Theme Tokens

- **Academic Navy & Teal Palette**:
  - Primary Navy: `#0F172A`, `#1E293B`, `#1E3A8A`, Indigo `#4F46E5`, `#6366F1`
  - Secondary Teal/Mint: `#0D9488`, `#14B8A6`, `#2DD4BF`
  - Status Indicators: Present `#10B981`, Absent/Error `#EF4444`, Warning `#F59E0B`, Info `#0284C7`
- **Light Theme**: Warm neutral background (`#F8FAFC`), crisp white cards (`#FFFFFF`) with subtle slate borders (`#E2E8F0`), deep navy typography (`#0F172A`).
- **Dark Theme**: Deep navy/slate background (`#0B1120`), slate cards (`#1E293B`) with visible separation (`#334155`), soft accents (`#818CF8`, `#2DD4BF`). Never pure black.
- **Theme Options**: System Default, Light Mode, Dark Mode — persisted locally in `SharedPreferences`.

---

## Proposed Architectural & Visual Directory Layout

```
lib/
├── config/
│   ├── routes.dart                          [Protected role-based routing & clean shell navigation]
│   └── theme/
│       ├── app_colors.dart                  [Academic Navy & Teal Presenza V2 palette for Light & Dark]
│       ├── app_theme.dart                   [Complete M3 typography, card, input, button, nav themes]
│       └── glass_theme.dart                 [Lightweight border & card styling for 60fps performance]
├── core/
│   ├── enums/
│   │   ├── activity_category.dart           [Categories for campus activities & circulars]
│   │   ├── attendance_status.dart           [Present, Absent, Late, Excused]
│   │   ├── enums.dart                       [Circular, Event, Priority, Face enums]
│   │   └── user_role.dart                   [Student, Teacher, Admin]
│   └── services/
│       └── security_service.dart            [FLAG_SECURE screenshot protection]
├── data/
│   ├── models/
│   │   ├── activity_model.dart              [Interactive campus activity post, comments & reactions]
│   │   ├── app_models.dart                  [Circulars, events, notifications, achievements]
│   │   ├── attendance_model.dart            [Math calculators, streak calculations, session metadata]
│   │   ├── auth_state.dart                  [Authentication state holder]
│   │   ├── course_model.dart                [Courses, batches, subjects]
│   │   └── user_model.dart                  [User, student, teacher models with bio/phone/avatar]
│   └── services/
│       ├── auth_service.dart                [Firebase Auth service]
│       ├── firestore_service.dart           [Activity CRUD, reactions, comments, profile updates, manual subjects]
│       └── location_service.dart            [GPS verification & geodesic distance calculation]
├── providers/
│   └── app_providers.dart                   [ThemeModeNotifier (System/Light/Dark), Activity stream providers, profile actions]
├── shared/
│   └── widgets/
│       ├── app_buttons.dart                 [Primary, Secondary, Outlined & Icon buttons with loading state]
│       ├── app_card.dart                    [Sleek, high-performance card with subtle light/dark borders]
│       ├── app_text_field.dart              [Clean form input with icons, visibility toggle, error display]
│       ├── attendance_progress.dart         [Circular & linear attendance visualizers with threshold colors]
│       ├── empty_state.dart                 [Meaningful empty state illustrations with action buttons]
│       ├── error_state.dart                 [User-friendly error message with Retry callback]
│       ├── filter_bottom_sheet.dart         [Filter modal for category, date range, and status]
│       ├── loading_shimmer.dart             [Shimmer skeleton placeholders for cards & lists]
│       ├── responsive_layout.dart           [Mobile bottom navigation + Tablet/Desktop navigation rail]
│       ├── shared_widgets.dart              [Export unified design system components]
│       └── status_badge.dart                [Color-coded badges for status, roles, categories, priorities]
└── features/
    ├── auth/
    │   └── screens/
    │       ├── forgot_password_screen.dart  [Modern email reset card with confirmation]
    │       ├── login_screen.dart            [Presenza V2 branding, clean welcome, 1-click test roles]
    │       ├── no_profile_screen.dart       [Self-healing missing profile resolver]
    │       └── register_screen.dart         [Role-based registration with department/course selector]
    ├── student/
    │   ├── screens/
    │   │   ├── qr_scanner_screen.dart       [Focused camera scanner with instant transaction feedback]
    │   │   └── student_shell.dart           [Responsive shell with notifications & theme switch]
    │   └── tabs/
    │       ├── student_activities_tab.dart  [Interactive campus hub (Official, Student, Saved, Reactions, Comments)]
    │       ├── student_attendance_tab.dart  [Subject attendance breakdown, status filters, miss calculator]
    │       ├── student_home_tab.dart        [Welcome header, attendance summary ring, schedule, quick actions, feed]
    │       ├── student_insights_tab.dart    [Subject distribution, class leaderboard, attendance risk tracker]
    │       └── student_profile_tab.dart     [Student ID card, bio editor, achievements showcase, settings & theme]
    ├── teacher/
    │   ├── screens/
    │   │   └── teacher_shell.dart           [Responsive shell with role navigation]
    │   └── tabs/
    │       ├── teacher_activities_tab.dart  [Create official circulars & moderate pending student posts]
    │       ├── teacher_attendance_tab.dart  [Start session with custom/predefined subject, live QR generator, history]
    │       ├── teacher_dashboard_tab.dart   [Greeting, session metrics, today's schedule, pending approvals]
    │       ├── teacher_profile_tab.dart     [Faculty profile, assigned classes, theme & system settings]
    │       └── teacher_students_tab.dart    [Searchable student directory by course/batch with attendance breakdown]
    └── admin/
        ├── screens/
        │   └── admin_shell.dart             [Responsive admin shell]
        └── tabs/
            ├── admin_attendance_tab.dart    [Institutional attendance analytics & policy editor]
            ├── admin_audit_logs_tab.dart    [Hardware & action security audit log viewer]
            ├── admin_circulars_tab.dart     [Institute broadcast announcements & circular publisher]
            ├── admin_overview_tab.dart      [Real-time institution KPIs, active sessions, quick actions]
            ├── admin_profile_tab.dart       [Admin profile, system diagnostics, theme options, logout]
            └── admin_users_tab.dart         [User directory, role promotion, add/edit faculty and students]
```

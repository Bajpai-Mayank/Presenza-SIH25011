# Presenza — Application Documentation & Technical Guide

Welcome to the **Presenza** technical documentation. This guide details the production architecture, Firebase backend configuration, security model, and deployment workflows.

---

## 1. Project Architecture

The application is engineered using **Clean Architecture** powered by **Riverpod** for reactive state management and **GoRouter** for declarative role-guarded navigation.

```
lib/
├── main.dart                        # Application entrypoint & Firebase initialization
├── app.dart                         # Root MaterialApp widget & theme configuration
├── firebase_options.dart            # FlutterFire auto-generated platform configuration
├── config/
│   ├── routes.dart                  # GoRouter configuration with role-based guards
│   └── theme/
│       ├── app_colors.dart          # Premium monochrome color tokens
│       ├── app_theme.dart           # Light/Dark Material 3 Themes & typography
│       └── glass_theme.dart         # Glassmorphic container parameters (blur, borders)
├── core/
│   └── enums/
│       ├── enums.dart               # Category, priority, method enums
│       ├── user_role.dart           # Role definitions: Student, Teacher, Admin
│       └── attendance_status.dart   # Status definitions: Present, Absent, Late, Excused
├── data/
│   ├── models/                      # Strongly-typed data models (User, Student, Teacher, Attendance)
│   └── services/                    # Production service layer
│       ├── auth_service.dart        # Firebase Auth wrapper (sign in, password reset)
│       ├── firestore_service.dart   # Cloud Firestore CRUD & atomic transactions
│       └── location_service.dart    # GPS geofencing & classroom distance verification
├── providers/
│   └── app_providers.dart           # Riverpod providers & state notifiers
├── shared/
│   └── widgets/
│       └── shared_widgets.dart      # Custom GlassCard, GlassButton, StatCard library
└── features/
    ├── auth/screens/                # Login, Forgot Password, Missing Profile screens
    ├── student/screens/             # Student panel (Home, Attendance, Notices, Scanner, Profile)
    ├── teacher/screens/             # Teacher panel (Dashboard, QR Generator, Directory, Circulars)
    └── admin/screens/               # Admin panel (Analytics, Policies, User Directory, Audit Logs)
```

---

## 2. Authentication & Authorization Flow

Presenza enforces a strict role-based authentication model directly tied to Firebase:

1. **Authentication**: Handled via `FirebaseAuth.instance`.
2. **Profile Resolution**: When auth state changes, `AuthStatusNotifier` queries `/users/{uid}` on Firestore:
   - If the user exists and has a valid role (`student`, `teacher`, `admin`), `AuthState.authenticated(userModel)` is set.
   - If authenticated in Firebase Auth but no Firestore document exists, `AuthState.profileMissing()` redirects to `/no-profile`.
   - If unauthenticated, the user is redirected to `/login`.
3. **Role Guards**: `GoRouter` prevents students from accessing `/teacher` or `/admin` routes, and vice versa.

---

## 3. Real-Time Attendance System

### Teacher QR Code Generation
- The teacher selects an assigned subject, target batch, and duration (in minutes).
- A cryptographically unique `AttendanceSessionModel` is written to `/sessions/{sessionId}` in Firestore.
- The session displays a dynamic QR code containing the session ID.
- Active students checking in are streamed in real time to the teacher's dashboard via `streamAttendanceRecordsForSession`.

### Student Attendance Verification
- The student scans the teacher's QR code using the integrated camera scanner (`mobile_scanner`).
- **Batch Verification**: The app ensures the student belongs to the course and batch assigned to the session.
- **Location Verification**: If `locationRequired` is enabled on the session, `LocationService` checks device GPS coordinates using the Haversine formula to ensure the student is within classroom bounds.
- **Atomic Transactions**: Attendance submission is executed via Firestore `runTransaction` to atomically guarantee:
  1. The session is active and unexpired.
  2. No duplicate attendance records exist for the student in this session.
  3. A new `AttendanceRecordModel` with UUID is committed.

---

## 4. Firestore Security Rules

All database operations are strictly protected by `firestore.rules`:
- **Users**: Users can only read/update their own profile. Only Admins can modify user roles or provision new accounts.
- **Attendance Records**: Students can create attendance records only for their own UID. Only teachers of the session or admins can edit records.
- **Sessions**: Only teachers and admins can create and manage attendance sessions.
- **Audit Logs**: Read and write access is restricted strictly to Admins.

---

## 5. Running the Application

1. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```
2. **Run static analysis**:
   ```bash
   flutter analyze
   ```
3. **Execute unit & widget tests**:
   ```bash
   flutter test
   ```
4. **Run on connected device**:
   ```bash
   flutter run
   ```

---

## 6. Build & CI/CD

### Android APK Build
```bash
flutter build apk --release
```

### Flutter Web Deployment
The repository includes automated build configuration for Vercel/Firebase Hosting via `build.sh`.

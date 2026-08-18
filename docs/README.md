# Smart Circular — Application Documentation & Code Guide

Welcome to the **Smart Circular** documentation guide. This guide explains how the application is structured, how the premium monochrome glassmorphism design system works, and how you can run and extend it without experiencing Firebase issues.

---

## 1. Project Architecture

The application is built using a **Feature-based Clean Architecture** powered by **Riverpod** for reactive state management and **GoRouter** for declarative navigation.

```
lib/
├── main.dart                        # Application entrypoint (Firebase try-caught)
├── app.dart                         # Root MaterialApp widget & theme configuration
├── config/
│   ├── routes.dart                  # GoRouter configuration & role-based redirects
│   └── theme/
│       ├── app_colors.dart          # Premium monochrome color tokens
│       ├── app_theme.dart           # Light/Dark Material 3 Themes & typography
│       └── glass_theme.dart         # Glassmorphic container parameters (blur, borders)
├── core/
│   └── enums/
│       ├── enums.dart               # Category, priority, method enums
│       ├── user_role.dart           # Role definitions: Student, Teacher, Admin
│       └── attendance_status.dart   # Status definitions: Present, Absent, Late
├── data/
│   ├── models/                      # Type-safe data entities
│   └── mock/
│       └── seed_data.dart           # Mock repository with realistic database seed entries
├── providers/
│   └── app_providers.dart           # StateNotifier & Provider definitions
├── shared/
│   └── widgets/
│       └── shared_widgets.dart      # Custom GlassCard, GlassButton, StatCard library
└── features/
    ├── auth/screens/                # Splash & Glassmorphic Login screens
    ├── student/screens/             # Student panel and tabs (Home, Attendance, Notices)
    ├── teacher/screens/             # Teacher controls (QR Code Generator, Student Directory)
    └── admin/screens/               # Admin dashboards (Analytics, Policies, Audit Logs)
```

---

## 2. Temporary Firebase Bypass (Mock / Offline Mode)

To prevent Firebase connection issues from breaking local execution, we have designed the codebase with a fallback system:

1. **Robust Startup**: In [`lib/main.dart`](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/main.dart), the initialization is wrapped in a `try-catch` block:
   ```dart
   try {
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   } catch (e) {
     debugPrint('Firebase initialization failed: $e. Running in mock offline mode.');
   }
   ```
2. **Unified State Providers**: All screen components read state through Riverpod providers in [`lib/providers/app_providers.dart`](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/providers/app_providers.dart) instead of making direct Firestore calls.
3. **Seed Database**: The providers serve highly detailed mock data from [`lib/data/mock/seed_data.dart`](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/data/mock/seed_data.dart).

---

## 3. Key Components Explained

### Glassmorphism System
Our design relies on the `GlassCard` wrapper widget inside [`lib/shared/widgets/shared_widgets.dart`](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/shared/widgets/shared_widgets.dart). It applies a real-time blur and semi-transparent borders:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(radius),
  child: BackdropFilter(
    filter: glass.blurFilter, // Smooth real-time blur
    child: Container(
      decoration: BoxDecoration(
        color: glass.fillColor,
        border: Border.all(color: glass.borderColor),
      ),
      child: child,
    ),
  ),
)
```

### QR Code Generator (Teacher Side)
The QR generator in [`lib/features/teacher/screens/teacher_shell.dart`](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/features/teacher/screens/teacher_shell.dart) generates active QR codes using `qr_flutter`. It tracks time remaining and count of active students:
* Tapping **Generate** instantiates an `AttendanceSessionModel` with a temporary token.
* A timer starts decrementing and counts checking-in students dynamically.

### Navigation Rules
The routing is managed by `GoRouter` inside [`lib/config/routes.dart`](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/config/routes.dart). It enforces:
* **Authentication Guard**: Unauthenticated users are redirected to `/login`.
* **Role Redirection**: Authenticated users are automatically routed to `/student`, `/teacher`, or `/admin` depending on their role profile.

---

## 4. Run & Test the App

1. Ensure packages are installed:
   ```bash
   flutter pub get
   ```
2. Run static analysis:
   ```bash
   flutter analyze
   ```
3. Run on device or simulator:
   ```bash
   flutter run
   ```
4. **Log in instantly** by clicking any of the **Quick Demo Access** chips (Student, Teacher, Admin) on the login screen.

---

## 5. Download & Install Android APK from GitHub

Every time changes are pushed to the `main` branch, a GitHub Actions workflow automatically builds the release APK and updates the repository release.

### How to Install:
1. Go to the **Releases** page of this GitHub repository: `https://github.com/Bajpai-Mayank/Presenza/releases`.
2. Locate the release tagged **`latest`** (titled **Latest Smart Circular Build**).
3. Under **Assets**, click on **`app-release.apk`** to download it to your Android device.
4. Open the downloaded file on your device to install the application. 
   *(Note: You may need to enable "Install from Unknown Sources" in your device settings).*

---

## 6. Deploy & Host on Vercel (Flutter Web)

The application includes a `vercel.json` configuration and a custom `build.sh` script to automate building the Flutter Web build directly inside the Vercel cloud environment.

### Setup Steps:
1. Log in to your **Vercel** dashboard (`https://vercel.com/`).
2. Click **Add New Project** and select this GitHub repository (`Bajpai-Mayank/Presenza`).
3. Under the **Build and Development Settings**:
   * **Build Command**: `bash build.sh`
   * **Output Directory**: `build/web`
4. Click **Deploy**. Vercel will clone the Flutter stable branch, build the web application, and serve it on a secure `vercel.app` URL.

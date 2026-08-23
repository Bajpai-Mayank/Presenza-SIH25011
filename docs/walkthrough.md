# Presenza V2 — Smart Curriculum Activity & Attendance Platform

Presenza V2 transforms the SIH25011 Smart Attendance & Activity platform into a mobile-first, educational experience with Light and Dark Navy/Teal palettes, interactive campus feeds, robust role-based navigation, live QR attendance generation and scanning, GPS classroom bounds verification, and responsive multi-device support.

---

## 🎨 Presenza V2 Design System & Aesthetics

### Color Palette & Elevation

| Element | Light Mode (`#F8FAFC`) | Dark Mode (`#0B1120`) | Semantic Meaning |
| :--- | :--- | :--- | :--- |
| **Primary (Brand)** | `#4F46E5` (Indigo 600) | `#818CF8` (Indigo 400) | University Academic Identity |
| **Secondary (Accent)** | `#0D9488` (Teal 600) | `#2DD4BF` (Teal 400) | Positive Attendance / Fresh |
| **Background** | `#F8FAFC` (Slate 50) | `#0B1120` (Deep Navy Midnight) | Zero Eye Fatigue (Never pure #000) |
| **Card Surface** | `#FFFFFF` (Pure White) | `#1E293B` (Slate 800) | Clean Material 3 Card Elevation |
| **Card Borders** | `#E2E8F0` (Slate 200) | `#334155` (Slate 700) | Subtle Visual Separation |
| **Success** | `#10B981` (Emerald) | `#34D399` (Mint) | Safe Attendance (≥75%), Verified |
| **Warning** | `#F59E0B` (Amber) | `#FBBF24` (Amber Light) | Pending Approvals, Borderline % |
| **Error** | `#EF4444` (Rose 500) | `#F87171` (Rose 400) | Debarment Risk (<75%), Rejection |

### Typography & Structure
- **Typography**: [Inter](https://fonts.google.com/specimen/Inter) paired with clean geometric hierarchy and accessible contrast ratios.
- **Theme Modes**: **System Default**, **Light Mode**, and **Dark Mode** with instant live switching and local preference persistence via `SharedPreferences`.

---

## 📱 Role-Based Modular Architecture

### 1. 🎓 Student Experience (`/student`)
- **`Home Tab`**:
  - Greeting banner with user avatar, name, student ID, and semester.
  - Overall Attendance Gauge (circular ring) with trend indicators (Present, Absent, Late, Total).
  - Attendance Streak counter with fire animation styling (`5 Day Streak`).
  - Today's Class Schedule with live status indicators (Upcoming, Checked In).
  - Quick actions (`Scan QR`, `Subject Attendance`, `Campus Activities`).
  - Upcoming circulars carousel and achievements showcase.
- **`Attendance Tab`**:
  - Filter chips (`All`, `Safe ≥75%`, `At Risk <75%`).
  - Subject cards with credit points, teacher name, attendance percentage, and progress bars.
  - Attendance Math Calculator (`"Can miss 2 more classes"` or `"Need 5 classes to reach 75%"`).
  - Detailed subject session logs modal with timestamp and verification method.
- **`Activities Tab`**:
  - Sub-tabs: `All Feed`, `Official Circulars`, `Student Events`, `Bookmarked`.
  - Category filters (`Academic`, `Workshop`, `Hackathon`, `Cultural`, `Sports`, `Notice`, `Club`).
  - Interactive Reaction Bar: Live **Like**, **Fire**, and **Clap** counters.
  - Real-time **"Interested / Going"** event registration counter.
  - Comments drawer with ability to post and read threaded discussions.
  - **"Post Activity"** submission modal with pending approval state for faculty review.
- **`Insights Tab`**:
  - Academic Health Index & Debarment Risk warning.
  - Attendance Risk Analysis.
  - Batch Attendance Leaderboard showcasing top scholars and streaks.
- **`Profile Tab`**:
  - Student identity card with roll number, department, batch, and editable bio.
  - Achievements and milestones grid.
  - Theme mode selector (System, Light, Dark) and logout confirmation.

---

### 2. 👨‍🏫 Faculty / Teacher Experience (`/teacher`)
- **`Dashboard Tab`**:
  - Faculty ID, department badge, assigned subjects count, and enrolled students count.
  - Active attendance session banner with real-time attendee counter.
  - Pending student activity submissions queue with 1-tap **Approve** / **Reject**.
- **`Attendance Tab`**:
  - Attendance session creator:
    - Pick from assigned subjects OR `+ Other — Enter Subject Manually` (custom subject name & code).
    - Section/Batch selector, Room number, QR expiration time (5, 10, 15, 30 mins).
    - Geolocation GPS Verification toggle with classroom radius constraint (~100m).
  - Live active session view with prominent QR code (`qr_flutter`), session token, live checked-in counter, and end session controls.
  - Session history log.
- **`Activities & Moderation Tab`**:
  - Official Announcement Broadcaster (priority tags, target courses/batches, venue, event date).
  - Moderation queue for student posts.
- **`Students Tab`**:
  - Searchable student directory filterable by section/batch.
  - Student detail bottom sheet with academic enrollment information.
- **`Profile Tab`**:
  - Faculty details, Assigned subject manager with **"Add Subject"** dialog, Theme selector, and Logout.

---

### 3. 🛡️ Campus Administrator Experience (`/admin`)
- **`Overview Tab`**:
  - Global metrics: Total Students, Total Courses, Active Sessions, Total Circulars.
  - Campus attendance overview card.
  - Live classroom monitoring grid.
- **`Attendance Monitor Tab`**:
  - Real-time monitor across all ongoing lecture hall sessions.
  - Enrolled student roster summary.
- **`Circulars Tab`**:
  - Official institution-wide announcement publisher with priority tags.
- **`Users Tab`**:
  - Directory of students and faculty with role filtering and search.
- **`Profile & System Tab`**:
  - Database Seeding & Mock Data Initializer for one-tap demo prep.
  - System diagnostics and Theme settings.

---

## 📍 GPS Geolocation Method Verification

Presenza V2 verifies physical presence through a 4-step security pipeline in [LocationService](file:///c:/Users/Hp/AndroidStudioProjects/Presenza/presenza/lib/data/services/location_service.dart):
1. **Service Enablement Check**: `Geolocator.isLocationServiceEnabled()`.
2. **Permission Check & Request**: Checks `LocationPermission.denied`, requests `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`.
3. **High-Accuracy Geolocation**: `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)`.
4. **Geodesic Distance Calculation**: `Geolocator.distanceBetween(currentLat, currentLng, targetLat, targetLng)`.
5. **Radius Verification**: Matches distance against session `allowedRadiusMeters` (default: 100 meters).

---

## 🧪 Verification & Quality Assurance

- **Unit Tests**: 12 test suites passing with 100% success (`flutter test`).
- **Static Analysis**: `flutter analyze` completed with **0 issues found** (zero errors, zero warnings, zero lints).
- **Security Protections**: Android `FLAG_SECURE` screenshot prevention active on camera, QR generation, and session screens.

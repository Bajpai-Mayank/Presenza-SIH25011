# Presenza — Smart Attendance & Academic Activity Management

Presenza is a production-ready Flutter and Firebase academic application designed for colleges and universities. It features real-time QR attendance verification, geofenced classroom validation, role-based access control (Student, Teacher, Admin), and circular broadcast management with a sleek glassmorphic monochrome design.

---

## Key Features

- **Role-Guarded Portals**: Separate, secure dashboards for Students, Teachers, and System Administrators.
- **Dynamic QR Attendance**: Teachers launch timed attendance sessions generating secure QR codes; students scan with their device camera.
- **Geofenced Verification**: Optional GPS validation ensuring students check in within physical classroom bounds.
- **Atomic Transactions**: Server-grade duplicate prevention and session verification using Cloud Firestore transactions.
- **Academic Analytics**: Subject-wise attendance calculation, streak tracking, and low-attendance alerts (<75%).
- **Digital Circulars**: Filtered notice broadcast with priority tagging (Urgent, Academic, Exam, Event).
- **Glassmorphism UI**: High-fidelity dark/light mode design built on custom blur and border tokens.

---

## Tech Stack

- **Framework**: Flutter 3.x (Dart 3.x)
- **Backend & Auth**: Firebase Auth + Cloud Firestore
- **State Management**: Flutter Riverpod 2.x
- **Navigation**: GoRouter 14.x
- **Scanner & QR**: mobile_scanner + qr_flutter
- **Location**: geolocator

---

## Getting Started

1. Ensure Flutter is installed:
   ```bash
   flutter doctor
   ```
2. Clone the repository and install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code analysis:
   ```bash
   flutter analyze
   ```
4. Run the app:
   ```bash
   flutter run
   ```

For detailed architectural documentation and security rules, see [docs/README.md](docs/README.md).

# Presenza Architecture Document

## Overview
Presenza is a Smart Attendance & Circular Activity Management Application for the Smart India Hackathon (SIH25011). It emphasizes security, geolocation validation, real-time dynamic QR tokenization, and multi-role (Student/Teacher/Admin) architecture.

## 1. State Management
We use **Riverpod** for robust, reactive state management.
- State is decoupled from the UI via Providers (`lib/providers/app_providers.dart`).
- Data streams directly from Firestore to the UI layer.

## 2. Routing
We use **GoRouter** for navigation.
- Role-based redirect logic ensures a Student cannot access Teacher routes, and vice versa.
- The router automatically handles Auth State (login vs main shells).

## 3. Database Layer
**Firestore** is the primary data store, using a NoSQL structure.
- To meet SIH requirements for redundancy, we implemented a `DatabaseRepository` interface.
- `FirestoreService` satisfies this interface.
- A fallback `SupabaseBackupService` skeleton is provided for secondary redundancy.

## 4. Security Protocols
- **FLAG_SECURE**: Enabled via native Android channels (`SecurityService`) to block screen recordings and screenshots.
- **Session Locking**: A `user_sessions` collection tracks login hashes. Logging in on Device B will invalidate the active session on Device A.
- **Dynamic QR**: QR codes embed a time-sensitive, unique `sessionId` rather than static course IDs to prevent spoofing.
- **Geolocation**: Attendance is verified by checking the user's distance to the classroom's coordinates. Mock location apps are actively rejected.

## 5. UI Architecture
- Features are strictly separated into `/features/admin`, `/features/student`, and `/features/teacher`.
- Shared components are housed in `/shared/widgets` (e.g., `AppCard`, `StatCard`, `StatusBadge`).

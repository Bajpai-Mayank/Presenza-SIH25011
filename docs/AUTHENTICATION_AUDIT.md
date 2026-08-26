# Authentication & Registration Audit Report

## 1. Executive Summary
This document summarizes the changes made to stabilize the Presenza authentication and registration pipeline, fix login "stuck" states, secure registration flows, and tighten Firestore rules.

## 2. Issues Identified & Fixed

### 2.1 State Management Duplication (Login Stuck)
- **Issue**: Both `AuthNotifier` and `AuthStatusNotifier` were listening to `FirebaseAuth.instance.authStateChanges()` and making duplicate concurrent calls to fetch the user profile from Firestore, leading to race conditions and "stuck" loading states.
- **Fix**: Merged logic into a single authoritative `authStatusProvider`. `AuthNotifier` now acts as a passive consumer of `authStatusProvider`. The GoRouter redirects now rely exclusively on `authStatusProvider`.

### 2.2 Blocking Session Creation
- **Issue**: During login, the session creation and invalidation processes blocked the UI transition, delaying perceived login speed.
- **Fix**: Wrapped session bookkeeping in an asynchronous background process (`unawaited`), allowing immediate UI transitions upon Firebase Auth success.

### 2.3 Registration Flow Hardcoding & Vulnerabilities
- **Issue**: `RegisterScreen` hardcoded values (`course-btech-cse`, `batch-2024-a`) and permitted public self-registration for `Admin` roles.
- **Fix**: 
  - Integrated dynamic dropdowns fetching courses and batches from Firestore providers.
  - Implemented cascading selections (Course filters Batches) and respected course semester limits.
  - Removed `Admin` option from public registration.
  - Consolidated Firestore writes (User profile, Student/Teacher profile, Notification) into atomic `WriteBatch` operations in `FirestoreService`.

### 2.4 Unsecure Auto-Provisioning
- **Issue**: `NoProfileScreen` automatically provisioned a student profile without validation.
- **Fix**: Removed the auto-provisioning capability. The screen now displays an error advising the user to contact their administrator.

### 2.5 Firebase Initialization Order
- **Issue**: Firebase initialization wasn't the explicit required priority, and Supabase initialization failures could interrupt the startup sequence.
- **Fix**: Adjusted `main.dart` to mandate Firebase initialization first. If it fails, an error app is displayed. Supabase is initialized conditionally and safely degrades if `.env` or variables are missing.

### 2.6 Firestore Security Rules
- **Issue**: The `/students/` collection allowed any authenticated user to read all students.
- **Fix**: Tightened rules so students can only read their own profile, while teachers and admins retain broader access.

## 3. Manual Steps Required
**Important:** The changes to `firestore.rules` were made locally in the repository. You must deploy these rules to your Firebase project. 
To do so, run:
```bash
firebase deploy --only firestore:rules
```
Or copy the contents of `firestore.rules` and paste them directly into the Rules tab of the Firestore section in the Firebase Console.

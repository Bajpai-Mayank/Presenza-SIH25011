# Setup Guide - Presenza V2

## 1. Firebase Setup (Primary Backend)
1. Install the Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize the project: `firebase init`
4. Choose Firestore, Authentication, and Hosting (if using web).
5. Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in their respective `app` directories.
6. Deploy Firestore rules and indexes.

## 2. Supabase Setup (Secondary Backup)
1. Create a Supabase project at [supabase.com](https://supabase.com).
2. Obtain the `URL` and `Anon Key`.
3. Add `supabase_flutter` to `pubspec.yaml` (if not already added).
4. Initialize Supabase in `main.dart` with the URL and Anon Key.
5. Setup equivalent tables for `students`, `attendance_sessions`, and `attendance_records`.
6. Use the `SupabaseBackupService` skeleton to begin syncing data.

## 3. Environment Variables
No `.env` file is used in this repository for security. All API keys for production must be securely injected via CI/CD, or kept out of source control.

## 4. Building the Project
Run `flutter pub get` followed by `flutter build apk --release` for Android.

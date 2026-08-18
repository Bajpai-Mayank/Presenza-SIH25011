# 1. pubspec.yaml — Dependency Changes

## What Changed & Why

We need `firebase_database` to use Firebase Realtime Database.  
We remove `cloud_firestore` because we're using Realtime Database instead.

## Before (Current)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  background: ^1.3.1
  firebase_core: ^4.13.0
  firebase_auth: ^6.5.7
  cloud_firestore: ^6.8.0       # <-- Firestore (we're NOT using this)
  firebase_app_check: ^0.4.6
  provider: ^6.1.5+1
```

## After (Updated)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  background: ^1.3.1
  firebase_core: ^4.13.0
  firebase_auth: ^6.5.7
  firebase_database: ^11.6.0    # <-- NEW: Realtime Database
  firebase_app_check: ^0.4.6
  provider: ^6.1.5+1
```

## Key Concepts

| Package            | Purpose                                      |
|--------------------|----------------------------------------------|
| `firebase_core`    | Initializes Firebase in your Flutter app      |
| `firebase_auth`    | Handles login, signup, logout (Authentication)|
| `firebase_database`| Read/write data to Firebase Realtime Database |
| `provider`         | State management — shares AuthService across the app |

## After Editing, Run:

```bash
flutter pub get
```

This downloads the new package.

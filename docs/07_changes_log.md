# Presenza — Changes Log

All code changes made to connect Firebase and implement the auth flow.

---

## Change 1: Android Gradle — Google Services Plugin

### File: `android/settings.gradle.kts`
**Why:** Without this plugin, `google-services.json` won't be processed and Firebase won't initialize on Android.

```diff
 plugins {
     id("dev.flutter.flutter-plugin-loader") version "1.0.0"
     id("com.android.application") version "9.0.1" apply false
     id("org.jetbrains.kotlin.android") version "2.3.20" apply false
+    id("com.google.gms.google-services") version "4.4.2" apply false
 }
```

### File: `android/app/build.gradle.kts`
**Why:** Apply the plugin at app level + set minSdk to 23 (Firebase Auth minimum).

```diff
 plugins {
     id("com.android.application")
+    id("com.google.gms.google-services")
     id("dev.flutter.flutter-gradle-plugin")
 }

-        minSdk = flutter.minSdkVersion
+        minSdk = 23
```

---

## Change 2: Firebase Initialization

### File: `lib/main.dart`
**Why:** `Firebase.initializeApp()` needs `DefaultFirebaseOptions` to know which Firebase project to connect to.

```diff
 import 'package:firebase_core/firebase_core.dart';
+import 'firebase_options.dart';

-  await Firebase.initializeApp();
+  await Firebase.initializeApp(
+    options: DefaultFirebaseOptions.currentPlatform,
+  );
```

---

## Change 3: Auth Service (Previously Implemented)

### File: `lib/core/auth/authservice.dart`
**What it does:**
- `signInWithEmailAndPassword(email, password)` — logs in via Firebase Auth
- `createUserWithEmailAndPassword(email, password, name, collegeName, studentId)` — creates account + writes user data to Realtime Database at `users/{uid}`
- `signOut()` — signs out
- `getCurrentUser()` — returns current Firebase user
- `getUserData(uid)` — reads user data from Realtime Database

### Database write on signup:
```dart
await _database.ref('users/${userCredential.user!.uid}').set({
  'uid': userCredential.user!.uid,
  'email': email,
  'name': name,
  'collegeName': collegeName,
  'studentId': studentId,
  'createdAt': ServerValue.timestamp,
});
```

---

## Change 4: Login Page (Previously Implemented)

### File: `lib/core/auth/login.dart`
**What it does:**
- Email + Password form with validation
- Calls `AuthService.signInWithEmailAndPassword()` via Provider
- Shows loading spinner during login
- Shows error snackbar on failure
- AuthGate handles redirect to HomePage on success
- "Create Account" navigates to `/signup`

---

## Change 5: Signup Page (Previously Implemented)

### File: `lib/core/auth/signup.dart`
**What it does:**
- 6 fields: Full Name, College Name, Student ID, Email, Password, Confirm Password
- Calls `AuthService.createUserWithEmailAndPassword()` via Provider
- Shows loading spinner during signup
- Shows error snackbar on failure
- Pops back on success — AuthGate redirects to HomePage

---

## Change 6: Auth Gate (Previously Implemented)

### File: `lib/core/auth/auth_gate.dart`
**What it does:**
- StreamBuilder on `FirebaseAuth.instance.authStateChanges()`
- If user is logged in → shows `HomePage`
- If user is logged out → shows `LoginPage`
- Shows loading spinner while checking

---

## Change 7: Home Page (Previously Implemented)

### File: `lib/pages/home_page.dart`
**What it does:**
- Loads user data from Firebase Realtime Database via `AuthService.getUserData()`
- Shows avatar (first letter of name), name, email
- Shows college name and student ID in info cards
- Logout button calls `AuthService.signOut()`
- Matches app gradient theme

---

## Remaining Manual Steps

> **You must do these yourself:**
> 1. Run `flutterfire configure` to generate `firebase_options.dart` and `google-services.json`
> 2. Enable **Email/Password** sign-in in Firebase Console
> 3. Enable **Realtime Database** in Firebase Console (test mode)

# 2. AuthService — The Brain of Authentication

**File:** `lib/core/auth/authservice.dart`

This is the most important file. It talks to Firebase Auth (login/signup/logout)
and Firebase Realtime Database (store/read user data).

---

## Complete Code

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  // ──────────────────────────────────────────────
  // STEP 1: Get references to Firebase services
  // ──────────────────────────────────────────────
  //
  // FirebaseAuth   → handles login, signup, logout
  // FirebaseDatabase → handles reading/writing user data
  //
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ──────────────────────────────────────────────
  // STEP 2: Sign In (Login)
  // ──────────────────────────────────────────────
  //
  // Takes email + password from the login form.
  // Calls Firebase Auth to verify credentials.
  // Returns a UserCredential on success.
  // Throws an Exception on failure (wrong password, user not found, etc.)
  //
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ──────────────────────────────────────────────
  // STEP 3: Sign Up (Create Account)
  // ──────────────────────────────────────────────
  //
  // 1. Creates a new user in Firebase Authentication
  // 2. After success, saves user profile data to Realtime Database
  //
  // Database path: "users/{uid}"
  //
  // Example of what gets saved in the database:
  //
  //   users/
  //     abc123def/           ← the user's unique ID
  //       uid: "abc123def"
  //       email: "john@example.com"
  //       name: "John Doe"
  //       collegeName: "MIT"
  //       studentId: "STU001"
  //       createdAt: 1692345678000  (timestamp)
  //
  Future<UserCredential> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      String collegeName,
      String studentId) async {
    try {
      // Part A: Create the authentication account
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Part B: Save user profile data to Realtime Database
      //
      // _database.ref('users/${uid}') creates a reference to:
      //   Realtime Database → users → {uid}
      //
      // .set({...}) writes the data at that location
      //
      await _database
          .ref('users/${userCredential.user!.uid}')
          .set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'collegeName': collegeName,
        'studentId': studentId,
        'createdAt': ServerValue.timestamp,
        // ServerValue.timestamp = Firebase server's current time
        // This ensures consistent timestamps regardless of device clock
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ──────────────────────────────────────────────
  // STEP 4: Sign Out (Logout)
  // ──────────────────────────────────────────────
  //
  // Signs out the current user.
  // After this, FirebaseAuth.instance.authStateChanges() will emit null,
  // which triggers AuthGate to show the LoginPage.
  //
  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  // ──────────────────────────────────────────────
  // STEP 5: Get Current User
  // ──────────────────────────────────────────────
  //
  // Returns the currently logged-in user, or null if not logged in.
  // Useful for checking auth state anywhere in the app.
  //
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // ──────────────────────────────────────────────
  // STEP 6: Get User Data from Realtime Database
  // ──────────────────────────────────────────────
  //
  // Reads the user's profile data from the database.
  //
  // .ref('users/$uid') → points to the user's data
  // .get()             → fetches it once (not a live stream)
  // .value             → the actual data (a Map)
  //
  // Returns a Map like:
  //   {
  //     'uid': 'abc123',
  //     'email': 'john@example.com',
  //     'name': 'John Doe',
  //     ...
  //   }
  //
  // Returns null if the user doesn't exist in the database.
  //
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snapshot = await _database.ref('users/$uid').get();

    if (snapshot.exists) {
      // snapshot.value is dynamic, we cast it to Map
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }
}
```

---

## How Data Flows

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────────────┐
│  Login Form  │──────▶│   AuthService    │──────▶│   Firebase Auth     │
│  (email/pw)  │       │  signIn(...)     │       │   (verifies user)   │
└─────────────┘       └──────────────────┘       └─────────────────────┘

┌─────────────┐       ┌──────────────────┐       ┌─────────────────────┐
│  Signup Form │──────▶│   AuthService    │──────▶│   Firebase Auth     │
│  (all fields)│       │  createUser(...) │       │   (creates account) │
└─────────────┘       └──────┬───────────┘       └─────────────────────┘
                             │
                             │ then saves profile
                             ▼
                      ┌──────────────────┐
                      │ Realtime Database │
                      │  users/{uid}/... │
                      └──────────────────┘
```

---

## Key Concepts Explained

### `ChangeNotifier`
AuthService extends `ChangeNotifier` — this is a Provider pattern.
It lets widgets listen for changes. When you call `notifyListeners()`,
all widgets using `Provider.of<AuthService>(context)` will rebuild.

### `FirebaseDatabase.instance.ref('path')`
This creates a "reference" to a specific location in the database.
Think of it like a file path:
- `ref('users')` → the "users" folder
- `ref('users/abc123')` → a specific user inside "users"

### `ServerValue.timestamp`
Instead of using `DateTime.now()` (which uses the phone's clock),
`ServerValue.timestamp` uses Firebase's server clock.
This is more reliable because phone clocks can be wrong.

### `snapshot.exists` and `snapshot.value`
When you `.get()` data from the database:
- `snapshot.exists` → true if data is there, false if not
- `snapshot.value` → the actual data (Map, String, int, etc.)

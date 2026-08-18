# 4. AuthGate — The Auto-Redirect System

**File:** `lib/core/auth/auth_gate.dart`

AuthGate is the "traffic controller" of your app.
It listens to Firebase Auth state and decides which page to show.

---

## Complete Code

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:presenza/core/auth/login.dart';
import 'package:presenza/pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ──────────────────────────────────────────────
      // StreamBuilder listens to auth state changes
      // ──────────────────────────────────────────────
      //
      // FirebaseAuth.instance.authStateChanges() is a STREAM.
      //
      // A Stream is like a pipe that continuously sends data:
      //   - When user logs in  → sends User object
      //   - When user logs out → sends null
      //
      // StreamBuilder rebuilds the UI every time new data arrives.
      //
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // ── CONNECTION STATE: Still loading ──
          // While Firebase is checking if user is logged in,
          // show a loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          // ── HAS DATA: User is logged in ──
          // snapshot.hasData means there IS a User object
          // → Show the HomePage
          if (snapshot.hasData) {
            return const HomePage();
          }

          // ── NO DATA: User is NOT logged in ──
          // snapshot has no data means no User
          // → Show the LoginPage
          else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
```

---

## How AuthGate Works (Visual Flow)

```
App starts
    │
    ▼
AuthGate (StreamBuilder listens to authStateChanges)
    │
    ├── Firebase checking... → ⏳ Loading spinner
    │
    ├── User IS logged in   → 🏠 HomePage
    │     (snapshot.hasData == true)
    │
    └── User NOT logged in  → 🔐 LoginPage
          (snapshot.hasData == false)
```

### What triggers state changes?

```
User signs up successfully
  → authStateChanges() emits User
  → StreamBuilder rebuilds
  → snapshot.hasData == true
  → Shows HomePage ✅

User taps Logout
  → authService.signOut()
  → authStateChanges() emits null
  → StreamBuilder rebuilds
  → snapshot.hasData == false
  → Shows LoginPage 🔐

App reopens (user was previously logged in)
  → Firebase remembers the session
  → authStateChanges() emits User
  → Shows HomePage directly ✅ (no need to login again!)
```

---

## Key Concepts Explained

### `StreamBuilder` vs `FutureBuilder`

| Feature        | FutureBuilder           | StreamBuilder                |
|----------------|------------------------|------------------------------|
| Data source    | One-time async call     | Continuous stream of data    |
| Rebuilds       | Once (when future completes) | Every time stream emits |
| Use case       | Fetch data once         | Listen for real-time changes |

Auth state can change at any time (login, logout, token expiry),
so we use `StreamBuilder` — not `FutureBuilder`.

### `snapshot.connectionState`

| State                          | Meaning                          |
|-------------------------------|----------------------------------|
| `ConnectionState.none`        | Not connected to stream          |
| `ConnectionState.waiting`     | Connected, waiting for first data|
| `ConnectionState.active`      | Stream is active, data received  |
| `ConnectionState.done`        | Stream is closed                 |

### Why no `Navigator.push` here?

AuthGate doesn't use `Navigator.push(HomePage)` or `Navigator.push(LoginPage)`.
Instead, it **returns** the widget directly inside `StreamBuilder`.

This is cleaner because:
- No manual navigation logic needed
- Firebase Auth state automatically controls which page shows
- Works even when app is reopened (Firebase remembers the session)

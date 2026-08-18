# 3. main.dart — App Entry Point, Provider & Routes

**File:** `lib/main.dart`

This file sets up three things:
1. Firebase initialization
2. Provider (so AuthService is available everywhere)
3. Named routes (so you can navigate between pages easily)

---

## Complete Code

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:presenza/core/auth/auth_gate.dart';
import 'package:presenza/core/auth/authservice.dart';
import 'package:presenza/core/auth/login.dart';
import 'package:presenza/core/auth/signup.dart';
import 'package:presenza/pages/home_page.dart';
import 'package:presenza/firebase_options.dart';

void main() async {
  // ──────────────────────────────────────────────
  // STEP 1: Initialize Flutter engine
  // ──────────────────────────────────────────────
  // Required before calling any async code in main()
  WidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────
  // STEP 2: Initialize Firebase
  // ──────────────────────────────────────────────
  // Connects your app to your Firebase project
  // using the config from firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ──────────────────────────────────────────────
  // STEP 3: Run the app
  // ──────────────────────────────────────────────
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ──────────────────────────────────────────────
    // STEP 4: Wrap with ChangeNotifierProvider
    // ──────────────────────────────────────────────
    //
    // This makes AuthService available to EVERY widget
    // in the app via:
    //   Provider.of<AuthService>(context)
    //
    // Without this, each page would need to create its
    // own AuthService instance — bad practice!
    //
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        // ──────────────────────────────────────────────
        // STEP 5: Set initial page
        // ──────────────────────────────────────────────
        // AuthGate decides: logged in → HomePage, not logged in → LoginPage
        home: const AuthGate(),

        // ──────────────────────────────────────────────
        // STEP 6: Define named routes
        // ──────────────────────────────────────────────
        //
        // Named routes let you navigate like this:
        //   Navigator.pushNamed(context, '/signup');
        //
        // Instead of the verbose:
        //   Navigator.push(context, MaterialPageRoute(builder: ...));
        //
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUp(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
```

---

## How It All Connects

```
main()
  │
  ├── Firebase.initializeApp()     ← connects to Firebase
  │
  └── MyApp
        │
        ├── ChangeNotifierProvider  ← makes AuthService global
        │     └── AuthService()
        │
        └── MaterialApp
              │
              ├── home: AuthGate    ← decides which page to show
              │
              └── routes:           ← navigation map
                    '/login'  → LoginPage
                    '/signup' → SignUp
                    '/home'   → HomePage
```

---

## Key Concepts Explained

### `ChangeNotifierProvider`

Think of it as a "service container" that sits at the top of the widget tree.

```
ChangeNotifierProvider<AuthService>    ← holds the service
  └── MaterialApp
        └── AuthGate
              ├── LoginPage          ← can access AuthService
              └── HomePage           ← can access AuthService
```

Any child widget can grab the service:
```dart
// Way 1: Full syntax
final authService = Provider.of<AuthService>(context, listen: false);

// Way 2: Shorthand (same thing)
final authService = context.read<AuthService>();
```

### Named Routes

Without named routes:
```dart
// Verbose — you have to import the page and create MaterialPageRoute
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SignUp()),
);
```

With named routes:
```dart
// Clean — just use the route name string
Navigator.pushNamed(context, '/signup');
```

### Why `home:` and `routes:` together?

- `home: AuthGate()` → the FIRST page shown when the app starts
- `routes: {...}` → a MAP of all pages the app can navigate to

The `home` page does NOT need to be in the `routes` map.
But login, signup, home ARE in the routes map so other pages can navigate to them.

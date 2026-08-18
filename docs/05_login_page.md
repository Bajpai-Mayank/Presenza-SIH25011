# 5. Login Page — Connected to Firebase Auth

**File:** `lib/core/auth/login.dart`

The login page now actually calls Firebase Auth when the user taps "Login".
Previously, it only showed a snackbar saying "Login action triggered" — now it works for real.

---

## What Changed (Summary)

| Before (Old)                          | After (New)                               |
|---------------------------------------|-------------------------------------------|
| Button shows snackbar "Login action"  | Button calls `authService.signIn()`       |
| No loading state                      | Shows loading spinner while signing in    |
| No error handling                     | Shows error message on failure            |
| `Navigator.push` to signup            | `Navigator.pushNamed(context, '/signup')` |

---

## Complete Code

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:presenza/core/auth/authservice.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── NEW: Loading state ──
  // Tracks whether a login request is in progress.
  // When true, the button shows a spinner instead of "Login" text.
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // NEW: The actual login method
  // ──────────────────────────────────────────────
  //
  // This is called when the user taps the Login button.
  //
  // Flow:
  //   1. Validate form fields
  //   2. Show loading spinner
  //   3. Call AuthService.signInWithEmailAndPassword()
  //   4. On success → AuthGate automatically redirects to HomePage
  //   5. On failure → Show error snackbar
  //
  Future<void> _login() async {
    // Step 1: Validate
    if (!_formKey.currentState!.validate()) return;

    // Step 2: Show loading
    setState(() => _isLoading = true);

    try {
      // Step 3: Get AuthService from Provider (listen: false because
      // we're calling this from a method, not from build())
      final authService = Provider.of<AuthService>(context, listen: false);

      // Step 4: Call Firebase Auth
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Step 5: SUCCESS!
      // We don't need to navigate manually.
      // AuthGate's StreamBuilder detects the auth state change
      // and automatically shows HomePage.

    } catch (e) {
      // Step 6: FAILURE — show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      // Step 7: Hide loading (only if widget is still mounted)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF051937),
              Color(0xFF00446b),
              Color(0xFF00759d),
              Color(0xFF00abc9),
              Color(0xFF12e2eb),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/icon.png',
                                width: 72,
                                height: 72,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Login to your account to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 214, 235, 255),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Email Field (unchanged) ──
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.08),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Password Field (unchanged) ──
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.08),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ─── CHANGED: Login Button ───
                              // Now calls _login() instead of showing a snackbar
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  // When loading, disable the button (null = disabled)
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.18),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  // Show spinner while loading, text otherwise
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Forgot password?',
                                      style:
                                          TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  // ─── CHANGED: Use named route ───
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/signup');
                                    },
                                    child: const Text(
                                      'Create Account',
                                      style:
                                          TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Key Concepts Explained

### `Provider.of<AuthService>(context, listen: false)`

```dart
final authService = Provider.of<AuthService>(context, listen: false);
```

- Gets the `AuthService` instance that was created in `main.dart`
- `listen: false` → We don't want the widget to rebuild when AuthService changes
  (we're calling this from a method, not inside `build()`)
- If you used `listen: true` inside a method, you'd get an error

### `mounted` check

```dart
if (mounted) {
  setState(() => _isLoading = false);
}
```

- After an async call (`await`), the widget might have been removed from the tree
  (e.g., user navigated away)
- Calling `setState` on an unmounted widget causes a crash
- `mounted` is `true` if the widget is still in the widget tree

### Why no manual navigation after login?

You might expect:
```dart
// DON'T DO THIS — it's not needed
await authService.signIn(email, password);
Navigator.pushNamed(context, '/home');  // ❌ Not needed!
```

Because `AuthGate` is always listening to `authStateChanges()`.
When login succeeds, Firebase Auth emits a new User → AuthGate rebuilds → shows HomePage.
It's automatic!

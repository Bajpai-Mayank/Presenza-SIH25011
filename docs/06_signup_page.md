# 6. Signup Page — Creates User + Saves Data to Realtime Database

**File:** `lib/core/auth/signup.dart`

The signup page now:
1. Creates a Firebase Auth account
2. Saves user profile data (name, college, ID) to Realtime Database
3. Shows loading state and error handling
4. Fixed bugs: wrong label text, wrong button text

---

## What Changed (Summary)

| Before (Old)                              | After (New)                                   |
|-------------------------------------------|-----------------------------------------------|
| Button shows snackbar "Login action"      | Button calls `authService.createUser()`       |
| College field labeled "Full Name" (bug)   | Correctly labeled "College Name"              |
| Button says "Login" (bug)                 | Correctly says "Sign Up"                      |
| No loading / error states                 | Loading spinner + error snackbar              |
| No back navigation                        | Back arrow to return to login                 |

---

## Complete Code

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:presenza/core/auth/authservice.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUp> {
  final TextEditingController _regemailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _collegeNameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final _signUpKey = GlobalKey<FormState>();

  // ── NEW: Loading state ──
  bool _isLoading = false;

  @override
  void dispose() {
    _regemailController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _collegeNameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // NEW: The actual signup method
  // ──────────────────────────────────────────────
  //
  // Flow:
  //   1. Validate all form fields
  //   2. Show loading spinner
  //   3. Call AuthService.createUserWithEmailAndPassword()
  //      → This creates the auth account AND saves data to Realtime DB
  //   4. On success → Pop back, AuthGate auto-redirects to HomePage
  //   5. On failure → Show error snackbar
  //
  Future<void> _signUp() async {
    if (!_signUpKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.createUserWithEmailAndPassword(
        _regemailController.text.trim(),
        _regPasswordController.text.trim(),
        _nameController.text.trim(),
        _collegeNameController.text.trim(),
        _idController.text.trim(),
      );

      // SUCCESS!
      // After signup, Firebase Auth automatically logs the user in.
      // AuthGate detects this and shows HomePage.
      // We just need to pop the signup page off the navigation stack.
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ─── NEW: Back button in AppBar ───
      // Transparent app bar with a back arrow
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                      padding: const EdgeInsets.all(24),
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
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _signUpKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Full Name ──
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Full Name",
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person_outline,
                                      color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.35),
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
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── College Name (BUG FIX: was "Full Name") ──
                              TextFormField(
                                controller: _collegeNameController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "College Name",  // ← FIXED
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.school_outlined,
                                      color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.35),
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
                                    return 'Please enter your college name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── Student ID ──
                              TextFormField(
                                controller: _idController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Student ID",
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.badge_outlined,
                                      color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.35),
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
                                    return 'Please enter your student ID';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── Email ──
                              TextFormField(
                                controller: _regemailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.35),
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
                              const SizedBox(height: 24),

                              // ── Password ──
                              TextFormField(
                                controller: _regPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.35),
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
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── Confirm Password ──
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.35),
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
                                    return 'Please confirm your password';
                                  }
                                  if (value != _regPasswordController.text) {
                                    return "Passwords don't match";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ─── CHANGED: Sign Up Button ───
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.18),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
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
                                          'Sign Up',  // ← FIXED: was "Login"
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
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

## What Happens When User Signs Up

```
User fills form → taps "Sign Up"
    │
    ▼
_signUp() called
    │
    ├── Form validates? ────── No → Show validation errors
    │                                (stop here)
    │
    ├── Yes ▼
    │   Show loading spinner
    │
    ├── authService.createUserWithEmailAndPassword()
    │     │
    │     ├── Firebase Auth creates account
    │     │
    │     └── Realtime Database saves:
    │           users/
    │             {uid}/
    │               uid: "abc123"
    │               email: "john@example.com"
    │               name: "John Doe"
    │               collegeName: "MIT"
    │               studentId: "STU001"
    │               createdAt: 1692345678000
    │
    ├── Success?
    │     │
    │     ├── Yes → Navigator.pop() (go back)
    │     │          AuthGate detects login → shows HomePage
    │     │
    │     └── No  → Show error snackbar
    │               (e.g., "email-already-in-use")
    │
    └── Hide loading spinner
```

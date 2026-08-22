import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result of an authentication operation.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.ok(User user) => AuthResult(success: true, user: user);
  factory AuthResult.error(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Dedicated Firebase Authentication service.
///
/// Wraps all Firebase Auth operations with robust error handling
/// and user-friendly error messages designed for production Firebase deployment.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Current Firebase Auth user (nullable).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthResult.ok(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService.signIn unexpected error: $e');
      return AuthResult.error(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send a password reset email.
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService.sendPasswordResetEmail unexpected error: $e');
      return AuthResult.error(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Create a new user account (for admin provisioning).
  ///
  /// Note: This signs in as the new user. For production admin provisioning,
  /// consider using Firebase Admin SDK via Cloud Functions instead.
  Future<AuthResult> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthResult.ok(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService.createUser unexpected error: $e');
      return AuthResult.error(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact your administrator.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        debugPrint('Unmapped Firebase Auth error code: $code');
        return 'Authentication failed. Please try again.';
    }
  }
}

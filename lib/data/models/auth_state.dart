import 'package:presenza/data/models/user_model.dart';

/// Represents the current authentication status of the application.
enum AuthStatus {
  /// Firebase Auth state has not yet been resolved.
  initializing,

  /// No user is signed in.
  unauthenticated,

  /// User is currently signing in or registering.
  authenticating,

  /// User is signed in via Firebase, currently fetching Firestore profile.
  fetchingProfile,

  /// User is signed in and their Firestore profile has been loaded.
  authenticated,

  /// User is signed in via Firebase Auth, but their Firestore profile
  /// does not exist. They need to contact their administrator.
  profileMissing,

  /// An error occurred during authentication or profile loading.
  error,
}

/// Immutable authentication state model.
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// Initial state before Firebase Auth resolves.
  const AuthState.initializing()
      : status = AuthStatus.initializing,
        user = null,
        errorMessage = null;

  /// No user signed in.
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  /// User is authenticating.
  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        user = null,
        errorMessage = null;

  /// Fetching user profile.
  const AuthState.fetchingProfile()
      : status = AuthStatus.fetchingProfile,
        user = null,
        errorMessage = null;

  /// User signed in with a valid Firestore profile.
  AuthState.authenticated(UserModel this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  /// User signed in but Firestore profile is missing.
  const AuthState.profileMissing()
      : status = AuthStatus.profileMissing,
        user = null,
        errorMessage = null;

  /// Error state.
  AuthState.error(String this.errorMessage)
      : status = AuthStatus.error,
        user = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isInitializing => status == AuthStatus.initializing;
}

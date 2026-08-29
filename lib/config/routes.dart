import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/data/models/auth_state.dart';
import 'package:presenza/features/auth/screens/login_screen.dart';
import 'package:presenza/features/auth/screens/register_screen.dart';
import 'package:presenza/features/auth/screens/forgot_password_screen.dart';
import 'package:presenza/features/auth/screens/no_profile_screen.dart';
import 'package:presenza/features/splash/screens/splash_screen.dart';
import 'package:presenza/shared/screens/help_support_screen.dart';

// Shell & Feature imports
import 'package:presenza/features/student/screens/student_shell.dart';
import 'package:presenza/features/student/screens/qr_scanner_screen.dart';
import 'package:presenza/features/teacher/screens/teacher_shell.dart';
import 'package:presenza/features/admin/screens/admin_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authStatus = ref.read(authStatusProvider);
      final currentLoc = state.matchedLocation;
      final isSplashRoute = currentLoc == '/splash';
      final isAuthRoute = currentLoc == '/login' ||
          currentLoc == '/forgot-password' ||
          currentLoc == '/register';
      final isNoProfileRoute = currentLoc == '/no-profile';

      // While on splash screen, let the branded animation play without redirect interference
      if (isSplashRoute) {
        return null;
      }

      // While auth is in progress (initializing, authenticating, fetchingProfile), stay on current route
      if (authStatus.status == AuthStatus.initializing || 
          authStatus.status == AuthStatus.authenticating || 
          authStatus.status == AuthStatus.fetchingProfile) {
        return null;
      }

      // If Firebase Auth currentUser is present, stay on current route while profile is finishing
      if (FirebaseAuth.instance.currentUser != null && authStatus.user == null) {
        return null;
      }

      // Error state: go back to login unless already on auth routes
      if (authStatus.status == AuthStatus.error) {
        return isAuthRoute ? null : '/login';
      }

      // Profile missing
      if (authStatus.status == AuthStatus.profileMissing) {
        return isNoProfileRoute ? null : '/no-profile';
      }

      // Not authenticated
      if (authStatus.status == AuthStatus.unauthenticated || authStatus.user == null) {
        return isAuthRoute ? null : '/login';
      }

      // Authenticated — redirect away from auth routes
      final user = authStatus.user!;
      if (isAuthRoute || isNoProfileRoute) {
        switch (user.role) {
          case UserRole.student:
            return '/student';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.admin:
            return '/admin';
        }
      }

      // Role-based route protection
      if (currentLoc.startsWith('/admin') && user.role != UserRole.admin) {
        return user.role == UserRole.teacher ? '/teacher' : '/student';
      }
      if (currentLoc.startsWith('/teacher') && user.role == UserRole.student) {
        return '/student';
      }
      if (currentLoc.startsWith('/student') && user.role != UserRole.student) {
        return user.role == UserRole.teacher ? '/teacher' : '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/no-profile',
        builder: (context, state) => const NoProfileScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentShell(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
    ],
  );
});

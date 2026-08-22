import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/data/models/auth_state.dart';
import 'package:presenza/features/auth/screens/login_screen.dart';
import 'package:presenza/features/auth/screens/forgot_password_screen.dart';
import 'package:presenza/features/auth/screens/no_profile_screen.dart';

// Shell & Dashboard imports
import 'package:presenza/features/student/screens/student_shell.dart';
import 'package:presenza/features/teacher/screens/teacher_shell.dart';
import 'package:presenza/features/admin/screens/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final currentLoc = state.matchedLocation;
      final isAuthRoute = currentLoc == '/login' ||
          currentLoc == '/forgot-password';
      final isNoProfileRoute = currentLoc == '/no-profile';

      // While auth is initializing, stay on login (the UI shows loading)
      if (authStatus.isInitializing) {
        return isAuthRoute ? null : '/login';
      }

      // Profile missing — user authenticated but no Firestore profile
      if (authStatus.status == AuthStatus.profileMissing) {
        return isNoProfileRoute ? null : '/no-profile';
      }

      // Not authenticated — redirect to login
      final loggedIn = authState != null;
      if (!loggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Authenticated — redirect away from auth routes
      if (isAuthRoute || isNoProfileRoute) {
        switch (authState.role) {
          case UserRole.student:
            return '/student';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.admin:
            return '/admin';
        }
      }

      // Role-based route protection:
      // Prevent students from accessing teacher/admin routes
      // Prevent teachers from accessing admin routes
      // Prevent unauthorized access across roles
      if (currentLoc.startsWith('/admin') &&
          authState.role != UserRole.admin) {
        switch (authState.role) {
          case UserRole.student:
            return '/student';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.admin:
            return null; // Already admin
        }
      }

      if (currentLoc.startsWith('/teacher') &&
          authState.role == UserRole.student) {
        return '/student';
      }

      if (currentLoc.startsWith('/student') &&
          authState.role != UserRole.student) {
        switch (authState.role) {
          case UserRole.teacher:
            return '/teacher';
          case UserRole.admin:
            return '/admin';
          case UserRole.student:
            return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
        path: '/teacher',
        builder: (context, state) => const TeacherShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
    ],
  );
});

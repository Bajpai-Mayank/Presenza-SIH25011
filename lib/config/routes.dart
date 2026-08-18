import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/features/auth/screens/login_screen.dart';

// Shell & Dashboard imports (mock skeletons that we will create)
import 'package:presenza/features/student/screens/student_shell.dart';
import 'package:presenza/features/teacher/screens/teacher_shell.dart';
import 'package:presenza/features/admin/screens/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!loggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // If logged in and trying to go to login, redirect to appropriate role dashboard
      if (isLoggingIn) {
        switch (authState.role) {
          case UserRole.student:
            return '/student';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.admin:
            return '/admin';
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

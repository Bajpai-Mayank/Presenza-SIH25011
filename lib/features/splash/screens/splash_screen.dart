import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/auth_state.dart';
import 'package:presenza/providers/app_providers.dart';

/// Professional branded startup splash screen for Presenza.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  bool _minDurationElapsed = false;
  bool _hasNavigated = false;
  Timer? _timer;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();

    // 1. Min branded duration (~1.0s)
    _timer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _minDurationElapsed = true);
        _checkAndNavigate();
      }
    });

    // 2. Safety fallback timeout (~2.2s) - guarantees app never hangs on splash
    _fallbackTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && !_hasNavigated) {
        _forceNavigation();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _forceNavigation() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final authStatus = ref.read(authStatusProvider);
    if (authStatus.status == AuthStatus.authenticated && authStatus.user != null) {
      _routeForRole(authStatus.user!.role);
    } else if (authStatus.status == AuthStatus.profileMissing) {
      context.go('/no-profile');
    } else {
      context.go('/login');
    }
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !_minDurationElapsed || !mounted) return;

    final authStatus = ref.read(authStatusProvider);

    if (authStatus.status == AuthStatus.initializing ||
        authStatus.status == AuthStatus.authenticating ||
        authStatus.status == AuthStatus.fetchingProfile) {
      return;
    }

    _hasNavigated = true;

    if (authStatus.status == AuthStatus.profileMissing) {
      context.go('/no-profile');
      return;
    }

    if (authStatus.status == AuthStatus.authenticated && authStatus.user != null) {
      _routeForRole(authStatus.user!.role);
      return;
    }

    context.go('/login');
  }

  void _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        context.go('/student');
        break;
      case UserRole.teacher:
        context.go('/teacher');
        break;
      case UserRole.admin:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to authStatus changes after the timer has elapsed
    ref.listen<AuthState>(authStatusProvider, (previous, next) {
      _checkAndNavigate();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Branded Logo ──────────────────────────────────────────
                  Transform.scale(
                    scale: _logoScaleAnim.value,
                    child: Opacity(
                      opacity: _fadeAnim.value,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4A72FF).withValues(alpha: isDark ? 0.35 : 0.2),
                              blurRadius: 32,
                              spreadRadius: 6,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Branded Title & Subtitle ──────────────────────────────
                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(
                      opacity: _fadeAnim.value,
                      child: Column(
                        children: [
                          Text(
                            'PRESENZA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A72FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Attendance & Academic Management',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Color(0xFF4A72FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Subtle Progress Indicator ────────────────────────────
                  Opacity(
                    opacity: _fadeAnim.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A72FF)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

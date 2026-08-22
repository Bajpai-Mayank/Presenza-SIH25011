import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final errorMessage = await ref
        .read(authStateProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      // On success, the auth state listener triggers navigation automatically.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    const Color(0xFF0F0F0F),
                    const Color(0xFF111111),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFEAEAEC),
                    AppColors.backgroundLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.white.withAlpha(13)
                                  : AppColors.black.withAlpha(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.white.withAlpha(25)
                                    : AppColors.black.withAlpha(15),
                              ),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              size: 40,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Smart Circular',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your account',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.gray400
                                      : AppColors.gray600,
                                ),
                          ),
                          const SizedBox(height: 40),

                          // Login Card
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                GlassTextField(
                                  controller: _emailController,
                                  labelText: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                GlassTextField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.push('/forgot-password'),
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassButton(
                                  label: 'Sign In',
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                              ],
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
    );
  }
}

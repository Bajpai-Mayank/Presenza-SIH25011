import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:presenza/core/auth/authservice.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    if (user != null) {
      final data = await authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    // App bar area
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Presenza',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Colors.white24, height: 1, thickness: 1),
                    // User info
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            // Avatar
                            CircleAvatar(
                              radius: 44,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              child: Text(
                                (_userData?['name'] as String?)
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userData?['name'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userData?['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Info cards
                            _buildInfoTile(
                                Icons.school_outlined,
                                'College',
                                _userData?['collegeName'] ?? '-'),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                                Icons.badge_outlined,
                                'Student ID',
                                _userData?['studentId'] ?? '-'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

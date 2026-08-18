import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:presenza/core/auth/login.dart';
import 'package:presenza/pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

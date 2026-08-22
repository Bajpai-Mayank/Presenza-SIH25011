import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization is required for production.
  // If it fails, the app cannot proceed safely.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Still run the app — auth state will handle showing an error screen.
    // But do NOT silently continue as if mock data is acceptable.
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wrap Firebase initialization in a try-catch.
  // If the user's Firebase config is missing or has errors, it will print a warning
  // and proceed in mock/offline mode.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Running app in mock offline mode.');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

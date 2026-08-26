import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables and initialize Supabase Backup
  try {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '',
    );
    debugPrint('Supabase backup initialized successfully.');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // Firebase initialization is required for production.
  // If it fails, the app cannot proceed safely.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // AuthStatusNotifier will detect the error state and display an error screen with retry option.
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

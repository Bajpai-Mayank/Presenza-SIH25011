import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:presenza/data/services/notification_service.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock Orientation to Portrait Only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase initialization is REQUIRED.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
    
    // Initialize Notifications
    await NotificationService().init();
    debugPrint('Notifications initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize the application.\nPlease check your connection or contact support.\nError: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SecurityEvent {
  screenCaptured,
  multiWindowEntered,
  multiWindowExited,
}

/// Platform security service providing hardware-level screen protection (FLAG_SECURE)
/// against screenshot capturing and screen recording during sensitive flows.
class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('com.example.presenza/security');
      
  static final StreamController<SecurityEvent> _eventController = 
      StreamController<SecurityEvent>.broadcast();

  static Stream<SecurityEvent> get securityEvents => _eventController.stream;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScreenCaptured':
          _eventController.add(SecurityEvent.screenCaptured);
          break;
        case 'onMultiWindowModeChanged':
          final bool isInMultiWindow = call.arguments as bool? ?? false;
          if (isInMultiWindow) {
            _eventController.add(SecurityEvent.multiWindowEntered);
          } else {
            _eventController.add(SecurityEvent.multiWindowExited);
          }
          break;
      }
    });
  }

  /// Enables screenshot and screen recording protection (Android FLAG_SECURE).
  static Future<bool> enableScreenshotProtection() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('enableSecure');
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint('SecurityService: Failed to enable FLAG_SECURE: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('SecurityService: Unexpected error enabling FLAG_SECURE: $e');
      return false;
    }
  }

  /// Disables screenshot and screen recording protection.
  static Future<bool> disableScreenshotProtection() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('disableSecure');
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint('SecurityService: Failed to disable FLAG_SECURE: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('SecurityService: Unexpected error disabling FLAG_SECURE: $e');
      return false;
    }
  }

  /// Checks if screenshot protection is currently active on Android.
  static Future<bool> isProtectionEnabled() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isSecureEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
  
  /// Checks if the app is currently in multi-window mode.
  static Future<bool> isMultiWindowMode() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isMultiWindowMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// A mixin for [StatefulWidget]s that automatically engages [FLAG_SECURE]
/// on mount and safely restores the window state on dispose.
mixin ScreenshotProtectedState<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SecurityService.enableScreenshotProtection();
  }

  @override
  void dispose() {
    SecurityService.disableScreenshotProtection();
    super.dispose();
  }
}

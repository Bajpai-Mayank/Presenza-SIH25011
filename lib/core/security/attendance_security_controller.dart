import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/core/services/security_service.dart';

enum SecurityState {
  idle,
  secureModeEnabled,
  compromised,
}

final attendanceSecurityProvider = StateNotifierProvider<AttendanceSecurityNotifier, SecurityState>((ref) {
  return AttendanceSecurityNotifier();
});

class AttendanceSecurityNotifier extends StateNotifier<SecurityState> with WidgetsBindingObserver {
  StreamSubscription<SecurityEvent>? _subscription;

  AttendanceSecurityNotifier() : super(SecurityState.idle) {
    WidgetsBinding.instance.addObserver(this);
    SecurityService.initialize();
    
    _subscription = SecurityService.securityEvents.listen((event) {
      if (event == SecurityEvent.screenCaptured || event == SecurityEvent.multiWindowEntered) {
        state = SecurityState.compromised;
      } else if (event == SecurityEvent.multiWindowExited) {
        state = SecurityState.secureModeEnabled;
      }
    });
  }

  Future<void> enableSecureMode() async {
    final success = await SecurityService.enableScreenshotProtection();
    if (success) {
      final isMulti = await SecurityService.isMultiWindowMode();
      if (isMulti) {
        state = SecurityState.compromised;
      } else {
        state = SecurityState.secureModeEnabled;
      }
    }
  }

  Future<void> disableSecureMode() async {
    await SecurityService.disableScreenshotProtection();
    state = SecurityState.idle;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (this.state != SecurityState.idle) {
        _checkMultiWindow();
      }
    }
  }

  Future<void> _checkMultiWindow() async {
    final isMulti = await SecurityService.isMultiWindowMode();
    if (isMulti) {
      state = SecurityState.compromised;
    } else if (state == SecurityState.compromised) {
       state = SecurityState.secureModeEnabled;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}

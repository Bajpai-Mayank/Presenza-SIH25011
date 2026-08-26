# Presenza Build & Release Report

## Build Information
- **Application ID**: `com.example.presenza`
- **Flutter Version**: Designed for 3.19.0+
- **Primary Language**: Dart
- **Target OS**: Android (Primary for Hackathon Demo) / iOS

## Dependencies Added / Checked
- `flutter_riverpod` - State management
- `go_router` - Declarative routing
- `cloud_firestore` - Database
- `firebase_auth` - Authentication
- `geolocator` - Location-based validations
- `qr_code_scanner` / `qr_flutter` - Attendance token generation & reading
- `uuid` - Session token generation
- `intl` - Date formatting

## Release Preparation Checklist
1. **Disable Test Buttons**: Removed all "Quick Login Demo" bypasses in `login_screen.dart`.
2. **ProGuard / R8**: Ensure `flutter build apk` obfuscates dart code to protect sensitive logic (e.g. `SecurityService`).
3. **Database Rules**: Check that `firestore.rules` blocks unauthorized writes to `audit_logs` and `user_sessions`.
4. **Android Permissions**: Verify `AndroidManifest.xml` retains `ACCESS_FINE_LOCATION` and camera permissions.

To execute a clean build:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

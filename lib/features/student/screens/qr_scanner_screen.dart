import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/security/attendance_security_controller.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/services/location_service.dart';
import 'package:presenza/providers/app_providers.dart';

/// QR Scanner Screen for classroom attendance verification.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;
  bool _scanComplete = false;
  String _statusMessage = 'Point Camera at Classroom QR';
  String _detailMessage = 'Align the QR code within the highlighted viewfinder.';
  bool _isSuccess = false;

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    ref.read(attendanceSecurityProvider.notifier).enableSecureMode();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    ref.read(attendanceSecurityProvider.notifier).disableSecureMode();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String code) async {
    if (_isProcessing || _scanComplete) return;

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying Attendance Session...';
      _detailMessage = 'Checking session validity with server...';
    });

    final student = ref.read(studentProfileProvider);
    if (student == null) {
      _showFailure('Student profile could not be loaded. Please log in again.');
      return;
    }

    try {
      final session = await _firestoreService.getAttendanceSession(trimmedCode);
      if (session == null) {
        _showFailure('Invalid QR code. No active session found.');
        return;
      }

      if (!session.isActive) {
        _showFailure('This attendance session has already been closed by the faculty.');
        return;
      }

      if (DateTime.now().isAfter(session.endTime)) {
        _showFailure('This attendance session has expired.');
        return;
      }

      if (session.courseId != student.courseId || session.batchId != student.batchId) {
        _showFailure('This session is for a different class or section.');
        return;
      }

      bool locationVerified = false;
      double? currentLat;
      double? currentLng;

      if (session.locationRequired && session.campusLat != null && session.campusLng != null) {
        setState(() {
          _statusMessage = 'Verifying Location...';
          _detailMessage = 'Checking GPS position within classroom bounds...';
        });

        final locResult = await _locationService.verifyLocation(
          targetLat: session.campusLat!,
          targetLng: session.campusLng!,
          allowedRadiusMeters: session.allowedRadiusMeters ?? 100.0,
        );

        if (!locResult.isVerified) {
          _showFailure(locResult.errorMessage ?? 'Location verification failed. You must be in the classroom.');
          return;
        }

        locationVerified = true;
        currentLat = locResult.latitude;
        currentLng = locResult.longitude;
      }

      setState(() {
        _statusMessage = 'Recording Attendance...';
        _detailMessage = 'Committing secure attendance record...';
      });

      final result = await _firestoreService.markAttendanceWithTransaction(
        sessionId: session.id,
        studentUid: student.user.id,
        studentDisplayId: student.studentId,
        studentCourseId: student.courseId,
        studentBatchId: student.batchId,
        locationVerified: locationVerified,
        latitude: currentLat,
        longitude: currentLng,
      );

      if (!result.success) {
        _showFailure(result.errorMessage ?? 'Failed to record attendance.');
        return;
      }

      setState(() {
        _scanComplete = true;
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Attendance Confirmed!';
        _detailMessage = 'Your attendance has been recorded successfully.';
      });
      _cameraController?.stop();
    } catch (e) {
      _showFailure('Error processing check-in: $e');
    }
  }

  void _showFailure(String errorMsg) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Attendance Failed';
      _detailMessage = errorMsg;
    });
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Enter Session Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the session code displayed on the faculty screen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: textController,
              labelText: 'Session Code / Token',
              prefixIcon: Icons.pin_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textController.text.trim();
              Navigator.pop(dialogCtx);
              if (code.isNotEmpty) {
                _processQrCode(code);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecurityOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Attendance QR'),
          actions: [
            if (!_scanComplete && !_isProcessing)
              IconButton(
                icon: const Icon(Icons.keyboard_outlined),
                tooltip: 'Enter code manually',
                onPressed: _showManualEntryDialog,
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isSuccess
                                    ? AppColors.success
                                    : (_statusMessage.contains('Failed')
                                        ? AppColors.error
                                        : AppColors.primary),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: _buildScannerArea(isDark),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _statusMessage,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _isSuccess
                                      ? AppColors.success
                                      : (_statusMessage.contains('Failed')
                                          ? AppColors.error
                                          : null),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _detailMessage,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_scanComplete || _statusMessage.contains('Failed'))
                  Row(
                    children: [
                      if (_statusMessage.contains('Failed'))
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _statusMessage = 'Point Camera at Classroom QR';
                                _detailMessage = 'Align the QR code within the highlighted viewfinder.';
                                _isProcessing = false;
                                _scanComplete = false;
                              });
                            },
                            child: const Text('Try Again'),
                          ),
                        ),
                      if (_statusMessage.contains('Failed')) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done / Return'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerArea(bool isDark) {
    if (_scanComplete && _isSuccess) {
      return Container(
        color: AppColors.success.withAlpha(25),
        child: const Center(
          child: Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: AppColors.success,
          ),
        ),
      );
    }

    if (_isProcessing) {
      return Container(
        color: (isDark ? AppColors.cardDark : AppColors.slate100),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_cameraController == null) {
      return const Center(child: Text('Camera initializing...'));
    }

    return MobileScanner(
      controller: _cameraController!,
      onDetect: (capture) {
        final barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            _processQrCode(barcode.rawValue!);
            break;
          }
        }
      },
    );
  }
}

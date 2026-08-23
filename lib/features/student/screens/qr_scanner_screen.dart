import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/services/security_service.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/services/location_service.dart';
import 'package:presenza/providers/app_providers.dart';

/// Production QR Scanner Screen for classroom attendance verification.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;
  bool _scanComplete = false;
  String _statusMessage = 'Point Camera at Classroom QR';
  String _detailMessage = 'Align the QR code within the highlighted square.';
  bool _isSuccess = false;

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    SecurityService.enableScreenshotProtection();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    SecurityService.disableScreenshotProtection();
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
      // 1. Fetch active session from Firestore
      final session = await _firestoreService.getAttendanceSession(trimmedCode);
      if (session == null) {
        _showFailure('Invalid QR code. No session found.');
        return;
      }

      if (!session.isActive) {
        _showFailure('This attendance session has already been closed by the teacher.');
        return;
      }

      if (DateTime.now().isAfter(session.endTime)) {
        _showFailure('This attendance session has expired.');
        return;
      }

      if (session.courseId != student.courseId || session.batchId != student.batchId) {
        _showFailure('This session is for a different class or batch.');
        return;
      }

      // 2. Perform location verification if required by session policy
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

      // 3. Mark attendance using Firestore transaction (atomic duplicate check & write)
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

      // 4. Success state
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
              'If camera scanning is unavailable, enter the session code displayed on the teacher screen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Session Code / Token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_scanComplete && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.keyboard_outlined),
              tooltip: 'Enter code manually',
              onPressed: _showManualEntryDialog,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    const Color(0xFF0F0F0F),
                    const Color(0xFF111111),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFEAEAEC),
                    AppColors.backgroundLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: GlassCard(
                      width: double.infinity,
                      height: 380,
                      borderRadius: 30,
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!_scanComplete && !_isProcessing)
                              MobileScanner(
                                controller: _cameraController,
                                onDetect: (capture) {
                                  final barcodes = capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue != null) {
                                      _processQrCode(barcode.rawValue!);
                                      break;
                                    }
                                  }
                                },
                              )
                            else
                              Container(
                                color: Colors.black.withAlpha(80),
                                child: Center(
                                  child: Icon(
                                    _isSuccess
                                        ? Icons.check_circle_outline
                                        : Icons.qr_code_scanner_outlined,
                                    size: 140,
                                    color: _isSuccess
                                        ? AppColors.success
                                        : Colors.white24,
                                  ),
                                ),
                              ),

                            // Highlight box overlay
                            if (!_scanComplete)
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _isProcessing
                                        ? AppColors.info
                                        : AppColors.white.withAlpha(100),
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),

                            // Laser animation
                            if (_isProcessing)
                              const _ScanningLineAnimation(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isSuccess
                                  ? AppColors.success
                                  : (!_isProcessing && _detailMessage.contains('Failed')
                                      ? AppColors.error
                                      : null),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detailMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray400,
                            ),
                      ),
                      const SizedBox(height: 20),
                      if (_isProcessing)
                        const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.white),
                          ),
                        ),
                      if (!_isProcessing && !_scanComplete) ...[
                        GlassButton(
                          label: 'Enter Code Manually',
                          icon: Icons.keyboard,
                          onPressed: _showManualEntryDialog,
                          filled: false,
                        ),
                      ],
                      if (_scanComplete)
                        GlassButton(
                          label: 'Back to Dashboard',
                          icon: Icons.check,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningLineAnimation extends StatefulWidget {
  const _ScanningLineAnimation();

  @override
  State<_ScanningLineAnimation> createState() => _ScanningLineAnimationState();
}

class _ScanningLineAnimationState extends State<_ScanningLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -100.0, end: 100.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 220,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.info,
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withAlpha(200),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

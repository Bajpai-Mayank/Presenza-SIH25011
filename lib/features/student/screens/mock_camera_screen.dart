import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/enums/attendance_status.dart';

/// Mock Camera Screen for face registration / verification demo
class MockCameraScreen extends StatefulWidget {
  const MockCameraScreen({super.key});

  @override
  State<MockCameraScreen> createState() => _MockCameraScreenState();
}

class _MockCameraScreenState extends State<MockCameraScreen> {
  bool _isScanning = false;
  bool _scanComplete = false;

  void _startScanning() async {
    setState(() {
      _isScanning = true;
      _scanComplete = false;
    });

    // Simulate face scanning duration
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanComplete = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face verification successful!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glass Viewport Box
                        GlassCard(
                          width: double.infinity,
                          height: 380,
                          borderRadius: 30,
                          padding: EdgeInsets.zero,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mock camera preview background
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(80),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 160,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                              
                              // Scanner reticle
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _scanComplete
                                        ? AppColors.success
                                        : (_isScanning ? AppColors.info : AppColors.white.withAlpha(100)),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(110),
                                ),
                              ),

                              // Moving laser line animation
                              if (_isScanning)
                                const _ScanningLineAnimation(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        _scanComplete
                            ? 'Verification Successful'
                            : (_isScanning ? 'Scanning Face...' : 'Align Face inside Circle'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scanComplete
                            ? 'Your identity has been authenticated.'
                            : 'Hold the camera still and ensure proper lighting.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray400,
                            ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isScanning && !_scanComplete)
                        GlassButton(
                          label: 'Start Verification',
                          onPressed: _startScanning,
                        ),
                      if (_isScanning)
                        const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.white),
                          ),
                        ),
                      if (_scanComplete)
                        GlassButton(
                          label: 'Done',
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

/// Qr Scanner Screen for scanning classroom code using MobileScanner
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
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String code) async {
    if (_isProcessing || _scanComplete) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying Session...';
    });

    final student = ref.read(studentProfileProvider);
    if (student == null) {
      _showFailure('Error: Student profile not found.');
      return;
    }

    try {
      // 1. Fetch active session from Firestore
      final session = await _firestoreService.getAttendanceSession(code);
      if (session == null || !session.isActive) {
        _showFailure('No active session found for this QR code.');
        return;
      }

      // Check if session belongs to student's course/batch
      if (session.courseId != student.courseId || session.batchId != student.batchId) {
        _showFailure('This session is not for your batch / class.');
        return;
      }

      // 2. Submit check-in record
      final now = DateTime.now();
      final record = AttendanceRecordModel(
        id: 'rec-${student.studentId}-${session.id}',
        studentId: student.studentId,
        attendanceSessionId: session.id,
        subjectId: session.subjectId,
        courseId: session.courseId,
        teacherId: session.teacherId,
        status: AttendanceStatus.present,
        verificationMethod: VerificationMethod.qr,
        timestamp: now,
        locationVerified: true,
        faceVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addAttendanceRecord(record);

      setState(() {
        _scanComplete = true;
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Attendance Checked-In';
        _detailMessage = 'Your attendance is successfully recorded!';
      });
      _cameraController?.stop();
    } catch (e) {
      _showFailure('Failed to mark attendance: $e');
    }
  }

  void _showFailure(String errorMsg) {
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Scan Failed';
      _detailMessage = errorMsg;
    });
  }

  // Fallback demo simulator check-in
  Future<void> _simulateScan() async {
    final student = ref.read(studentProfileProvider);
    if (student == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Locating active session...';
    });

    try {
      // Fetch active sessions matching the student's batch
      final activeSessionsStream = _firestoreService.streamActiveSessionsForBatch(student.courseId, student.batchId);
      final activeSessionsList = await activeSessionsStream.first;

      if (activeSessionsList.isEmpty) {
        // Fallback: No active session on Firestore, so we simulate a local success check-in record
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _scanComplete = true;
          _isProcessing = false;
          _isSuccess = true;
          _statusMessage = 'Attendance Checked-In (Demo)';
          _detailMessage = 'Simulated check-in successful!';
        });
        return;
      }

      final activeSession = activeSessionsList.first;
      await _processQrCode(activeSession.id);
    } catch (e) {
      _showFailure('Simulation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                            // Mobile Scanner Preview (if camera is active)
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
                                    _isSuccess ? Icons.check_circle_outline : Icons.qr_code_scanner_outlined,
                                    size: 140,
                                    color: _isSuccess ? AppColors.success : Colors.white24,
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

                            // Moving laser line animation
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
                      if (!_isProcessing && !_scanComplete) ...[
                        GlassButton(
                          label: 'Simulate Scan (Demo Mode)',
                          onPressed: _simulateScan,
                        ),
                      ],
                      if (_isProcessing)
                        const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.white),
                          ),
                        ),
                      if (_scanComplete)
                        GlassButton(
                          label: 'Back to Dashboard',
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

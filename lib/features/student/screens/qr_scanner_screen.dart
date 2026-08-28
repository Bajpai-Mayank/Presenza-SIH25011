import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/security/attendance_security_controller.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/services/location_service.dart';
import 'package:presenza/providers/app_providers.dart';

/// Dedicated QR Scanner Screen for classroom attendance verification with zoom controls.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _scanComplete = false;
  String _statusMessage = 'Scan the faculty QR code';
  String _detailMessage = 'Align the QR code within the highlighted viewfinder. Use zoom if scanning from a distance.';
  bool _isSuccess = false;

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  MobileScannerController? _cameraController;

  double _zoomScale = 0.0; // 0.0 = 1x (min), 1.0 = max zoom
  bool _isTorchOn = false;
  bool _isZoomSupported = true;

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    ref.read(attendanceSecurityProvider.notifier).enableSecureMode();

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: false,
    );

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    try {
      ref.read(attendanceSecurityProvider.notifier).disableSecureMode();
    } catch (_) {}
    _scanAnimController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _setZoom(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    setState(() => _zoomScale = clamped);
    try {
      await _cameraController?.setZoomScale(clamped);
    } catch (_) {
      if (mounted) {
        setState(() => _isZoomSupported = false);
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController?.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _processQrCode(String code) async {
    if (_isProcessing || _scanComplete) return;

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying Attendance...';
      _detailMessage = 'Connecting with attendance server...';
    });

    final student = ref.read(studentProfileProvider);
    if (student == null) {
      _showFailure('Student profile could not be loaded. Please log in again.');
      return;
    }

    try {
      final session = await _firestoreService.getAttendanceSession(trimmedCode);
      if (session == null) {
        _showFailure('Invalid QR code. No active class attendance session found.');
        return;
      }

      if (!session.isActive) {
        _showFailure('This attendance session has already been closed by faculty.');
        return;
      }

      if (DateTime.now().isAfter(session.endTime)) {
        _showFailure('This attendance session has expired.');
        return;
      }

      if (session.courseId != student.courseId || session.batchId != student.batchId) {
        _showFailure('This session is for a different degree program or section.');
        return;
      }

      bool locationVerified = false;
      double? currentLat;
      double? currentLng;

      if (session.locationRequired && session.campusLat != null && session.campusLng != null) {
        setState(() {
          _statusMessage = 'Verifying Location...';
          _detailMessage = 'Checking GPS position within classroom boundary (~100m)...';
        });

        final locResult = await _locationService.verifyLocation(
          targetLat: session.campusLat!,
          targetLng: session.campusLng!,
          allowedRadiusMeters: session.allowedRadiusMeters ?? 100.0,
        );

        if (!locResult.isVerified) {
          _showFailure(locResult.errorMessage ?? 'Location verification failed. You must be inside the classroom.');
          return;
        }

        locationVerified = true;
        currentLat = locResult.latitude;
        currentLng = locResult.longitude;
      }

      setState(() {
        _statusMessage = 'Recording Attendance...';
        _detailMessage = 'Submitting attendance confirmation...';
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
        _detailMessage = 'Your attendance for ${session.subjectName ?? "class"} has been marked successfully.';
      });
      _cameraController?.stop();
    } catch (e) {
      _showFailure('An error occurred during verification. Please try again.');
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the session token displayed on the classroom screen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: textController,
              labelText: 'Session Code / Token',
              hintText: 'e.g. 7f938d2a-...',
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
            child: const Text('Submit Code'),
          ),
        ],
      ),
    );
  }

  String _formatZoomDisplay(double scale) {
    // Map 0.0 -> 1.0x, 0.33 -> 1.5x, 0.66 -> 2.0x, 1.0 -> 3.0x
    final multiplier = 1.0 + (scale * 2.0);
    return '${multiplier.toStringAsFixed(1)}x';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecurityOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Attendance QR'),
          actions: [
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? Colors.amber : null,
              ),
              tooltip: _isTorchOn ? 'Turn Flash Off' : 'Turn Flash On',
              onPressed: _toggleTorch,
            ),
            if (!_scanComplete && !_isProcessing)
              IconButton(
                icon: const Icon(Icons.keyboard_outlined),
                tooltip: 'Enter code manually',
                onPressed: _showManualEntryDialog,
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                // ── Scanner Card with Viewfinder ───────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 280, maxWidth: 280),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isSuccess
                                ? AppColors.success
                                : (_statusMessage.contains('Failed')
                                    ? AppColors.error
                                    : AppColors.primary),
                            width: 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildScannerArea(isDark),
                              if (!_scanComplete && !_isProcessing) ...[
                                _buildCornerBrackets(),
                                _buildAnimatedScanLine(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Zoom Controls ────────────────────────────────────
                      if (_isZoomSupported && !_scanComplete && !_isProcessing) ...[
                        _buildZoomControlSection(isDark),
                        const SizedBox(height: 12),
                      ],

                      // Status Header
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _isSuccess
                                  ? AppColors.success
                                  : (_statusMessage.contains('Failed')
                                      ? AppColors.error
                                      : null),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _detailMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Action Buttons (Retry / Done / Return) ──────────────────
                if (_scanComplete || _statusMessage.contains('Failed')) ...[
                  Row(
                    children: [
                      if (_statusMessage.contains('Failed')) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: () {
                              setState(() {
                                _statusMessage = 'Scan the faculty QR code';
                                _detailMessage = 'Align the QR code within the highlighted viewfinder.';
                                _isProcessing = false;
                                _scanComplete = false;
                                _isSuccess = false;
                              });
                              _cameraController?.start();
                            },
                            label: const Text('Try Again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.pop(context),
                          label: Text(_isSuccess ? 'Return to Home' : 'Cancel'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.pin_outlined, size: 18),
                    label: const Text('Having trouble? Enter session code manually'),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControlSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.zoom_in_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Zoom: ${_formatZoomDisplay(_zoomScale)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Step Down Button
                  InkWell(
                    onTap: () => _setZoom(_zoomScale - 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Step Up Button
                  InkWell(
                    onTap: () => _setZoom(_zoomScale + 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Zoom Quick Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildZoomChip('1.0x', 0.0),
              _buildZoomChip('1.5x', 0.25),
              _buildZoomChip('2.0x', 0.5),
              _buildZoomChip('3.0x', 1.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomChip(String label, double scale) {
    final isSelected = (_zoomScale - scale).abs() < 0.12;
    return InkWell(
      onTap: () => _setZoom(scale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.slate300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCornerBrackets() {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedScanLine() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: 30 + (_scanAnimation.value * 200),
          left: 30,
          right: 30,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScannerArea(bool isDark) {
    if (_scanComplete && _isSuccess) {
      return Container(
        color: AppColors.success.withValues(alpha: 0.15),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Verifying...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
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

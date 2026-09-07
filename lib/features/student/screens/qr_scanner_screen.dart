import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
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
  bool _isExpiredError = false;

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  MobileScannerController? _cameraController;

  double _zoomScale = 0.0; // 0.0 = 1x (min), 1.0 = max zoom
  bool _isTorchOn = false;

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
    
    // Only attempt hardware camera zoom on native Android / iOS devices
    if (!kIsWeb && _cameraController != null) {
      try {
        await _cameraController!.setZoomScale(clamped);
      } catch (e) {
        debugPrint('Optical zoom not supported on this lens, digital zoom active: $e');
      }
    }
  }

  void _cycleNextZoom() {
    if (_zoomScale < 0.2) {
      _setZoom(0.25); // 1.5x
    } else if (_zoomScale < 0.45) {
      _setZoom(0.5); // 2.0x
    } else if (_zoomScale < 0.9) {
      _setZoom(1.0); // 3.0x
    } else {
      _setZoom(0.0); // 1.0x
    }
  }

  Future<void> _toggleTorch() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.toggleTorch();
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (e) {
      debugPrint('Torch not supported or hardware error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash/torch is not available on this device lens.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

      if (session.isExpired || DateTime.now().isAfter(session.endTime)) {
        _showExpired();
        return;
      }

      if (session.courseId != student.courseId || session.batchId != student.batchId) {
        _showFailure('This attendance session is not assigned to your batch/section.');
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
        final err = result.errorMessage ?? '';
        if (err.contains('already marked') || err.contains('already recorded')) {
          _showFailure('Attendance already recorded for this session.');
        } else if (err.contains('expired')) {
          _showExpired();
        } else {
          _showFailure(err.isNotEmpty ? err : 'Failed to record attendance.');
        }
        return;
      }

      setState(() {
        _scanComplete = true;
        _isProcessing = false;
        _isSuccess = true;
        _isExpiredError = false;
        _statusMessage = 'Attendance Confirmed!';
        _detailMessage = 'Your attendance for ${session.subjectName ?? "class"} has been marked successfully.';
      });
      _cameraController?.stop();
    } catch (e) {
      _showFailure('An error occurred during verification. Please try again.');
    }
  }

  void _showExpired() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _scanComplete = false;
      _isSuccess = false;
      _isExpiredError = true;
      _statusMessage = 'QR CODE EXPIRED';
      _detailMessage =
          'This attendance session has ended.\n\nPlease ask your faculty to generate a new attendance QR code.';
    });
  }

  void _showFailure(String errorMsg) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _scanComplete = false;
      _isSuccess = false;
      _isExpiredError = false;
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                // ── Inline Toolbar (replaces AppBar) ────────────────────────
                if (!_scanComplete && !_isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scan Attendance QR',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: _isTorchOn ? Colors.amber : (isDark ? Colors.white70 : Colors.black54),
                                size: 22,
                              ),
                              tooltip: _isTorchOn ? 'Turn Flash Off' : 'Turn Flash On',
                              onPressed: _toggleTorch,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_outlined,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 22,
                              ),
                              tooltip: 'Enter code manually',
                              onPressed: _showManualEntryDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                                // ── Floating Quick Zoom Pill on Viewfinder ──────
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: _cycleNextZoom,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.zoom_in_rounded, size: 15, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatZoomDisplay(_zoomScale),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Zoom Controls (Always Visible) ──────────────────
                      if (!_scanComplete && !_isProcessing) ...[
                        _buildZoomControlSection(isDark),
                        const SizedBox(height: 14),
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

                // ── Action Buttons (Retry / Done / Return / Expired) ───────
                if (_isExpiredError) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.primary(
                          label: 'Scan New QR',
                          icon: Icons.qr_code_scanner_rounded,
                          onPressed: () {
                            setState(() {
                              _statusMessage = 'Scan the faculty QR code';
                              _detailMessage = 'Align the QR code within the highlighted viewfinder.';
                              _isProcessing = false;
                              _scanComplete = false;
                              _isSuccess = false;
                              _isExpiredError = false;
                            });
                            _cameraController?.start();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.outlined(
                          label: 'Contact Faculty',
                          icon: Icons.help_outline_rounded,
                          onPressed: () => context.push('/help'),
                        ),
                      ),
                    ],
                  ),
                ] else if (_scanComplete || _statusMessage.contains('Failed')) ...[
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
                                _isExpiredError = false;
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
                          onPressed: () {
                            // Reset scanner state for re-use in tab
                            setState(() {
                              _statusMessage = 'Scan the faculty QR code';
                              _detailMessage = 'Align the QR code within the highlighted viewfinder. Use zoom if scanning from a distance.';
                              _isProcessing = false;
                              _scanComplete = false;
                              _isSuccess = false;
                              _isExpiredError = false;
                            });
                            _cameraController?.start();
                          },
                          label: Text(_isSuccess ? 'Scan Another' : 'Reset'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── Header + Buttons Row ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.zoom_in_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Zoom: ${_formatZoomDisplay(_zoomScale)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Step Down Button — larger hit target
                  Material(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _setZoom(_zoomScale - 0.15),
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.remove_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Step Up Button — larger hit target
                  Material(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _setZoom(_zoomScale + 0.15),
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.add_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Continuous Slider ────────────────────────────────────
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _zoomScale,
              min: 0.0,
              max: 1.0,
              onChanged: (v) => _setZoom(v),
            ),
          ),
          const SizedBox(height: 4),

          // ── Zoom Quick Chips ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildZoomChip('1x', 0.0),
              _buildZoomChip('1.5x', 0.25),
              _buildZoomChip('2x', 0.5),
              _buildZoomChip('3x', 1.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomChip(String label, double scale) {
    final isSelected = (_zoomScale - scale).abs() < 0.12;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setZoom(scale),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.slate300,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : null,
            ),
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

    return GestureDetector(
      onDoubleTap: _cycleNextZoom,
      child: ClipRect(
        child: Transform.scale(
          scale: 1.0 + (_zoomScale * 1.5),
          child: MobileScanner(
            controller: _cameraController!,
            errorBuilder: (context, error) {
              return Container(
                color: isDark ? AppColors.surfaceDark : const Color(0xFF1E293B),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, color: Colors.amber, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Camera Access Required',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Presenza needs camera access to scan attendance QR codes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _cameraController?.start();
                            },
                            child: const Text('Allow Camera', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            onPressed: () {
                              Geolocator.openAppSettings();
                            },
                            child: const Text('Open Settings', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

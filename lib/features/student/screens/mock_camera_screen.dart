import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

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

/// Mock QR Scanner Screen for scanning classroom code
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanning = false;
  bool _scanComplete = false;

  void _scanCode() async {
    setState(() {
      _isScanning = true;
      _scanComplete = false;
    });

    // Simulate QR code scanning duration
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanComplete = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance recorded successfully!'),
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background mock camera feed
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(80),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          
                          // QR scan area overlay
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _scanComplete
                                    ? AppColors.success
                                    : (_isScanning ? AppColors.info : AppColors.white.withAlpha(100)),
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),

                          // Moving laser line animation
                          if (_isScanning)
                            const _ScanningLineAnimation(),
                            
                          const Center(
                            child: Icon(
                              Icons.qr_code_scanner_outlined,
                              size: 140,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        _scanComplete
                            ? 'Attendance Checked-In'
                            : (_isScanning ? 'Scanning...' : 'Point Camera at Classroom QR'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scanComplete
                            ? 'Your present mark is successfully submitted!'
                            : 'Align the QR code within the highlighted square.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray400,
                            ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isScanning && !_scanComplete)
                        GlassButton(
                          label: 'Simulate Scan',
                          onPressed: _scanCode,
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

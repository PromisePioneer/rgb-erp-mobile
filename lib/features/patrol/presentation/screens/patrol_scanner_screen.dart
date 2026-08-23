import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_spacing.dart';

/// Scanner screen for scanning checkpoint QR codes
class PatrolScannerScreen extends StatefulWidget {
  const PatrolScannerScreen({super.key});

  @override
  State<PatrolScannerScreen> createState() => _PatrolScannerScreenState();
}

class _PatrolScannerScreenState extends State<PatrolScannerScreen> {
  MobileScannerController? _controller;
  bool _isInitialized = false;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal akses kamera');
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Got a QR code, return it
    setState(() => _hasScanned = true);
    context.pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Scanner or error
            if (_errorMessage != null)
              _buildError()
            else if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_controller != null)
              _buildScanner(),

            // Guide overlay
            if (_isInitialized && !_hasScanned) _buildGuideOverlay(),

            // Controls
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Center(
      child: MobileScanner(
        controller: _controller!,
        onDetect: _onDetect,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _errorMessage ?? 'Gagal akses kamera',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitialized = false;
                  });
                  _initializeScanner();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(
            Icons.qr_code_scanner,
            color: Colors.white54,
            size: 80,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: const Text(
                  'Arahkan kamera ke QR code checkpoint',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Flash toggle
              if (_controller != null)
                IconButton(
                  onPressed: () => _controller?.toggleTorch(),
                  icon: const Icon(Icons.flash_off, color: Colors.white, size: 28),
                ),
              const SizedBox(height: AppSpacing.md),
              // Cancel button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

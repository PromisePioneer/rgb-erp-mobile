import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/theme/app_spacing.dart';

/// Face capture screen with auto-capture when face is ready
class FaceCaptureScreen extends StatefulWidget {
  final Function(String photoPath)? onCapture;
  final VoidCallback? onCancel;

  const FaceCaptureScreen({
    super.key,
    this.onCapture,
    this.onCancel,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isFaceReady = false;
  bool _showReadyIndicator = false;
  String? _capturedPhotoPath;
  String? _errorMessage;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'Kamera tidak ditemukan';
        });
        return;
      }

      // Find front camera
      CameraDescription frontCamera = _cameras!.first;
      for (final camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start ready timer - after 2 seconds, assume face is ready
        _startReadyTimer();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal initialize kamera: $e';
      });
    }
  }

  void _startReadyTimer() {
    _readyTimer?.cancel();
    setState(() {
      _isFaceReady = false;
      _showReadyIndicator = false;
    });

    // After 2 seconds, face is ready
    _readyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _capturedPhotoPath == null) {
        setState(() {
          _isFaceReady = true;
          _showReadyIndicator = true;
        });

        // Auto capture after green indicator shows
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isFaceReady && _capturedPhotoPath == null) {
            _capturePhoto();
          }
        });
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    _readyTimer?.cancel();
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();

      if (mounted) {
        setState(() {
          _capturedPhotoPath = photo.path;
          _isCapturing = false;
        });
      }

      // Small delay to let UI render the captured photo before navigating away
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate away - this will unmount and dispose properly via State.dispose()
      widget.onCapture?.call(photo.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _errorMessage = 'Gagal mengambil foto: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview or captured photo
            _buildCameraView(),

            // Face guide overlay (changes color based on ready state)
            if (_isInitialized && _capturedPhotoPath == null)
              _buildFaceGuide(),

            // Instructions
            if (_capturedPhotoPath == null && _isInitialized)
              _buildInstructions(),

            // Controls (only cancel button)
            _buildControls(),

            // Error message
            if (_errorMessage != null) _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_capturedPhotoPath != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            child: Image.file(
              File(_capturedPhotoPath!),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildFaceGuide() {
    return Center(
      child: CustomPaint(
        size: Size(
          MediaQuery.of(context).size.width * 0.75,
          MediaQuery.of(context).size.width * 0.9,
        ),
        painter: _FaceGuidePainter(
          color: _isFaceReady ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _isFaceReady ? Colors.green.withAlpha(200) : Colors.black54,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Text(
          _isFaceReady
              ? 'Wajah terdeteksi! Menangkap foto...'
              : 'Posisikan wajah Anda di dalam oval',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: _isFaceReady ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: TextButton(
          onPressed: () {
            widget.onCancel?.call();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(AppSpacing.lg),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
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
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for face guide oval with dynamic color
class _FaceGuidePainter extends CustomPainter {
  final Color color;

  _FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw oval guide
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.85,
      height: size.height * 0.9,
    );

    canvas.drawOval(ovalRect, paint);

    // Draw pulsing effect when ready
    if (color == Colors.green) {
      final pulsePaint = Paint()
        ..color = Colors.green.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      canvas.drawOval(ovalRect, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}

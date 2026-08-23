import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/camera/face_capture_screen.dart';

/// Screen for capturing face with live camera preview
class AttendanceCaptureScreen extends StatelessWidget {
  const AttendanceCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FaceCaptureScreen(
      onCapture: (photoPath) {
        // Navigate back with result
        context.pop(photoPath);
      },
      onCancel: () {
        context.pop();
      },
    );
  }
}

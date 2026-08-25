import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/camera/face_capture_screen.dart';
import '../providers/face_enrollment_provider.dart';

/// Screen for capturing face enrollment with live camera preview
class FaceEnrollmentCaptureScreen extends StatelessWidget {
  final String? initialPhotoPath;

  const FaceEnrollmentCaptureScreen({
    super.key,
    this.initialPhotoPath,
  });

  @override
  Widget build(BuildContext context) {
    return FaceCaptureScreen(
      onCapture: (photoPath) async {
        print('FACE_ENROLL_SCREEN: Photo captured: $photoPath');

        // Submit enrollment
        final notifier = context.read<FaceEnrollmentNotifier>();
        print('FACE_ENROLL_SCREEN: Calling enrollFace...');
        final result = await notifier.enrollFace(photoPath: photoPath);
        print('FACE_ENROLL_SCREEN: Result: success=${result?.success}, message=${result?.message}');

        if (context.mounted) {
          if (result != null && result.success) {
            // Update auth state with hasFaceEnrollment = true
            context.read<AuthNotifier>().setFaceEnrollment(true);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: AppColors.success,
              ),
            );
            // Redirect to dashboard instead of staying on face enrollment screen
            context.go('/dashboard');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result?.message ?? 'Gagal mendaftarkan wajah'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      },
      onCancel: () {
        context.pop();
      },
    );
  }
}

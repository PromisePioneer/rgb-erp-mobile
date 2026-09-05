import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/camera/face_capture_screen.dart';
import '../providers/face_enrollment_provider.dart';

IconData _getErrorIcon() => IconMap.errorOutline;
IconData _getCheckIcon() => IconMap.checkCircle;

/// Shows a custom notification overlay
void _showNotification(BuildContext context, String message, {Color? backgroundColor}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.success,
            borderRadius: AppRadius.radiusMd,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Icon(
                backgroundColor == AppColors.danger
                    ? _getErrorIcon()
                    : _getCheckIcon(),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

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
        // Submit enrollment
        final notifier = context.read<FaceEnrollmentNotifier>();

        final result = await notifier.enrollFace(photoPath: photoPath);

        if (context.mounted) {
          if (result != null && result.success) {
            // Update auth state with hasFaceEnrollment = true
            context.read<AuthNotifier>().setFaceEnrollment(true);

            _showNotification(
              context,
              result.message,
              backgroundColor: AppColors.success,
            );
            // Redirect to dashboard instead of staying on face enrollment screen
            context.go('/dashboard');
          } else {
            _showNotification(
              context,
              result?.message ?? 'Gagal mendaftarkan wajah',
              backgroundColor: AppColors.danger,
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

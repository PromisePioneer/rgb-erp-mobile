import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../providers/face_enrollment_provider.dart';

/// Face enrollment status screen
class FaceEnrollmentStatusScreen extends StatefulWidget {
  const FaceEnrollmentStatusScreen({super.key});

  @override
  State<FaceEnrollmentStatusScreen> createState() => _FaceEnrollmentStatusScreenState();
}

class _FaceEnrollmentStatusScreenState extends State<FaceEnrollmentStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaceEnrollmentNotifier>().loadEnrollmentStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Pendaftaran Wajah'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Consumer<FaceEnrollmentNotifier>(
          builder: (context, notifier, child) {
            if (notifier.state.isLoading && notifier.state.status == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final isEnrolled = notifier.state.isEnrolled;
            final faceInfo = notifier.state.faceInfo;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status card
                  _buildStatusCard(isEnrolled, faceInfo),

                  const SizedBox(height: AppSpacing.lg),

                  // Face info
                  if (isEnrolled && faceInfo != null) ...[
                    _buildFaceInfoCard(faceInfo),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Error message
                  if (notifier.state.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              notifier.state.error!,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                // Action button
                if (isEnrolled)
                  _buildEnrolledActions(notifier)
                else
                  _buildNotEnrolledContent(notifier),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildStatusCard(bool isEnrolled, dynamic faceInfo) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnrolled
              ? [AppColors.success, AppColors.success.withAlpha(200)]
              : [AppColors.warning, AppColors.warning.withAlpha(200)],
        ),
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        children: [
          Icon(
            isEnrolled ? Icons.face : Icons.face_outlined,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isEnrolled ? 'Wajah Terdaftar' : 'Belum Terdaftar',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEnrolled
                ? 'Anda dapat melakukan absensi dengan verifikasi wajah'
                : 'Daftarkan wajah Anda untuk dapat melakukan absensi',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFaceInfoCard(dynamic faceInfo) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Wajah',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Provider', faceInfo.provider ?? 'Unknown'),
          _buildInfoRow('Jumlah Foto', '${faceInfo.photoCount} foto'),
          if (faceInfo.enrolledAt != null)
            _buildInfoRow(
              'Tanggal Daftar',
              _formatDate(faceInfo.enrolledAt),
            ),
          _buildInfoRow('Status', faceInfo.isActive ? 'Aktif' : 'Tidak Aktif'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnrolledContent(FaceEnrollmentNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Column(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 40),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Cara Mendaftarkan Wajah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildStep(1, 'Pastikan wajah terlihat jelas'),
              _buildStep(2, 'Hindari cahaya terlalu terang/gelap'),
              _buildStep(3, 'Posisikan wajah di dalam oval panduan'),
              _buildStep(4, 'Ambil foto sesuai instruksi'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Daftarkan Wajah',
          icon: Icons.camera_alt,
          isLoading: notifier.state.isCapturing || notifier.state.isEnrolling,
          onPressed: () => _handleEnrollment(notifier),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledActions(FaceEnrollmentNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: AppRadius.radiusLg,
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Wajah Anda sudah terdaftar dan dapat digunakan untuk absensi',
                  style: TextStyle(color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          label: 'Hapus Pendaftaran',
          icon: Icons.delete_outline,
          isDanger: true,
          isLoading: notifier.state.isLoading,
          onPressed: () => _showDeleteConfirmation(notifier),
        ),
      ],
    );
  }

  Future<void> _handleEnrollment(FaceEnrollmentNotifier notifier) async {
    // Navigate to camera capture screen
    if (mounted) {
      context.push('/face-enrollment/capture');
    }
  }

  Future<void> _showDeleteConfirmation(FaceEnrollmentNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pendaftaran?'),
        content: const Text(
          'Wajah yang terdaftar akan dihapus. Anda perlu mendaftarkan wajah kembali untuk dapat absen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await notifier.deleteEnrollment();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran wajah berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

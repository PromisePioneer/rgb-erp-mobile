import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
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
              return const Center(child: LoadingIndicator(size: 32));
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
                        color: context.theme.colors.destructive,
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Row(
                        children: [
                          Icon(IconMap.errorOutline, color: context.theme.colors.destructiveForeground),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              notifier.state.error!,
                              style: TextStyle(color: context.theme.colors.destructiveForeground),
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
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.primary,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        children: [
          Icon(
            IconMap.face,
            size: 80,
            color: theme.colors.primaryForeground,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isEnrolled ? 'Wajah Terdaftar' : 'Belum Terdaftar',
            style: TextStyle(
              color: theme.colors.primaryForeground,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEnrolled
                ? 'Anda dapat melakukan absensi dengan verifikasi wajah'
                : 'Daftarkan wajah Anda untuk dapat absensi',
            style: TextStyle(color: theme.colors.primaryForeground.withAlpha(179)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFaceInfoCard(dynamic faceInfo) {
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Wajah',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
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
    final theme = FTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.colors.mutedForeground),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnrolledContent(FaceEnrollmentNotifier notifier) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colors.secondary,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Column(
            children: [
              Icon(IconMap.infoOutline, color: theme.colors.secondaryForeground, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cara Mendaftarkan Wajah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colors.secondaryForeground,
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
          icon: IconMap.cameraAlt,
          isLoading: notifier.state.isCapturing || notifier.state.isEnrolling,
          onPressed: () => _handleEnrollment(notifier),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    final theme = FTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colors.secondaryForeground.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colors.secondaryForeground,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: theme.colors.secondaryForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledActions(FaceEnrollmentNotifier notifier) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colors.primary.withAlpha(25),
            borderRadius: AppRadius.radiusLg,
          ),
          child: Row(
            children: [
              Icon(IconMap.checkCircle, color: theme.colors.primary),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Wajah Anda sudah terdaftar dan dapat digunakan untuk absensi',
                  style: TextStyle(color: theme.colors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          label: 'Hapus Pendaftaran',
          icon: IconMap.remove,
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
          FButton(
            onPress: () => Navigator.pop(context, false),
            variant: FButtonVariant.ghost,
            child: const Text('Batal'),
          ),
          FButton(
            onPress: () => Navigator.pop(context, true),
            variant: FButtonVariant.destructive,
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await notifier.deleteEnrollment();
      if (success && mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pendaftaran wajah berhasil dihapus'),
            backgroundColor: theme.colors.primary,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

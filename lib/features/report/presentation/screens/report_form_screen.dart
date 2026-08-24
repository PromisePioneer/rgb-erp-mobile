import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../providers/report_provider.dart';

/// Field report form screen - simple form with auto location & time
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<ReportNotifier>();
      notifier.reset();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notifier = context.read<ReportNotifier>();

    // Get location first
    await notifier.getLocation();
    if (!mounted) return;

    // Validate time
    await notifier.validateTime();
    if (!mounted) return;

    if (notifier.state.locationError != null) {
      _showErrorDialog(
        'Lokasi Tidak Valid',
        notifier.state.locationError!,
      );
      return;
    }

    if (!notifier.state.isTimeValid) {
      _showErrorDialog(
        'Waktu Tidak Valid',
        'Waktu perangkat tidak valid. Mohon perbarui waktu otomatis di pengaturan perangkat.',
      );
      return;
    }

    // Submit
    final success = await notifier.submit();
    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(
        'Gagal',
        notifier.state.submitError ?? 'Terjadi kesalahan saat menyimpan laporan.',
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Berhasil'),
          ],
        ),
        content: const Text('Laporan lapangan berhasil disimpan.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Buat Laporan Lapangan'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: Consumer<ReportNotifier>(
        builder: (context, notifier, child) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Info card - auto captured data
                  _buildInfoCard(notifier),
                  const SizedBox(height: AppSpacing.md),

                  // Description field
                  _buildSection(
                    'Deskripsi Laporan',
                    _buildDescriptionField(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location status
                  _buildLocationStatus(notifier),
                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  PrimaryButton(
                    label: 'Simpan Laporan',
                    icon: Icons.send,
                    isLoading: notifier.state.isSubmitting,
                    onPressed: notifier.state.canSubmit ? _handleSubmit : null,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),

              // Loading overlay
              if (notifier.state.isSubmitting)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(ReportNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Waktu dan lokasi akan dicatat otomatis saat laporan disimpan.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildDescriptionField(ReportNotifier notifier) {
    return TextField(
      controller: _descriptionController,
      maxLines: 5,
      maxLength: 2000,
      decoration: InputDecoration(
        hintText: 'Tuliskan deskripsi laporan lapangan...',
        hintStyle: TextStyle(color: AppColors.gray400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      onChanged: (v) => notifier.updateDescription(v),
    );
  }

  Widget _buildLocationStatus(ReportNotifier notifier) {
    final location = notifier.state.location;
    final error = notifier.state.locationError;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: location != null ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: location != null ? AppColors.success : AppColors.danger,
        ),
      ),
      child: Row(
        children: [
          Icon(
            location != null ? Icons.location_on : Icons.location_off,
            color: location != null ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              location != null
                  ? 'Lokasi: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'
                  : error ?? 'Lokasi belum tersedia',
              style: TextStyle(
                color: location != null ? AppColors.success : AppColors.danger,
                fontSize: 14,
              ),
            ),
          ),
          if (location == null)
            TextButton(
              onPressed: () => notifier.getLocation(),
              child: Text(
                'Coba Lagi',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}

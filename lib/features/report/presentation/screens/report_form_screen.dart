import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/dialogs/alert_dialogs.dart';
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
      ErrorDialog.show(
        context: context,
        title: 'Lokasi Tidak Valid',
        message: notifier.state.locationError!,
      );
      return;
    }

    if (!notifier.state.isTimeValid) {
      ErrorDialog.show(
        context: context,
        title: 'Waktu Tidak Valid',
        message: 'Waktu perangkat tidak valid. Mohon perbarui waktu otomatis di pengaturan perangkat.',
      );
      return;
    }

    // Submit
    final success = await notifier.submit();
    if (!mounted) return;

    if (success) {
      SuccessDialog.show(
        context: context,
        title: 'Berhasil',
        message: 'Laporan mutasi berhasil disimpan.',
        buttonText: 'OK',
      );
    } else {
      ErrorDialog.show(
        context: context,
        title: 'Gagal',
        message: notifier.state.submitError ?? 'Terjadi kesalahan saat menyimpan laporan.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Buat Laporan Mutasi'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
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
                    icon: IconMap.send,
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
                    child: LoadingIndicator(size: 48),
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.info.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(IconMap.infoOutline, color: AppColors.info, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Waktu dan lokasi akan dicatat otomatis saat laporan disimpan.',
              style: TextStyle(fontSize: 13, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label, Widget child) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildDescriptionField(ReportNotifier notifier) {
    return FTextField(
      control: FTextFieldControl.managed(
        controller: _descriptionController,
        onChange: (value) => notifier.updateDescription(value.text),
      ),
      size: FTextFieldSizeVariant.md,
      hint: 'Tuliskan deskripsi laporan Mutasi...',
      maxLines: 5,
      maxLength: 2000,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildLocationStatus(ReportNotifier notifier) {
    final location = notifier.state.location;
    final error = notifier.state.locationError;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: location != null ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: location != null ? AppColors.success : AppColors.danger,
        ),
      ),
      child: Row(
        children: [
          Icon(
            location != null ? IconMap.locationOn : IconMap.locationOff,
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
            FButton(
              onPress: () => notifier.getLocation(),
              variant: FButtonVariant.ghost,
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

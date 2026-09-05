import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/backup_offer.dart';

/// Dialog for backup offer (accept/reject)
class BackupOfferDialog extends StatefulWidget {
  final BackupOffer offer;
  final Future<bool> Function(String action, {String? reason}) onRespond;

  const BackupOfferDialog({
    super.key,
    required this.offer,
    required this.onRespond,
  });

  /// Show the backup offer dialog
  static Future<bool?> show(
    BuildContext context, {
    required BackupOffer offer,
    required Future<bool> Function(String action, {String? reason}) onRespond,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupOfferDialog(
        offer: offer,
        onRespond: onRespond,
      ),
    );
  }

  @override
  State<BackupOfferDialog> createState() => _BackupOfferDialogState();
}

class _BackupOfferDialogState extends State<BackupOfferDialog> {
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.offer.remainingSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        // Offer expired, close dialog
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    final success = await widget.onRespond('accept');
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    final success = await widget.onRespond('reject');
    if (mounted) {
      Navigator.of(context).pop(!success); // Return true if rejected successfully
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isExpired = _remainingSeconds <= 0;
    final isLowTime = _remainingSeconds < 300;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: Icon(IconMap.swapHoriz, color: theme.colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tawaran Backup Jaga',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Timer countdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isLowTime ? AppColors.dangerBg : AppColors.primaryBg,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconMap.timer,
                      size: 20,
                      color: isLowTime ? AppColors.danger : theme.colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isExpired
                          ? 'Waktu Habis'
                          : 'Berakhir dalam: ${_formatTime(_remainingSeconds)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLowTime ? AppColors.danger : theme.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Schedule details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(IconMap.calendarToday, 'Tanggal', widget.offer.date),
                    const SizedBox(height: AppSpacing.sm),
                    if (widget.offer.areaName != null)
                      _buildInfoRow(IconMap.locationOn, 'Area', widget.offer.areaName!),
                    const SizedBox(height: AppSpacing.sm),
                    if (widget.offer.posName != null)
                      _buildInfoRow(IconMap.place, 'POS', widget.offer.posName!),
                    const SizedBox(height: AppSpacing.sm),
                    if (widget.offer.shiftName != null)
                      _buildInfoRow(IconMap.accessTime, 'Shift', widget.offer.shiftName!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Info text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.warning.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    Icon(IconMap.infoOutline, color: AppColors.amber500, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Menjadi backup jaga berarti Anda menggantikan petugas original.',
                        style: TextStyle(
                          color: AppColors.amber500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'TOLAK',
                      onPressed: (_isLoading || isExpired) ? null : _reject,
                      isDanger: true,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'TERIMA',
                      onPressed: (_isLoading || isExpired) ? null : _accept,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

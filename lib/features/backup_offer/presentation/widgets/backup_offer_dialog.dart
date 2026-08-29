import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/core.dart';
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
    final isExpired = _remainingSeconds <= 0;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.swap_horiz, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('Tawaran Backup Jaga')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer countdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _remainingSeconds < 300 // Less than 5 minutes
                  ? AppColors.dangerBg
                  : AppColors.primaryBg,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: _remainingSeconds < 300
                      ? AppColors.danger
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isExpired
                      ? 'Waktu Habis'
                      : 'Berakhir dalam: ${_formatTime(_remainingSeconds)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 300
                        ? AppColors.danger
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Schedule details
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sky50,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.calendar_today, 'Tanggal', widget.offer.date),
                const SizedBox(height: AppSpacing.sm),
                if (widget.offer.areaName != null)
                  _buildInfoRow(Icons.location_on, 'Area', widget.offer.areaName!),
                const SizedBox(height: AppSpacing.sm),
                if (widget.offer.posName != null)
                  _buildInfoRow(Icons.place, 'POS', widget.offer.posName!),
                const SizedBox(height: AppSpacing.sm),
                if (widget.offer.shiftName != null)
                  _buildInfoRow(Icons.access_time, 'Shift', widget.offer.shiftName!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Info text
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.amber50,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.amber200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.amber600, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Menjadi backup jaga berarti Anda menggantikan petugas original.',
                    style: TextStyle(
                      color: AppColors.amber600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Reject button
        OutlinedButton(
          onPressed: (_isLoading || isExpired) ? null : _reject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.textSecondary),
          ),
          child: const Text('TOLAK'),
        ),
        // Accept button
        ElevatedButton(
          onPressed: (_isLoading || isExpired) ? null : _accept,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('TERIMA'),
        ),
      ],
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

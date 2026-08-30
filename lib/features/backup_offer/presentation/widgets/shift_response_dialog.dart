import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/shift_response.dart';

/// Dialog for responding to shift reminder
class ShiftResponseDialog extends StatefulWidget {
  final PendingShiftResponse shift;
  final Future<ShiftRespondResponse?> Function(String action, {String? reason}) onRespond;

  const ShiftResponseDialog({
    super.key,
    required this.shift,
    required this.onRespond,
  });

  /// Show the shift response dialog
  static Future<ShiftRespondResponse?> show(
    BuildContext context, {
    required PendingShiftResponse shift,
    required Future<ShiftRespondResponse?> Function(String action, {String? reason}) onRespond,
  }) {
    return showDialog<ShiftRespondResponse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShiftResponseDialog(
        shift: shift,
        onRespond: onRespond,
      ),
    );
  }

  @override
  State<ShiftResponseDialog> createState() => _ShiftResponseDialogState();
}

class _ShiftResponseDialogState extends State<ShiftResponseDialog> {
  bool _isLoading = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    await widget.onRespond('accept');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reject() async {
    // Show reason input dialog
    final reason = await _showRejectReasonDialog();
    if (reason == null) return; // User cancelled

    setState(() {
      _isLoading = true;
    });

    final response = await widget.onRespond('reject', reason: reason);
    if (mounted) {
      Navigator.of(context).pop(response);
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(IconMap.warningRounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            const Text('Alasan Penolakan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mohon isi alasan penolakan shift:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Sakit, Urusan keluarga, dll',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 255,
            ),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.ghost,
            child: const Text('Batal'),
          ),
          FButton(
            onPress: () {
              final reason = _reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi alasan penolakan')),
                );
                return;
              }
              Navigator.pop(context, reason);
            },
            variant: FButtonVariant.destructive,
            child: const Text('Tolak Shift'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(IconMap.schedule, color: theme.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('Konfirmasi Jadwal Shift')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sky50,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(IconMap.calendarToday, 'Tanggal', widget.shift.date),
                const SizedBox(height: AppSpacing.sm),
                if (widget.shift.areaName != null)
                  _buildInfoRow(IconMap.locationOn, 'Area', widget.shift.areaName!),
                const SizedBox(height: AppSpacing.sm),
                if (widget.shift.posName != null)
                  _buildInfoRow(IconMap.place, 'POS', widget.shift.posName!),
                const SizedBox(height: AppSpacing.sm),
                if (widget.shift.shiftName != null)
                  _buildInfoRow(IconMap.accessTime, 'Shift', widget.shift.shiftName!),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(IconMap.schedule, 'Jam Mulai', widget.shift.shiftStartTime),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.amber50,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.amber200),
            ),
            child: Row(
              children: [
                Icon(IconMap.infoOutline, color: AppColors.amber600, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Jika ditolak, sistem akan mencari backup secara otomatis.',
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
        SecondaryButton(
          label: 'TOLAK',
          onPressed: _isLoading ? null : _reject,
          isDanger: true,
          isLoading: _isLoading,
        ),
        // Accept button
        PrimaryButton(
          label: 'TERIMA',
          onPressed: _isLoading ? null : _accept,
          isLoading: _isLoading,
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

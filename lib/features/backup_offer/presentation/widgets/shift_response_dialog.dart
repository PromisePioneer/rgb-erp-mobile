import 'package:flutter/material.dart';
import '../../../../core/core.dart';
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: AppSpacing.sm),
            Text('Alasan Penolakan'),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = _reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi alasan penolakan')),
                );
                return;
              }
              Navigator.pop(context, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak Shift'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.schedule, color: AppColors.primary),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Konfirmasi Jadwal Shift')),
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
                _buildInfoRow(Icons.calendar_today, 'Tanggal', widget.shift.date),
                const SizedBox(height: AppSpacing.sm),
                if (widget.shift.areaName != null)
                  _buildInfoRow(Icons.location_on, 'Area', widget.shift.areaName!),
                const SizedBox(height: AppSpacing.sm),
                if (widget.shift.posName != null)
                  _buildInfoRow(Icons.place, 'POS', widget.shift.posName!),
                const SizedBox(height: AppSpacing.sm),
                if (widget.shift.shiftName != null)
                  _buildInfoRow(Icons.access_time, 'Shift', widget.shift.shiftName!),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(Icons.schedule, 'Jam Mulai', widget.shift.shiftStartTime),
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
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.amber600, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
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
        OutlinedButton(
          onPressed: _isLoading ? null : _reject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
          child: const Text('TOLAK'),
        ),
        // Accept button
        ElevatedButton(
          onPressed: _isLoading ? null : _accept,
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

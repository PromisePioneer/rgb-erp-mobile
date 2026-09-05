import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
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
      builder: (context) {
        final theme = context.theme;
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
                      Icon(IconMap.warningRounded, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Alasan Penolakan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    'Mohon isi alasan penolakan shift:',
                    style: TextStyle(color: theme.colors.mutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Text field
                  FTextField(
                    control: FTextFieldControl.managed(controller: _reasonController),
                    size: FTextFieldSizeVariant.md,
                    hint: 'Contoh: Sakit, Urusan keluarga, dll',
                    maxLines: 3,
                    maxLength: 255,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          onPress: () => Navigator.pop(context),
                          variant: FButtonVariant.ghost,
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FButton(
                          onPress: () {
                            final reason = _reasonController.text.trim();
                            if (reason.isEmpty) {
                              return;
                            }
                            _reasonController.clear();
                            Navigator.pop(context, reason);
                          },
                          variant: FButtonVariant.destructive,
                          child: const Text('Tolak Shift'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

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
                  Icon(IconMap.schedule, color: theme.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Konfirmasi Jadwal Shift',
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
                        'Jika ditolak, sistem akan mencari backup secara otomatis.',
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
                      onPressed: _isLoading ? null : _reject,
                      isDanger: true,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'TERIMA',
                      onPressed: _isLoading ? null : _accept,
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

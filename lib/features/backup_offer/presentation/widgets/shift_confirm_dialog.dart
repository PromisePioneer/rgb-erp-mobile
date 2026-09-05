import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';

/// Simple confirm dialog for shift reminder
class ShiftConfirmDialog extends StatefulWidget {
  final String title;
  final String areaName;
  final String shiftName;
  final String shiftTime;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ShiftConfirmDialog({
    super.key,
    required this.title,
    required this.areaName,
    required this.shiftName,
    required this.shiftTime,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<ShiftConfirmDialog> createState() => _ShiftConfirmDialogState();
}

class _ShiftConfirmDialogState extends State<ShiftConfirmDialog> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconMap.schedule,
                size: 48,
                color: theme.colors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Column(
                  children: [
                    _buildRow(IconMap.locationOn, 'Area', widget.areaName),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRow(IconMap.accessTime, 'Shift', widget.shiftName),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRow(IconMap.schedule, 'Jam', widget.shiftTime),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
                        'Jika ditolak, sistem akan cari backup.',
                        style: TextStyle(fontSize: 12, color: AppColors.amber500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'TOLAK',
                      onPressed: _isLoading ? null : () {
                        widget.onReject();
                      },
                      isDanger: true,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'TERIMA',
                      onPressed: _isLoading ? null : () {
                        widget.onAccept();
                      },
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

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

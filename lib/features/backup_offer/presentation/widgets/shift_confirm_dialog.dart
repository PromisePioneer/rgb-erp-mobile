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
    final theme = FTheme.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconMap.schedule,
                size: 48,
                color: theme.colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildRow(IconMap.locationOn, 'Area', widget.areaName),
                    const SizedBox(height: 8),
                    _buildRow(IconMap.accessTime, 'Shift', widget.shiftName),
                    const SizedBox(height: 8),
                    _buildRow(IconMap.schedule, 'Jam', widget.shiftTime),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber200),
                ),
                child: Row(
                  children: [
                    Icon(IconMap.infoOutline, color: AppColors.amber600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika ditolak, sistem akan cari backup.',
                        style: TextStyle(fontSize: 12, color: AppColors.amber600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                  const SizedBox(width: 16),
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
        const SizedBox(width: 8),
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

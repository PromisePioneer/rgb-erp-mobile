import 'package:flutter/material.dart';
import '../core/core.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                    _buildRow(Icons.location_on, 'Area', widget.areaName),
                    const SizedBox(height: 8),
                    _buildRow(Icons.access_time, 'Shift', widget.shiftName),
                    const SizedBox(height: 8),
                    _buildRow(Icons.schedule, 'Jam', widget.shiftTime),
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
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.amber600, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika ditolak, sistem akan cari backup.',
                        style: TextStyle(fontSize: 12, color: AppColors.amber800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        widget.onReject();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text('TOLAK'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        widget.onAccept();
                      },
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
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('TERIMA'),
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

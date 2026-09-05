import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core.dart';
import '../../features/backup_offer/data/repositories/backup_offer_repository.dart';
import '../../features/backup_offer/data/repositories/shift_response_repository.dart';
import '../../features/backup_offer/domain/models/backup_offer.dart';
import '../../features/backup_offer/presentation/providers/backup_offer_provider.dart';
import '../../features/backup_offer/presentation/providers/shift_response_provider.dart';

/// Simple notification dialog overlay manager
class NotificationDialogManager {
  static final NotificationDialogManager _instance = NotificationDialogManager._internal();
  factory NotificationDialogManager() => _instance;
  NotificationDialogManager._internal();

  /// Show shift response dialog (Accept/Tolak)
  Future<void> showShiftResponseDialog({
    required BuildContext context,
    required String scheduleId,
    required String areaName,
    required String shiftName,
    required String shiftTime,
  }) async {
    final repository = ShiftResponseRepository(ApiClientFactory(storage: StorageService()).create());
    final notifier = ShiftResponseNotifier(repository);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ShiftConfirmDialogContent(
        scheduleId: scheduleId,
        areaName: areaName,
        shiftName: shiftName,
        shiftTime: shiftTime,
        onAccept: () async {
          await notifier.acceptShift(scheduleId);
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onReject: () async {
          await notifier.rejectShift(scheduleId);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  /// Show backup offer dialog (Accept/Tolak)
  Future<void> showBackupOfferDialog({
    required BuildContext context,
    required String offerId,
  }) async {
    final repository = BackupOfferRepository(ApiClientFactory(storage: StorageService()).create());
    final notifier = BackupOfferNotifier(repository);

    // Load offer first
    await notifier.loadPendingOffers();
    final offer = notifier.state.offers.where((o) => o.id == offerId).firstOrNull;

    if (offer == null) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BackupOfferDialogContent(
        offer: offer,
        onAccept: () async {
          await notifier.acceptOffer(offerId);
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onReject: () async {
          await notifier.rejectOffer(offerId);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ShiftConfirmDialogContent extends StatefulWidget {
  final String scheduleId;
  final String areaName;
  final String shiftName;
  final String shiftTime;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ShiftConfirmDialogContent({
    required this.scheduleId,
    required this.areaName,
    required this.shiftName,
    required this.shiftTime,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_ShiftConfirmDialogContent> createState() => _ShiftConfirmDialogContentState();
}

class _ShiftConfirmDialogContentState extends State<_ShiftConfirmDialogContent> {
  bool _isLoading = false;
  String _action = '';

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.schedule, color: theme.colors.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konfirmasi Jadwal Shift',
                      style: theme.typography.display.lg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildRow(theme, Icons.location_on, 'Area', widget.areaName),
                    const SizedBox(height: 8),
                    _buildRow(theme, Icons.access_time, 'Shift', widget.shiftName),
                    const SizedBox(height: 8),
                    _buildRow(theme, Icons.schedule, 'Jam', widget.shiftTime),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.amber600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika ditolak, sistem akan cari backup otomatis.',
                        style: theme.typography.body.md.copyWith(color: AppColors.amber600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      onPress: _isLoading ? null : () => _handleReject(),
                      variant: FButtonVariant.outline,
                      child: const Text('TOLAK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: _isLoading ? null : _handleAccept,
                      variant: FButtonVariant.primary,
                      child: _isLoading && _action == 'accept'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
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

  Widget _buildRow(FThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.typography.body.md.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
      _action = 'accept';
    });
    widget.onAccept();
  }

  Future<void> _handleReject() async {
    setState(() {
      _isLoading = true;
      _action = 'reject';
    });
    widget.onReject();
  }
}

class _BackupOfferDialogContent extends StatefulWidget {
  final BackupOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BackupOfferDialogContent({
    required this.offer,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_BackupOfferDialogContent> createState() => _BackupOfferDialogContentState();
}

class _BackupOfferDialogContentState extends State<_BackupOfferDialogContent> {
  bool _isLoading = false;
  String _action = '';
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.offer.remainingSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: theme.colors.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tawaran Backup Jaga',
                      style: theme.typography.display.lg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 300 ? AppColors.dangerBg : AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 20,
                      color: _remainingSeconds < 300 ? AppColors.danger : theme.colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _remainingSeconds <= 0
                          ? 'Waktu Habis'
                          : 'Berakhir: ${_formatTime(_remainingSeconds)}',
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds < 300 ? AppColors.danger : theme.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildRow(theme, Icons.calendar_today, 'Tanggal', widget.offer.date),
                    if (widget.offer.areaName != null) ...[
                      const SizedBox(height: 8),
                      _buildRow(theme, Icons.location_on, 'Area', widget.offer.areaName!),
                    ],
                    if (widget.offer.shiftName != null) ...[
                      const SizedBox(height: 8),
                      _buildRow(theme, Icons.access_time, 'Shift', widget.offer.shiftName!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.amber600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Menjadi backup berarti menggantikan petugas original.',
                        style: theme.typography.body.md.copyWith(color: AppColors.amber600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      onPress: _isLoading || _remainingSeconds <= 0 ? null : () => _handleReject(),
                      variant: FButtonVariant.outline,
                      child: const Text('TOLAK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: _isLoading || _remainingSeconds <= 0 ? null : _handleAccept,
                      variant: FButtonVariant.primary,
                      child: _isLoading && _action == 'accept'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
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

  Widget _buildRow(FThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.typography.body.md.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
      _action = 'accept';
    });
    widget.onAccept();
  }

  Future<void> _handleReject() async {
    setState(() {
      _isLoading = true;
      _action = 'reject';
    });
    widget.onReject();
  }
}

/// Global instance
final notificationDialogManager = NotificationDialogManager();

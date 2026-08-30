import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/domain.dart';
import '../providers/attendance_provider.dart';

/// Attendance home screen
class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  bool _isProcessingAttendance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceNotifier>().loadTodayAttendance();
    });
  }

  Future<void> _handleAttendance({String? earlyLeaveNotes}) async {
    // Prevent double invocation
    if (_isProcessingAttendance) {
      return;
    }
    _isProcessingAttendance = true;

    final notifier = context.read<AttendanceNotifier>();

    try {
      // 1. Get location first
      final location = await notifier.getCurrentLocation();
      if (location == null) {
        if (notifier.state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notifier.state.error!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // 2. Navigate to camera capture
      final photoPath = await context.push<String>('/attendance/capture');
      if (photoPath == null || !mounted) {
        return;
      }

      // Generate capturedAt timestamp once for idempotency
      final capturedAt = DateTime.now().toIso8601String();

      // 3. Face verify
      final type = notifier.state.hasCheckedIn ? 'check_out' : 'check_in';
      final verifyResult = await notifier.faceVerify(
        photoPath: photoPath,
        capturedAt: capturedAt,
        lat: location.latitude,
        lng: location.longitude,
        type: type,
      );

      if (verifyResult == null) {
        if (!mounted) return;
        _handleError(notifier.state.error!);
        return;
      }

      if (!verifyResult.match) {
        if (mounted) {
          _handleError(verifyResult.message);
        }
        return;
      }

      // 4. If job_id exists, poll for status
      String? jobUuid = verifyResult.jobId;
      if (jobUuid != null) {
        final status = await notifier.pollJobStatus(jobUuid);
        if (status == null || status.isFailed) {
          if (mounted) {
            _handleError(status?.message ?? 'Verifikasi gagal');
          }
          return;
        }
      }

      // 5. Record attendance (same capturedAt for idempotency)
      final record = await notifier.recordAttendance(
        photoPath: photoPath,
        capturedAt: capturedAt,
        lat: location.latitude,
        lng: location.longitude,
        faceMatchScore: verifyResult.score,
        earlyLeaveNotes: earlyLeaveNotes,
      );

      if (record != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${record.isCheckIn ? 'Absen Masuk' : 'Absen Pulang'} berhasil'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (notifier.state.error != null && mounted) {
        _handleError(notifier.state.error!);
      }
    } finally {
      _isProcessingAttendance = false;
    }
  }

  void _handleError(String error) {
    // Check if error is about face not enrolled
    if (error.contains('Belum terdaftar wajah') ||
        error.contains('belum terdaftar') ||
        (error.toLowerCase().contains('face') && error.toLowerCase().contains('not'))) {
      _showFaceEnrollmentRequiredDialog();
    }
    // Check if error is about geofence/location distance - show as AlertDialog
    else if (error.contains('jarak') ||
        error.contains('lokasi') ||
        error.contains('Dekatkan lokasi')) {
      _showGeofenceErrorDialog(error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showGeofenceErrorDialog(String error) {
    final theme = FTheme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Row(
          children: [
            Icon(IconMap.locationOff, color: theme.colors.destructive),
            const SizedBox(width: AppSpacing.sm),
            const Text('Lokasi Jauh'),
          ],
        ),
        content: Text(error),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.primary,
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFaceEnrollmentRequiredDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: const Text('Wajah Belum Terdaftar'),
        content: const Text(
          'Anda perlu mendaftarkan wajah terlebih dahulu untuk dapat melakukan absensi dengan verifikasi wajah.',
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context, false),
            variant: FButtonVariant.ghost,
            child: const Text('Nanti Saja'),
          ),
          FButton(
            onPress: () => Navigator.pop(context, true),
            variant: FButtonVariant.primary,
            child: const Text('Daftarkan Wajah'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      context.push('/face-enrollment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Absensi'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Consumer<AttendanceNotifier>(
          builder: (context, notifier, child) {
            // Show error if there's an error and no data
            if (notifier.state.error != null && notifier.state.todayData == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconMap.errorOutline, size: 64, color: FTheme.of(context).colors.destructive),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        notifier.state.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FTheme.of(context).colors.mutedForeground),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: 'Coba Lagi',
                        onPressed: () => notifier.loadTodayAttendance(),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (notifier.state.isLoading && notifier.state.todayData == null) {
              return const Center(child: LoadingIndicator(size: 32));
            }

            final data = notifier.state.todayData;
            final isLoading = notifier.state.isVerifying || notifier.state.isRecording;

            return RefreshIndicator(
              onRefresh: () => notifier.loadTodayAttendance(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status card
                    _buildStatusCard(notifier),
                    const SizedBox(height: AppSpacing.lg),

                    // Schedule info
                    if (data?.hasSchedule == true) ...[
                      _buildScheduleCard(data),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Attendance button
                    _buildAttendanceButton(notifier, isLoading),

                    const SizedBox(height: AppSpacing.lg),

                    // Records list
                    if (data?.records.isNotEmpty == true) ...[
                      _buildRecordsList(data!.records),
                    ],

                    // Error message
                    if (notifier.state.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: FTheme.of(context).colors.destructive,
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Row(
                          children: [
                            Icon(IconMap.errorOutline, color: FTheme.of(context).colors.destructiveForeground),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                notifier.state.error!,
                                style: TextStyle(color: FTheme.of(context).colors.destructiveForeground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(AttendanceNotifier notifier) {
    final theme = FTheme.of(context);
    final data = notifier.state.todayData;
    final statusText = data?.statusText ?? 'Memuat...';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.primary,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.schedule, color: theme.colors.primaryForeground, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Hari Ini',
                      style: TextStyle(color: theme.colors.primaryForeground.withAlpha(179)),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: theme.colors.primaryForeground,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data?.hasCheckedIn == true && data?.checkInTime != null) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: theme.colors.primaryForeground.withAlpha(61)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeColumn(
                  'Masuk',
                  _formatTime(data!.checkInTime!),
                  IconMap.login,
                ),
                if (data.checkOutTime != null)
                  _buildTimeColumn(
                    'Pulang',
                    _formatTime(data.checkOutTime!),
                    IconMap.logout,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon) {
    final theme = FTheme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colors.primaryForeground.withAlpha(179), size: 16),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: theme.colors.primaryForeground.withAlpha(138), fontSize: 12),
            ),
            Text(
              time,
              style: TextStyle(
                color: theme.colors.primaryForeground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleCard(AttendanceData? data) {
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(IconMap.work, color: theme.colors.secondaryForeground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data?.pos?.name ?? data?.client?.name ?? 'Lokasi Kerja',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    if (data?.shift != null)
                      Text(
                        'Shift: ${data!.shift!.name} (${data.shift!.startTime} - ${data.shift!.endTime})',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (data?.client != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(IconMap.locationOn, size: 16, color: theme.colors.mutedForeground),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Radius: ${data!.client!.radiusMeters}m dari lokasi',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(AttendanceNotifier notifier, bool isLoading) {
    final theme = FTheme.of(context);
    final canAttend = notifier.state.canAttend;
    final nextAction = notifier.state.nextAction;
    final isDone = nextAction == 'done';
    final willCheckOutEarly = notifier.state.todayData?.willCheckOutEarly ?? false;

    if (!canAttend) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          borderRadius: AppRadius.radiusLg,
        ),
        child: Row(
          children: [
            Icon(IconMap.infoOutline, color: theme.colors.secondaryForeground),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                notifier.state.todayData?.message ?? 'Tidak ada jadwal kerja hari ini',
                style: TextStyle(color: theme.colors.secondaryForeground),
              ),
            ),
          ],
        ),
      );
    }

    // Show warning if user is about to check out early
    if (willCheckOutEarly && nextAction == 'check_out') {
      final theme = FTheme.of(context);
      final minutesToEnd = notifier.state.todayData?.minutesToShiftEnd ?? 0;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          borderRadius: AppRadius.radiusLg,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(IconMap.warning, color: theme.colors.secondaryForeground),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Pulang lebih awal dari jadwal ($minutesToEnd menit sebelum waktu pulang)',
                    style: TextStyle(color: theme.colors.secondaryForeground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Absen Pulang',
              icon: IconMap.fingerprint,
              isLoading: isLoading || _isProcessingAttendance,
              onPressed: _isProcessingAttendance
                  ? null
                  : () => _handleCheckOutWithEarlyLeaveWarning(notifier, minutesToEnd),
            ),
          ],
        ),
      );
    }

    return PrimaryButton(
      label: isDone
          ? 'Selesai'
          : (nextAction == 'check_in' ? 'Absen Masuk' : 'Absen Pulang'),
      icon: isDone ? IconMap.checkCircle : IconMap.fingerprint,
      isLoading: isLoading || _isProcessingAttendance,
      onPressed: isDone || !canAttend || _isProcessingAttendance
          ? null
          : () => _handleAttendance(),
    );
  }

  /// Handle check-out with early leave warning dialog
  Future<void> _handleCheckOutWithEarlyLeaveWarning(
    AttendanceNotifier notifier,
    int minutesEarly,
  ) async {
    final result = await showDialog<EarlyLeaveDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EarlyLeaveDialog(minutesEarly: minutesEarly),
    );

    if (result == null) return;

    // If user chose to wait, do nothing (they can try again later)
    if (result.action == EarlyLeaveAction.wait) return;

    // User chose to continue with early leave - proceed with notes
    if (mounted) {
      _handleAttendance(earlyLeaveNotes: result.notes);
    }
  }

  Widget _buildRecordsList(List<dynamic> records) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...records.map((record) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colors.card,
                borderRadius: AppRadius.radiusMd,
                boxShadow: AppShadows.cardSubtle,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: record.isCheckIn
                          ? theme.colors.primary.withAlpha(25)
                          : theme.colors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      record.isCheckIn ? IconMap.login : IconMap.logout,
                      color: record.isCheckIn
                          ? theme.colors.primary
                          : theme.colors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colors.foreground,
                          ),
                        ),
                        if (record.recordedAt != null)
                          Text(
                            _formatDateTime(record.recordedAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(IconMap.checkCircle, color: theme.colors.primary, size: 20),
                ],
              ),
            )),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

/// Result of early leave dialog
class EarlyLeaveDialogResult {
  final EarlyLeaveAction action;
  final String? notes;

  EarlyLeaveDialogResult({required this.action, this.notes});
}

/// Action chosen in early leave dialog
enum EarlyLeaveAction { continue_, wait }

/// Dialog to show when user tries to check out early
class EarlyLeaveDialog extends StatefulWidget {
  final int minutesEarly;

  const EarlyLeaveDialog({super.key, required this.minutesEarly});

  @override
  State<EarlyLeaveDialog> createState() => _EarlyLeaveDialogState();
}

class _EarlyLeaveDialogState extends State<EarlyLeaveDialog> {
  final _notesController = TextEditingController();
  String? _notesError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: Row(
        children: [
          Icon(IconMap.warning, color: theme.colors.secondary),
          const SizedBox(width: AppSpacing.sm),
          const Text('Pulang Lebih Awal'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan pulang ${widget.minutesEarly} menit lebih awal dari jadwal.',
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Mohon isi alasan kepulangan lebih awal:'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _notesController,
              hint: 'Contoh: Anak sakit,Urusan mendesak,...',
              maxLines: 3,
              maxLength: 500,
              errorText: _notesError,
              onChanged: (_) {
                if (_notesError != null) {
                  setState(() => _notesError = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Catatan: Anda bisa menunggu hingga waktu pulang untuk menghindari pencatatan ini.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        FButton(
          onPress: () => Navigator.pop(
            context,
            EarlyLeaveDialogResult(action: EarlyLeaveAction.wait),
          ),
          variant: FButtonVariant.ghost,
          child: const Text('Tunggu Sampai Jadwal'),
        ),
        FButton(
          onPress: _onContinue,
          variant: FButtonVariant.primary,
          child: const Text('Tetap Pulang'),
        ),
      ],
    );
  }

  void _onContinue() {
    final notes = _notesController.text.trim();

    if (notes.isEmpty) {
      setState(() => _notesError = 'Harap isi alasan kepulangan lebih awal');
      return;
    }

    Navigator.pop(
      context,
      EarlyLeaveDialogResult(
        action: EarlyLeaveAction.continue_,
        notes: notes,
      ),
    );
  }
}

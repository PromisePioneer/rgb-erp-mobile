import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
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
      print('HOME: Already processing, ignoring duplicate call');
      return;
    }
    _isProcessingAttendance = true;

    print('HOME: Starting _handleAttendance');
    final notifier = context.read<AttendanceNotifier>();

    try {
      // 1. Get location first
      print('HOME: Step 1 - Getting location...');
      final location = await notifier.getCurrentLocation();
      if (location == null) {
        print('HOME: Location null, showing error');
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
      print('HOME: Location obtained - lat: ${location.latitude}, lng: ${location.longitude}');

    // 2. Navigate to camera capture
    print('HOME: Step 2 - Navigating to camera capture...');
    final photoPath = await context.push<String>('/attendance/capture');
    print('HOME: Camera returned photoPath: $photoPath');
    if (photoPath == null || !mounted) {
      print('HOME: Returning early - photoPath null or not mounted');
      return;
    }

    // Generate capturedAt timestamp once for idempotency
    final capturedAt = DateTime.now().toIso8601String();

    // 3. Face verify
    print('HOME: Step 3 - Face verify...');
    final type = notifier.state.hasCheckedIn ? 'check_out' : 'check_in';
    final verifyResult = await notifier.faceVerify(
      photoPath: photoPath,
      capturedAt: capturedAt,
      lat: location.latitude,
      lng: location.longitude,
      type: type,
    );
    print('HOME: faceVerify result: ${verifyResult?.match}');

    if (verifyResult == null) {
      print('HOME: verifyResult is null');
      if (!mounted) return;
      _handleError(notifier.state.error!);
      return;
    }

    if (!verifyResult.match) {
      print('HOME: Face match failed - ${verifyResult.message}');
      if (mounted) {
        _handleError(verifyResult.message);
      }
      return;
    }

    // 4. If job_id exists, poll for status
    String? jobUuid = verifyResult.jobId;
    if (jobUuid != null) {
      print('HOME: Step 4 - Polling job status: $jobUuid');
      final status = await notifier.pollJobStatus(jobUuid);
      if (status == null || status.isFailed) {
        print('HOME: Job status failed');
        if (mounted) {
          _handleError(status?.message ?? 'Verifikasi gagal');
        }
        return;
      }
    }

    // 5. Record attendance (same capturedAt for idempotency)
    print('HOME: Step 5 - Recording attendance...');
    final record = await notifier.recordAttendance(
      photoPath: photoPath,
      capturedAt: capturedAt,
      lat: location.latitude,
      lng: location.longitude,
      faceMatchScore: verifyResult.score,
      earlyLeaveNotes: earlyLeaveNotes,
    );
    print('HOME: record result: ${record?.id}');

    if (record != null && mounted) {
      print('HOME: Attendance recorded successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${record.isCheckIn ? 'Absen Masuk' : 'Absen Pulang'} berhasil'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (notifier.state.error != null && mounted) {
      print('HOME: Recording failed with error');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppColors.danger),
            SizedBox(width: AppSpacing.sm),
            Text('Lokasi Jauh'),
          ],
        ),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
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
        title: const Text('Wajah Belum Terdaftar'),
        content: const Text(
          'Anda perlu mendaftarkan wajah terlebih dahulu untuk dapat melakukan absensi dengan verifikasi wajah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
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
                      const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        notifier.state.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => notifier.loadTodayAttendance(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (notifier.state.isLoading && notifier.state.todayData == null) {
              return const Center(child: CircularProgressIndicator());
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
                          color: AppColors.dangerBg,
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                notifier.state.error!,
                                style: const TextStyle(color: AppColors.danger),
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
    final data = notifier.state.todayData;
    final statusText = data?.statusText ?? 'Memuat...';

    Color statusColor;
    IconData statusIcon;

    if (data?.hasSchedule == false) {
      statusColor = AppColors.warning;
      statusIcon = Icons.event_busy;
    } else if (data?.hasCheckedOut == true) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (data?.hasCheckedIn == true) {
      statusColor = AppColors.primary;
      statusIcon = Icons.login;
    } else {
      statusColor = AppColors.amber600;
      statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withAlpha(200)],
        ),
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: Colors.white, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Hari Ini',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
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
            const Divider(color: Colors.white24),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeColumn(
                  'Masuk',
                  _formatTime(data!.checkInTime!),
                  Icons.login,
                ),
                if (data.checkOutTime != null)
                  _buildTimeColumn(
                    'Pulang',
                    _formatTime(data.checkOutTime!),
                    Icons.logout,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.sky100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work, color: AppColors.sky600),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data?.pos?.name ?? data?.client?.name ?? 'Lokasi Kerja',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (data?.shift != null)
                      Text(
                        'Shift: ${data!.shift!.name} (${data.shift!.startTime} - ${data.shift!.endTime})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Radius: ${data!.client!.radiusMeters}m dari lokasi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
    final canAttend = notifier.state.canAttend;
    final nextAction = notifier.state.nextAction;
    final isDone = nextAction == 'done';
    final willCheckOutEarly = notifier.state.todayData?.willCheckOutEarly ?? false;

    if (!canAttend) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.amber200),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.amber600),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                notifier.state.todayData?.message ?? 'Tidak ada jadwal kerja hari ini',
                style: TextStyle(color: AppColors.amber600),
              ),
            ),
          ],
        ),
      );
    }

    // Show warning if user is about to check out early
    if (willCheckOutEarly && nextAction == 'check_out') {
      final minutesToEnd = notifier.state.todayData?.minutesToShiftEnd ?? 0;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.amber600),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amber600),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Pulang lebih awal dari jadwal ($minutesToEnd menit sebelum waktu pulang)',
                    style: const TextStyle(color: AppColors.amber600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Absen Pulang',
              icon: Icons.fingerprint,
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
      icon: isDone ? Icons.check_circle : Icons.fingerprint,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...records.map((record) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
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
                          ? AppColors.emerald100
                          : AppColors.rose100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      record.isCheckIn ? Icons.login : Icons.logout,
                      color: record.isCheckIn
                          ? AppColors.emerald600
                          : AppColors.rose600,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (record.recordedAt != null)
                          Text(
                            _formatDateTime(record.recordedAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.amber600),
          SizedBox(width: AppSpacing.sm),
          Text('Pulang Lebih Awal'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan pulang ${widget.minutesEarly} menit lebih awal dari jadwal.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Mohon isi alasan kepulangan lebih awal:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
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
            const Text(
              'Catatan: Anda bisa menunggu hingga waktu pulang untuk menghindari pencatatan ini.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            EarlyLeaveDialogResult(action: EarlyLeaveAction.wait),
          ),
          child: const Text('Tunggu Sampai Jadwal'),
        ),
        ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../domain/domain.dart';
import '../providers/patrol_provider.dart';
import '../widgets/checkpoint_path.dart';

/// Patrol home screen - shows today's patrol status and scan button
class PatrolHomeScreen extends StatefulWidget {
  const PatrolHomeScreen({super.key});

  @override
  State<PatrolHomeScreen> createState() => _PatrolHomeScreenState();
}

class _PatrolHomeScreenState extends State<PatrolHomeScreen> {
  @override
  void initState() {
    super.initState();
    final notifier = context.read<PatrolNotifier>();

    // Set navigation callback for alarm
    notifier.navigateToAlarmScreen = (message) {
      context.push(
        '/patrol/alarm?message=${Uri.encodeComponent(message ?? '')}',
      );
    };

    notifier.loadTodayStatus();
  }

  Future<void> _handleScan() async {
    final notifier = context.read<PatrolNotifier>();

    // Open scanner
    final qrCode = await context.push<String>('/patrol/scan');
    if (qrCode == null || !mounted) return;

    // Perform scan (loadTodayStatus is already called inside performScan on success)
    final result = await notifier.performScan(qrCode);
    if (result == null || !mounted) return;

    // Handle result
    if (result.success) {
      if (result.valid) {
        // Success with valid location
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Checkpoint ${result.checkpoint?.name ?? ''} berhasil discan!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // Success but location warning
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.validation?.locationMessage ??
                  'Scan berhasil - lokasi di luar radius',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Status sudah di-refresh oleh performScan()
    } else {
      // Error
      _handleError(result);
    }
  }

  void _handleError(PatrolScanResult result) {
    final code = result.errorCode;
    final message = result.errorMessage ?? 'Scan gagal';

    if (code == 'MOCK_LOCATION') {
      _showMockLocationDialog(message);
    } else if (code == 'INVALID_TOTP') {
      _showTOTPErrorDialog(message);
    } else if (code == 'TIME_DRIFT') {
      _showTimeDriftDialog(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showMockLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.danger),
            SizedBox(width: 8),
            Text('GPS Palsu Terdeteksi'),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'GPS palsu (fake GPS) terdeteksi. Matikan aplikasi fake GPS untuk melanjutkan patroli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTOTPErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Kode OTP Salah'),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'Kode OTP tidak valid atau sudah kadaluarsa. Pastikan waktu perangkat Anda sudah sinkron.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTimeDriftDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Waktu Tidak Sinkron'),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'Waktu perangkat Anda tidak sinkron dengan server. Mohon perbarui waktu otomatis di pengaturan perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Patroli'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [
            // Countdown badge in app bar
            Consumer<PatrolNotifier>(
              builder: (context, notifier, child) {
                final countdownText = notifier.state.roundCountdownText;
                if (countdownText == null || !notifier.state.hasSchedule) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: _buildCountdownBadge(
                    countdownText,
                    notifier.state.isRoundOverdue,
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<PatrolNotifier>(
          builder: (context, notifier, child) {
            if (notifier.state.error != null &&
                notifier.state.todayStatus == null) {
              return _buildError(notifier);
            }

            if (notifier.state.isLoading &&
                notifier.state.todayStatus == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final status = notifier.state.todayStatus;

            if (status == null || !status.hasSchedule) {
              return _buildNoSchedule();
            }

            return Column(
              children: [
                Expanded(
                  child: _buildContent(notifier, status),
                ),
                _buildScanButtonFixed(notifier),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(String text, bool isOverdue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.danger : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.timer,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PatrolNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => notifier.loadTodayStatus(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSchedule() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy, size: 64, color: AppColors.slate400),
            SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ada jadwal patroli hari ini',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PatrolNotifier notifier, PatrolTodayStatus status) {
    return RefreshIndicator(
      onRefresh: () => notifier.loadTodayStatus(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          120, // Extra padding at bottom for fixed button
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Countdown card (for when not overdue)
            if (!notifier.state.isRoundOverdue &&
                notifier.state.roundCountdownText != null)
              _buildCountdownCard(notifier),

            // Schedule card
            _buildScheduleCard(status),
            const SizedBox(height: AppSpacing.lg),

            // Progress info
            _buildProgressInfo(status),
            const SizedBox(height: AppSpacing.lg),

            // Checkpoint path visualization
            _buildCheckpointPath(notifier, status),
            const SizedBox(height: AppSpacing.lg),

            // Session history
            if (status.sessions.isNotEmpty) ...[_buildSessionHistory(status)],
          ],
        ),
      ),
    );
  }

  Widget _buildScanButtonFixed(PatrolNotifier notifier) {
    final isLoading =
        notifier.state.isScanning || notifier.state.isCountingDown;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      child: PrimaryButton(
        label: isLoading
            ? 'Memproses...'
            : 'Scan Checkpoint #${notifier.state.nextExpectedSequence}',
        icon: Icons.qr_code_scanner,
        isLoading: isLoading,
        onPressed: isLoading ? null : _handleScan,
      ),
    );
  }

  Widget _buildCountdownCard(PatrolNotifier notifier) {
    final progress = notifier.state.todayStatus?.currentProgress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withAlpha(204)],
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checkpoint Berikutnya',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notifier.state.roundCountdownText ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (progress.currentRoundDueAt != null)
                Column(
                  children: [
                    Text(
                      'Jam',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(progress.currentRoundDueAt!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          _buildCountdownProgressBar(progress),
        ],
      ),
    );
  }

  Widget _buildCountdownProgressBar(CurrentProgressInfo progress) {
    // Calculate progress based on interval and time elapsed
    final intervalMinutes = progress.intervalMinutes;
    final dueAt = progress.currentRoundDueAt;

    if (dueAt == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final startTime = dueAt.subtract(Duration(minutes: intervalMinutes));
    final totalDuration = dueAt.difference(startTime);
    final elapsed = now.difference(startTime);

    double progressValue = elapsed.inSeconds / totalDuration.inSeconds;
    progressValue = progressValue.clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.white.withAlpha(51),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mulai: ${_formatTime(startTime)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(179),
              ),
            ),
            Text(
              'Selesai: ${_formatTime(dueAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildScheduleCard(PatrolTodayStatus status) {
    final schedule = status.schedule;
    if (schedule == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.teal100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_city, color: AppColors.teal600),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.projectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.shiftName} (${schedule.shiftStartTime} - ${schedule.shiftEndTime})',
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
    );
  }

  Widget _buildProgressInfo(PatrolTodayStatus status) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Ronde Selesai',
            '${status.stats?.completedRounds ?? 0}',
            Icons.check_circle,
            AppColors.teal500,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Sedang Berlangsung',
            '${status.stats?.inProgressRounds ?? 0}',
            Icons.play_circle,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Total Titik',
            '${status.stats?.totalCheckpoints ?? 0}',
            Icons.place,
            AppColors.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointPath(
    PatrolNotifier notifier,
    PatrolTodayStatus status,
  ) {
    final total = status.stats?.totalCheckpoints ?? 0;
    final nextSeq = status.nextExpectedSequence;

    // Build node list
    final nodes = List.generate(total, (index) {
      final seq = index + 1;
      CheckpointNodeStatus nodeStatus;
      String name;

      if (seq < nextSeq) {
        nodeStatus = CheckpointNodeStatus.completed;
        name = 'Titik $seq';
      } else if (seq == nextSeq) {
        nodeStatus = CheckpointNodeStatus.active;
        name = 'Titik $seq';
      } else {
        nodeStatus = CheckpointNodeStatus.locked;
        name = 'Titik $seq';
      }

      return CheckpointNode(sequence: seq, status: nodeStatus, name: name);
    });

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Peta Checkpoint',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              if (notifier.state.isCountingDown)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.amber600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${notifier.state.countdownSeconds}s',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.amber600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: CheckpointPath(
              nodes: nodes,
              onNodeTap: (node) {
                if (node.status == CheckpointNodeStatus.locked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selesaikan checkpoint sebelumnya dulu'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory(PatrolTodayStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Ronde Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...status.sessions.map((session) => _buildSessionItem(session)),
      ],
    );
  }

  Widget _buildSessionItem(PatrolSession session) {
    Color statusColor;
    IconData statusIcon;

    switch (session.status) {
      case 'in_progress':
        statusColor = AppColors.primary;
        statusIcon = Icons.play_circle;
        break;
      case 'completed':
        statusColor = AppColors.teal500;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppColors.slate400;
        statusIcon = Icons.cancel;
    }

    String timeText = '-';
    if (session.startedAt != null) {
      timeText =
          '${session.startedAt!.hour.toString().padLeft(2, '0')}:${session.startedAt!.minute.toString().padLeft(2, '0')}';
      if (session.completedAt != null) {
        timeText +=
            ' - ${session.completedAt!.hour.toString().padLeft(2, '0')}:${session.completedAt!.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
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
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ronde ${session.roundNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.scansCount} scan',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

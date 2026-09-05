import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/domain.dart';
import '../providers/patrol_provider.dart';
import '../widgets/checkpoint_path.dart';

/// Patrol home screen - shows today's patrol status and scan button
class PatrolHomeScreen extends StatefulWidget {
  const PatrolHomeScreen({super.key});

  @override
  State<PatrolHomeScreen> createState() => _PatrolHomeScreenState();
}

class _PatrolHomeScreenState extends State<PatrolHomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final notifier = context.read<PatrolNotifier>();

    // Set navigation callback for alarm
    notifier.navigateToAlarmScreen = (message) {
      context.push(
        '/patrol/alarm?message=${Uri.encodeComponent(message ?? '')}',
      );
    };

    notifier.loadTodayStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleScan() async {
    final notifier = context.read<PatrolNotifier>();

    // Open scanner
    final qrCode = await context.push<String>('/patrol/scan');
    if (qrCode == null || !mounted) return;

    // Parse QR to check if OTP is needed
    final qrResult = QRScanResult.fromQRContent(qrCode);

    if (qrResult.hasSecretKey) {
      // Show OTP dialog
      final otp = await _showOtpDialog(qrResult.code, qrResult.secretKey!);
      if (otp == null || !mounted) return;

      // Submit OTP and scan
      final result = await notifier.submitOtpAndScan(qrCode, otp);
      if (result == null || !mounted) return;

      // Handle result
      _handleResult(result);
    } else {
      // No OTP needed, scan directly
      final result = await notifier.performScan(qrCode);
      if (result == null || !mounted) return;

      // Handle result (might be null if OTP is needed but we handle above)
      if (result.success) {
        _handleResult(result);
      }
    }
  }

  /// Show dialog to input OTP code
  Future<String?> _showOtpDialog(String checkpointName, String secretKey) async {
    final theme = context.theme;
    final controller = TextEditingController();
    final notifier = context.read<PatrolNotifier>();

    // Generate initial TOTP
    String currentOtp = notifier.generateTOTP(secretKey);

    // Timer for OTP refresh
    int countdown = 30;
    Timer? timer;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Start timer on first build
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              setState(() {
                countdown--;
                if (countdown <= 0) {
                  countdown = 30;
                  currentOtp = notifier.generateTOTP(secretKey);
                }
              });
            });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
            title: Row(
              children: [
                Icon(IconMap.lock, color: theme.colors.destructive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkpointName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // OTP Display
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withAlpha(26),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: theme.colors.primary.withAlpha(77),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'KODE OTP',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentOtp,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colors.primary,
                          letterSpacing: 8,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: countdown <= 5
                              ? theme.colors.destructive.withAlpha(51)
                              : theme.colors.primary.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Berubah dalam ${countdown}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: countdown <= 5
                                ? theme.colors.destructive
                                : theme.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Input field - using FTextField
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: controller,
                    onChange: (_) {},
                  ),
                  size: FTextFieldSizeVariant.md,
                  hint: 'Input kode OTP',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Masukkan kode 6 digit di atas',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            actions: [
              FButton(
                onPress: () {
                  timer?.cancel();
                  Navigator.pop(context, null);
                },
                variant: FButtonVariant.ghost,
                child: const Text('Batal'),
              ),
              FButton(
                onPress: () {
                  timer?.cancel();
                  Navigator.pop(context, controller.text);
                },
                child: const Text('Konfirmasi'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleResult(PatrolScanResult result) {
    if (result.success) {
      if (result.valid) {
        // Success with valid location - use custom notification
        _showNotification(
          'Checkpoint ${result.checkpoint?.name ?? ''} berhasil discan!',
          AppColors.success,
        );
      } else {
        // Success but location warning
        _showNotification(
          result.validation?.locationMessage ??
              'Scan berhasil - lokasi di luar radius',
          AppColors.warning,
          duration: const Duration(seconds: 4),
        );
      }
    } else {
      // Error
      _handleError(result);
    }
  }

  void _showNotification(String message, Color backgroundColor, {Duration? duration}) {
    // Use custom notification overlay
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _handleError(PatrolScanResult result) {
    final theme = context.theme;
    final code = result.errorCode;
    final message = result.errorMessage ?? 'Scan gagal';

    if (code == 'MOCK_LOCATION') {
      _showMockLocationDialog(message);
    } else if (code == 'INVALID_TOTP') {
      _showTOTPErrorDialog(message);
    } else if (code == 'TIME_DRIFT') {
      _showTimeDriftDialog(message);
    } else {
      _showNotification(message, theme.colors.destructive, duration: const Duration(seconds: 4));
    }
  }

  void _showMockLocationDialog(String message) {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Row(
          children: [
            Icon(IconMap.warning, color: theme.colors.destructive),
            const SizedBox(width: 8),
            const Text('GPS Palsu Terdeteksi'),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'GPS palsu (fake GPS) terdeteksi. Matikan aplikasi fake GPS untuk melanjutkan patroli.',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.ghost,
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTOTPErrorDialog(String message) {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Row(
          children: [
            Icon(IconMap.lock, color: theme.colors.destructive),
            const SizedBox(width: 8),
            const Text('Kode OTP Salah'),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'Kode OTP tidak valid atau sudah kadaluarsa. Pastikan waktu perangkat Anda sudah sinkron.',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.ghost,
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTimeDriftDialog(String message) {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Row(
          children: [
            Icon(IconMap.schedule, color: theme.colors.secondary),
            const SizedBox(width: 8),
            const Text('Waktu Tidak Sinkron'),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'Waktu perangkat Anda tidak sinkron dengan server. Mohon perbarui waktu otomatis di pengaturan perangkat.',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.ghost,
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
              return const Center(child: LoadingIndicator(size: 32));
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
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue ? theme.colors.destructive : theme.colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? IconMap.warning : IconMap.timer,
            size: 16,
            color: isOverdue ? theme.colors.destructiveForeground : theme.colors.primaryForeground,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOverdue ? theme.colors.destructiveForeground : theme.colors.primaryForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PatrolNotifier notifier) {
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.errorOutline, size: 64, color: theme.colors.destructive),
            const SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 150,
              child: PrimaryButton(
                label: 'Coba Lagi',
                onPressed: () => notifier.loadTodayStatus(),
                fullWidth: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSchedule() {
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.eventBusy, size: 64, color: theme.colors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ada jadwal patroli hari ini',
              style: TextStyle(fontSize: 16, color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PatrolNotifier notifier, PatrolTodayStatus status) {
    return SingleChildScrollView(
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
        icon: IconMap.qrCodeScanner,
        isLoading: isLoading,
        onPressed: isLoading ? null : _handleScan,
      ),
    );
  }

  Widget _buildCountdownCard(PatrolNotifier notifier) {
    final theme = context.theme;
    final progress = notifier.state.todayStatus?.currentProgress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colors.primary, theme.colors.primary.withAlpha(204)],
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: theme.colors.primary.withAlpha(77),
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
                  color: theme.colors.primaryForeground.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(IconMap.timer, color: theme.colors.primaryForeground, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkpoint Berikutnya',
                      style: TextStyle(fontSize: 14, color: theme.colors.primaryForeground.withAlpha(179)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notifier.state.roundCountdownText ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.primaryForeground,
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
                        color: theme.colors.primaryForeground.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(progress.currentRoundDueAt!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.primaryForeground,
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
    final theme = context.theme;
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
            backgroundColor: theme.colors.primaryForeground.withAlpha(51),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colors.primaryForeground),
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
                color: theme.colors.primaryForeground.withAlpha(179),
              ),
            ),
            Text(
              'Selesai: ${_formatTime(dueAt)}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colors.primaryForeground.withAlpha(179),
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
    final theme = context.theme;
    final schedule = status.schedule;
    if (schedule == null) return const SizedBox.shrink();

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(IconMap.locationCity, color: theme.colors.secondaryForeground),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.areaName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${schedule.shiftName} (${schedule.shiftStartTime} - ${schedule.shiftEndTime})',
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
            IconMap.checkCircle,
            context.theme.colors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Sedang Berlangsung',
            '${status.stats?.inProgressRounds ?? 0}',
            IconMap.playCircle,
            context.theme.colors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Total Titik',
            '${status.stats?.totalCheckpoints ?? 0}',
            IconMap.place,
            context.theme.colors.muted,
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
    final theme = context.theme;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
              style: TextStyle(
                fontSize: 10,
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointPath(
    PatrolNotifier notifier,
    PatrolTodayStatus status,
  ) {
    final theme = context.theme;
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

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Peta Checkpoint',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.colors.foreground,
                  ),
                ),
                if (notifier.state.isCountingDown)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconMap.timer,
                          size: 14,
                          color: theme.colors.secondaryForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${notifier.state.countdownSeconds}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colors.secondaryForeground,
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
                    _showNotification(
                      'Selesaikan checkpoint sebelumnya dulu',
                      AppColors.warning,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistory(PatrolTodayStatus status) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Ronde Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...status.sessions.map((session) => _buildSessionItem(session)),
      ],
    );
  }

  Widget _buildSessionItem(PatrolSession session) {
    final theme = context.theme;
    Color statusColor;
    IconData statusIcon;

    switch (session.status) {
      case 'in_progress':
        statusColor = theme.colors.primary;
        statusIcon = IconMap.playCircle;
        break;
      case 'completed':
        statusColor = theme.colors.primary;
        statusIcon = IconMap.checkCircle;
        break;
      default:
        statusColor = theme.colors.muted;
        statusIcon = IconMap.cancel;
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colors.foreground,
                  ),
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.scansCount} scan',
            style: TextStyle(
              fontSize: 12,
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom notification overlay (replaces SnackBar)
class _NotificationOverlay extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: AppRadius.radiusMd,
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

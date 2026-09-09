import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../providers/client_reports_provider.dart';

/// Client reports list screen (Daily Tasks, Patrol, Field Reports)
class ClientReportsScreen extends StatefulWidget {
  final String reportType; // 'tasks', 'patrol', 'field'

  const ClientReportsScreen({super.key, required this.reportType});

  @override
  State<ClientReportsScreen> createState() => _ClientReportsScreenState();
}

class _ClientReportsScreenState extends State<ClientReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Set initial tab based on reportType after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      int initialIndex;
      switch (widget.reportType) {
        case 'patrol':
          initialIndex = 1;
          break;
        case 'field':
          initialIndex = 2;
          break;
        default:
          initialIndex = 0;
      }
      if (_tabController.index != initialIndex) {
        _tabController.index = initialIndex;
      }
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    final notifier = context.read<ClientReportsNotifier>();
    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);

    switch (_tabController.index) {
      case 0:
        await notifier.fetchDailyTasks(fromDate: fromStr, toDate: toStr);
        break;
      case 1:
        await notifier.fetchPatrolReports(fromDate: fromStr, toDate: toStr);
        break;
      case 2:
        await notifier.fetchFieldReports(fromDate: fromStr, toDate: toStr);
        break;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchData();
    }
  }

  String get _title {
    switch (widget.reportType) {
      case 'tasks':
        return 'Daily Tasks';
      case 'patrol':
        return 'Patrol Reports';
      case 'field':
        return 'Field Reports';
      default:
        return 'Reports';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ClientReportsNotifier>().state;
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          FButton.icon(
            onPress: _selectDateRange,
            child: const Icon(FLucideIcons.calendarRange),
          ),
          const SizedBox(width: 8),
          FButton.icon(
            onPress: _fetchData,
            child: const Icon(FLucideIcons.refreshCcw),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tugas'),
            Tab(text: 'Patrol'),
            Tab(text: 'Field'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: AppColors.gray100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}',
                  style: theme.typography.body.md.copyWith(color: AppColors.gray600),
                ),
                FButton(
                  onPress: _selectDateRange,
                  variant: FButtonVariant.ghost,
                  prefix: const Icon(FLucideIcons.pencil, size: 16),
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(state, theme),
                _buildPatrolTab(state, theme),
                _buildFieldTab(state, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab(ClientReportsState state, FThemeData theme) {
    if (state.isLoadingTasks) {
      return const Center(child: LoadingIndicator());
    }

    if (state.tasksError != null) {
      return _buildError(state.tasksError!, () => _fetchData(), theme);
    }

    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.checkCircle2, size: 64, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('Belum ada tugas', style: theme.typography.body.md),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.tasks.length,
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return _TaskCard(
            task: task,
            theme: theme,
            onTap: () => _showProgressChecksSheet(context, task),
          );
        },
      ),
    );
  }

  void _showProgressChecksSheet(BuildContext context, DailyTaskRecord task) {
    final notifier = context.read<ClientReportsNotifier>();
    notifier.fetchProgressChecks(task.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProgressChecksBottomSheet(
        task: task,
      ),
    );
  }

  Widget _buildPatrolTab(ClientReportsState state, FThemeData theme) {
    if (state.isLoadingPatrol) {
      return const Center(child: LoadingIndicator());
    }

    if (state.patrolError != null) {
      return _buildError(state.patrolError!, () => _fetchData(), theme);
    }

    if (state.patrolReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.shield, size: 64, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('Belum ada patrol', style: theme.typography.body.md),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.patrolReports.length,
        itemBuilder: (context, index) {
          final report = state.patrolReports[index];
          return _PatrolCard(report: report, theme: theme);
        },
      ),
    );
  }

  Widget _buildFieldTab(ClientReportsState state, FThemeData theme) {
    if (state.isLoadingField) {
      return const Center(child: LoadingIndicator());
    }

    if (state.fieldError != null) {
      return _buildError(state.fieldError!, () => _fetchData(), theme);
    }

    if (state.fieldReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.alertTriangle, size: 64, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('Belum ada field report', style: theme.typography.body.md),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.fieldReports.length,
        itemBuilder: (context, index) {
          final report = state.fieldReports[index];
          return _FieldReportCard(report: report, theme: theme);
        },
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry, FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FLucideIcons.alertCircle, size: 64, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Gagal memuat: $error', style: theme.typography.body.md),
          const SizedBox(height: AppSpacing.lg),
          FButton(
            onPress: onRetry,
            variant: FButtonVariant.primary,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskRecord task;
  final FThemeData theme;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.task,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusMd,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(FLucideIcons.checkCircle2, size: 16, color: AppColors.info),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.itemName ?? 'Task',
                        style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        task.employeeName ?? '-',
                        style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (task.progressChecksCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FLucideIcons.camera, size: 12, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          '${task.progressChecksCount}',
                          style: theme.typography.body.xs.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                _StatusBadge(status: task.status, theme: theme),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Use Wrap instead of Row to prevent overflow on narrow screens
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FLucideIcons.calendar, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        task.assignedDate ?? '-',
                        style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (task.targetMinutes != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FLucideIcons.timer, size: 14, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        '${task.targetMinutes} min',
                        style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressChecksBottomSheet extends StatelessWidget {
  final DailyTaskRecord task;

  const _ProgressChecksBottomSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final state = context.watch<ClientReportsNotifier>().state;
    final isLoading = state.loadingProgressChecks[task.id] ?? false;
    final progressChecks = state.progressChecks[task.id] ?? [];
    final error = state.progressChecksError;

    // Format date
    String formattedDate = '-';
    if (task.assignedDate != null) {
      try {
        final date = DateTime.parse(task.assignedDate!);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      } catch (_) {
        formattedDate = task.assignedDate!;
      }
    }

    // Format time
    String formattedTime = '-';
    if (task.startAt != null && task.endAt != null) {
      try {
        final start = DateTime.parse(task.startAt!);
        final end = DateTime.parse(task.endAt!);
        formattedTime = '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
      } catch (_) {
        formattedTime = '${task.startAt} - ${task.endAt}';
      }
    } else if (task.startAt != null) {
      try {
        final start = DateTime.parse(task.startAt!);
        formattedTime = DateFormat('HH:mm').format(start);
      } catch (_) {
        formattedTime = task.startAt!;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with task details
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              border: Border(
                bottom: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(FLucideIcons.camera, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.itemName ?? 'Task',
                            style: theme.typography.body.lg.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            task.employeeName ?? '-',
                            style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(FLucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Task details row
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    // Area
                    if (task.areaName != null)
                      _DetailChip(
                        icon: FLucideIcons.mapPin,
                        label: task.areaName!,
                        theme: theme,
                      ),
                    // Date
                    _DetailChip(
                      icon: FLucideIcons.calendar,
                      label: formattedDate,
                      theme: theme,
                    ),
                    // Time
                    if (formattedTime != '-')
                      _DetailChip(
                        icon: FLucideIcons.clock,
                        label: formattedTime,
                        theme: theme,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: isLoading
                ? const Center(child: LoadingIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FLucideIcons.alertCircle, size: 48, color: AppColors.danger),
                              const SizedBox(height: AppSpacing.md),
                              Text('Gagal memuat: $error', style: theme.typography.body.md),
                            ],
                          ),
                        ),
                      )
                    : progressChecks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FLucideIcons.cameraOff, size: 48, color: AppColors.gray400),
                                  const SizedBox(height: AppSpacing.md),
                                  Text('Belum ada progress check', style: theme.typography.body.md),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: progressChecks.length,
                            itemBuilder: (context, index) {
                              final check = progressChecks[index];
                              return _ProgressCheckCard(check: check, theme: theme);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final FThemeData theme;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gray500),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

class _ProgressCheckCard extends StatefulWidget {
  final ProgressCheckRecord check;
  final FThemeData theme;

  const _ProgressCheckCard({required this.check, required this.theme});

  @override
  State<_ProgressCheckCard> createState() => _ProgressCheckCardState();
}

class _ProgressCheckCardState extends State<_ProgressCheckCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _hasVideoError = false;
  bool _isVideoLoading = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_videoController != null || _isVideoLoading) return;

    setState(() {
      _isVideoLoading = true;
      _hasVideoError = false;
    });

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.check.mediaUrl),
      );
      await _videoController!.initialize();
      await _videoController!.setLooping(false);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoLoading = false;
        });
        _playVideo();
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _isVideoLoading = false;
        });
      }
    }
  }

  void _playVideo() {
    if (_videoController == null) return;
    _videoController!.play();
    setState(() {
      _isVideoPlaying = true;
    });
    _videoController!.addListener(_videoListener);
  }

  void _pauseVideo() {
    _videoController?.pause();
    _videoController?.removeListener(_videoListener);
    if (mounted) {
      setState(() {
        _isVideoPlaying = false;
      });
    }
  }

  void _videoListener() {
    if (_videoController == null) return;
    if (_videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.duration.inMilliseconds > 0) {
      // Video ended
      _videoController!.removeListener(_videoListener);
      if (mounted) {
        setState(() {
          _isVideoPlaying = false;
        });
      }
    }
  }

  Future<void> _openPhotoFullscreen(BuildContext context) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => _PhotoZoomDialog(mediaUrl: widget.check.mediaUrl),
    );
  }

  Future<void> _openVideoExternal() async {
    final url = Uri.parse(widget.check.mediaUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media preview
          InkWell(
            onTap: () {
              if (widget.check.isPhoto) {
                _openPhotoFullscreen(context);
              } else {
                if (!_isVideoInitialized && !_hasVideoError) {
                  _initializeVideo();
                }
              }
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: widget.check.isPhoto
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            widget.check.mediaUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(FLucideIcons.imageOff, size: 48, color: AppColors.gray400),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: LoadingIndicator());
                            },
                          ),
                        ),
                        // Zoom icon
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              FLucideIcons.zoomIn,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildVideoPreview(),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FLucideIcons.user, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Karyawan: ${widget.check.employeeName ?? '-'}',
                        style: widget.theme.typography.body.sm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(FLucideIcons.userCheck, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dicek oleh: ${widget.check.checkedByName ?? '-'}',
                        style: widget.theme.typography.body.sm,
                      ),
                    ),
                  ],
                ),
                if (widget.check.notes != null && widget.check.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FLucideIcons.messageSquare, size: 14, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.check.notes!,
                          style: widget.theme.typography.body.sm,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(FLucideIcons.clock, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      widget.check.checkedAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(widget.check.checkedAt!))
                          : '-',
                      style: widget.theme.typography.body.xs.copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_isVideoLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Memuat video...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_hasVideoError) {
      return InkWell(
        onTap: () {
          // Try external player as fallback
          _openVideoExternal();
        },
        child: Container(
          color: AppColors.gray800,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FLucideIcons.playCircle,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Tap untuk buka dengan player lain',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isVideoInitialized && _videoController != null) {
      return GestureDetector(
        onTap: () {
          if (_isVideoPlaying) {
            _pauseVideo();
          } else {
            _playVideo();
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            if (!_isVideoPlaying)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FLucideIcons.play,
                  size: 32,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    // Default state - show placeholder
    return InkWell(
      onTap: () {
        if (!_isVideoInitialized && !_hasVideoError) {
          _initializeVideo();
        }
      },
      child: Container(
        color: AppColors.gray800,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Play icon center
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FLucideIcons.play,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            // VIDEO badge
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _PhotoZoomDialog extends StatelessWidget {
  final String mediaUrl;

  const _PhotoZoomDialog({required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    FLucideIcons.imageOff,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(FLucideIcons.x, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatrolCard extends StatelessWidget {
  final PatrolReportRecord report;
  final FThemeData theme;

  const _PatrolCard({required this.report, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(FLucideIcons.shield, size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.patrolRoundName ?? 'Patrol',
                      style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${report.employeeName ?? '-'} • ${report.areaName ?? '-'}',
                      style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: report.status ?? 'pending', theme: theme),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Use Wrap instead of Row to prevent overflow on narrow screens
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FLucideIcons.calendar, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(
                    report.patrolDate ?? '-',
                    style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FLucideIcons.qrCode, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(
                    '${report.totalScans ?? 0} scans',
                    style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldReportCard extends StatelessWidget {
  final FieldReportRecord report;
  final FThemeData theme;

  const _FieldReportCard({required this.report, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(FLucideIcons.alertTriangle, size: 16, color: AppColors.danger),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.note ?? 'Field Report',
                      style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${report.employeeName ?? '-'} • ${report.location ?? '-'}',
                      style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Use Wrap instead of Row to prevent overflow on narrow screens
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FLucideIcons.calendar, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(
                    report.reportDate ?? '-',
                    style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
              if (report.photoUrl != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FLucideIcons.image, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      'Ada foto',
                      style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final FThemeData theme;

  const _StatusBadge({required this.status, required this.theme});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'reviewed':
        color = AppColors.success;
        label = 'Selesai';
        break;
      case 'in_progress':
        color = AppColors.info;
        label = 'Dikerjakan';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'Pending';
        break;
      case 'assigned':
        color = AppColors.gray500;
        label = 'Ditugaskan';
        break;
      default:
        color = AppColors.gray500;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.typography.body.xs.copyWith(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

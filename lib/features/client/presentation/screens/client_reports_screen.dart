import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';


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

  void _fetchData() {
    final notifier = context.read<ClientReportsNotifier>();
    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);

    switch (_tabController.index) {
      case 0:
        notifier.fetchDailyTasks(fromDate: fromStr, toDate: toStr);
        break;
      case 1:
        notifier.fetchPatrolReports(fromDate: fromStr, toDate: toStr);
        break;
      case 2:
        notifier.fetchFieldReports(fromDate: fromStr, toDate: toStr);
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
      onRefresh: () async => _fetchData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.tasks.length,
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return _TaskCard(task: task, theme: theme);
        },
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
      onRefresh: () async => _fetchData(),
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
      onRefresh: () async => _fetchData(),
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

  const _TaskCard({required this.task, required this.theme});

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
                    ),
                    Text(
                      task.employeeName ?? '-',
                      style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: task.status, theme: theme),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(FLucideIcons.calendar, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                task.assignedDate ?? '-',
                style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
              ),
              if (task.targetMinutes != null) ...[
                const SizedBox(width: AppSpacing.md),
                Icon(FLucideIcons.timer, size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  '${task.targetMinutes} min',
                  style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                ),
              ],
            ],
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
                    ),
                    Text(
                      '${report.employeeName ?? '-'} • ${report.areaName ?? '-'}',
                      style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: report.status ?? 'pending', theme: theme),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(FLucideIcons.calendar, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                report.patrolDate ?? '-',
                style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
              ),
              const SizedBox(width: AppSpacing.md),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(FLucideIcons.calendar, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                report.reportDate ?? '-',
                style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
              ),
              if (report.photoUrl != null) ...[
                const SizedBox(width: AppSpacing.md),
                Icon(FLucideIcons.image, size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  'Ada foto',
                  style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                ),
              ],
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

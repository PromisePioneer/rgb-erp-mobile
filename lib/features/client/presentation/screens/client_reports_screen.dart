import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter Tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
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
                  style: const TextStyle(color: AppColors.gray600),
                ),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Ubah'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(state),
                _buildPatrolTab(state),
                _buildFieldTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab(ClientReportsState state) {
    if (state.isLoadingTasks) {
      return const Center(child: LoadingIndicator());
    }

    if (state.tasksError != null) {
      return _buildError(state.tasksError!, () => _fetchData());
    }

    if (state.tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: AppColors.gray400),
            SizedBox(height: AppSpacing.md),
            Text('Belum ada tugas'),
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
          return _TaskCard(task: task);
        },
      ),
    );
  }

  Widget _buildPatrolTab(ClientReportsState state) {
    if (state.isLoadingPatrol) {
      return const Center(child: LoadingIndicator());
    }

    if (state.patrolError != null) {
      return _buildError(state.patrolError!, () => _fetchData());
    }

    if (state.patrolReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: AppColors.gray400),
            SizedBox(height: AppSpacing.md),
            Text('Belum ada patrol'),
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
          return _PatrolCard(report: report);
        },
      ),
    );
  }

  Widget _buildFieldTab(ClientReportsState state) {
    if (state.isLoadingField) {
      return const Center(child: LoadingIndicator());
    }

    if (state.fieldError != null) {
      return _buildError(state.fieldError!, () => _fetchData());
    }

    if (state.fieldReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem_outlined, size: 64, color: AppColors.gray400),
            SizedBox(height: AppSpacing.md),
            Text('Belum ada field report'),
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
          return _FieldReportCard(report: report);
        },
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Gagal memuat: $error'),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskRecord task;

  const _TaskCard({required this.task});

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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.info.withAlpha(26),
                child: const Icon(Icons.task_alt, size: 16, color: AppColors.info),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.itemName ?? 'Task',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      task.employeeName ?? '-',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                task.assignedDate ?? '-',
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
              if (task.targetMinutes != null) ...[
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  '${task.targetMinutes} min',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
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

  const _PatrolCard({required this.report});

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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.warning.withAlpha(26),
                child: const Icon(Icons.security, size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.patrolRoundName ?? 'Patrol',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${report.employeeName ?? '-'} • ${report.areaName ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: report.status ?? 'pending'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                report.patrolDate ?? '-',
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.qr_code_scanner, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                '${report.totalScans ?? 0} scans',
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
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

  const _FieldReportCard({required this.report});

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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.danger.withAlpha(26),
                child: const Icon(Icons.report_problem_outlined, size: 16, color: AppColors.danger),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.note ?? 'Field Report',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${report.employeeName ?? '-'} • ${report.location ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text(
                report.reportDate ?? '-',
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
              if (report.photoUrl != null) ...[
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.photo, size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                const Text(
                  'Ada foto',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
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

  const _StatusBadge({required this.status});

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
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../client/presentation/providers/client_attendance_provider.dart';

/// Client attendance list screen
class ClientAttendanceScreen extends StatefulWidget {
  const ClientAttendanceScreen({super.key});

  @override
  State<ClientAttendanceScreen> createState() => _ClientAttendanceScreenState();
}

class _ClientAttendanceScreenState extends State<ClientAttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final notifier = context.read<ClientAttendanceNotifier>();
    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);
    notifier.fetchAttendance(fromDate: fromStr, toDate: toStr);
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ClientAttendanceNotifier>().state;
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
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
            Tab(text: 'Hari Ini'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: AppColors.gray100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}',
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
          // Tab content
          Expanded(
            child: state.isLoading && state.attendanceData == null
                ? const Center(child: LoadingIndicator())
                : state.error != null && state.attendanceData == null
                    ? _buildError(state.error!, theme)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTodayTab(state, theme),
                          _buildHistoryTab(state, theme),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(ClientAttendanceState state, FThemeData theme) {
    final todayData = state.attendanceData.where((e) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return e.capturedAt?.startsWith(today) ?? false;
    }).toList() ?? [];

    if (todayData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.calendarX, size: 64, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('Belum ada data absensi hari ini', style: theme.typography.body.md),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: todayData.length,
        itemBuilder: (context, index) {
          final item = todayData[index];
          return _AttendanceCard(item: item, theme: theme);
        },
      ),
    );
  }

  Widget _buildHistoryTab(ClientAttendanceState state, FThemeData theme) {
    final data = state.attendanceData ?? [];

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.history, size: 64, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('Belum ada data absensi', style: theme.typography.body.md),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final item in data) {
      final date = item.capturedAt?.substring(0, 10) ?? 'Unknown';
      grouped.putIfAbsent(date, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final date = grouped.keys.elementAt(index);
          final items = grouped[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(date)),
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...items.map((item) => _AttendanceCard(item: item, theme: theme)),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(String error, FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FLucideIcons.alertCircle, size: 64, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Gagal memuat data: $error', style: theme.typography.body.md),
          const SizedBox(height: AppSpacing.lg),
          FButton(
            onPress: _fetchData,
            variant: FButtonVariant.primary,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final dynamic item;
  final FThemeData theme;

  const _AttendanceCard({required this.item, required this.theme});

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    (item.employeeName ?? '?')[0].toUpperCase(),
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.employeeName ?? 'Unknown',
                      style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.employeeCode ?? '',
                      style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusChip(type: item.type, theme: theme),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(FLucideIcons.mapPin, size: 16, color: AppColors.gray500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.areaName ?? '-',
                  style: theme.typography.body.xs.copyWith(color: AppColors.gray600),
                ),
              ),
              if (item.capturedAt != null) ...[
                Icon(FLucideIcons.clock, size: 16, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(DateTime.parse(item.capturedAt!)),
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

class _StatusChip extends StatelessWidget {
  final String type;
  final FThemeData theme;

  const _StatusChip({required this.type, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = type == 'check_in';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCheckIn ? AppColors.success.withAlpha(26) : AppColors.warning.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCheckIn ? 'Masuk' : 'Pulang',
        style: theme.typography.body.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: isCheckIn ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

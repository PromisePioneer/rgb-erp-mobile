import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
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
          // Tab content
          Expanded(
            child: state.isLoading && state.attendanceData == null
                ? const Center(child: LoadingIndicator())
                : state.error != null && state.attendanceData == null
                    ? _buildError(state.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTodayTab(state),
                          _buildHistoryTab(state),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(ClientAttendanceState state) {
    final todayData = state.attendanceData.where((e) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return e.capturedAt?.startsWith(today) ?? false;
    }).toList() ?? [];

    if (todayData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.gray400),
            SizedBox(height: AppSpacing.md),
            Text('Belum ada data absensi hari ini'),
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
          return _AttendanceCard(item: item);
        },
      ),
    );
  }

  Widget _buildHistoryTab(ClientAttendanceState state) {
    final data = state.attendanceData ?? [];

    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.gray400),
            SizedBox(height: AppSpacing.md),
            Text('Belum ada data absensi'),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...items.map((item) => _AttendanceCard(item: item)),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Gagal memuat data: $error'),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final dynamic item;

  const _AttendanceCard({required this.item});

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
                backgroundColor: AppColors.primary.withAlpha(26),
                child: Text(
                  (item.employeeName ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.employeeName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.employeeCode ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusChip(type: item.type),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.areaName ?? '-',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ),
              if (item.capturedAt != null) ...[
                const Icon(Icons.access_time, size: 16, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(DateTime.parse(item.capturedAt!)),
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

class _StatusChip extends StatelessWidget {
  final String type;

  const _StatusChip({required this.type});

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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isCheckIn ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../providers/client_schedule_provider.dart';

/// Client schedule screen with calendar
class ClientScheduleScreen extends StatefulWidget {
  const ClientScheduleScreen({super.key});

  @override
  State<ClientScheduleScreen> createState() => _ClientScheduleScreenState();
}

class _ClientScheduleScreenState extends State<ClientScheduleScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    // Auto-select today's date
    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<ClientScheduleNotifier>();
      // Fetch schedule dates and today's employees
      notifier.fetchScheduleDates(
        year: _currentMonth.year,
        month: _currentMonth.month,
      );
      // Fetch employees for today immediately
      notifier.fetchEmployeesByDate(_selectedDate!);
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    context.read<ClientScheduleNotifier>().fetchScheduleDates(
          year: _currentMonth.year,
          month: _currentMonth.month,
        );
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    context.read<ClientScheduleNotifier>().fetchScheduleDates(
          year: _currentMonth.year,
          month: _currentMonth.month,
        );
  }

  void _onDateTap(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    context.read<ClientScheduleNotifier>().fetchEmployeesByDate(date);
  }

  Future<void> _refreshAll() async {
    final notifier = context.read<ClientScheduleNotifier>();
    await notifier.fetchScheduleDates(
      year: _currentMonth.year,
      month: _currentMonth.month,
    );
    if (_selectedDate != null) {
      await notifier.fetchEmployeesByDate(_selectedDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Karyawan'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: Consumer<ClientScheduleNotifier>(
          builder: (context, notifier, child) {
            return Column(
              children: [
                // Calendar Header
                _CalendarHeader(
                  currentMonth: _currentMonth,
                  onPrevious: _previousMonth,
                  onNext: _nextMonth,
                  theme: theme,
                ),
                // Calendar Grid
                _CalendarGrid(
                  currentMonth: _currentMonth,
                  selectedDate: _selectedDate,
                  scheduleDates: notifier.dateState.dates,
                  isLoading: notifier.dateState.isLoading,
                  onDateTap: _onDateTap,
                ),
                const Divider(height: 1),
                // Selected Date Employees
                Expanded(
                  child: _EmployeesList(
                    selectedDate: _selectedDate,
                    employees: notifier.employeeState.employees,
                    isLoading: notifier.employeeState.isLoading,
                    error: notifier.employeeState.error,
                    theme: theme,
                    onRetry: () {
                      if (_selectedDate != null) {
                        notifier.fetchEmployeesByDate(_selectedDate!);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final FThemeData theme;

  const _CalendarHeader({
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FButton.icon(
            onPress: onPrevious,
            child: const Icon(FLucideIcons.chevronLeft),
          ),
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(currentMonth),
            style: theme.typography.display.sm,
          ),
          FButton.icon(
            onPress: onNext,
            child: const Icon(FLucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final List<ScheduleDate> scheduleDates;
  final bool isLoading;
  final Function(DateTime) onDateTap;

  const _CalendarGrid({
    required this.currentMonth,
    required this.selectedDate,
    required this.scheduleDates,
    required this.isLoading,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    final scheduleDatesSet = scheduleDates.map((d) => d.date.day).toSet();
    final scheduleCountMap = {for (var d in scheduleDates) d.date.day: d.count};

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Calendar days
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LoadingIndicator(),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (startWeekday - 1);
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(currentMonth.year, currentMonth.month, dayOffset);
              final isToday = _isToday(date);
              final isSelected = selectedDate != null &&
                  date.year == selectedDate!.year &&
                  date.month == selectedDate!.month &&
                  date.day == selectedDate!.day;
              final hasSchedule = scheduleDatesSet.contains(dayOffset);
              final scheduleCount = scheduleCountMap[dayOffset] ?? 0;

              return GestureDetector(
                onTap: () => onDateTap(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : hasSchedule
                            ? AppColors.primary.withAlpha(26)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayOffset',
                        style: TextStyle(
                          fontWeight: isToday || isSelected ? FontWeight.bold : null,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      if (hasSchedule && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$scheduleCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _EmployeesList extends StatelessWidget {
  final DateTime? selectedDate;
  final List<ScheduledEmployee> employees;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final FThemeData theme;

  const _EmployeesList({
    required this.selectedDate,
    required this.employees,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.calendar, size: 48, color: AppColors.gray300),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pilih tanggal untuk melihat jadwal',
              style: theme.typography.body.md.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.alertCircle, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text('Error: $error', style: theme.typography.body.md),
            const SizedBox(height: AppSpacing.md),
            FButton(
              onPress: onRetry,
              variant: FButtonVariant.primary,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.calendarX, size: 48, color: AppColors.gray300),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tidak ada jadwal pada ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate!)}',
              style: theme.typography.body.md.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Jadwal ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate!)}',
            style: theme.typography.display.sm,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return _EmployeeScheduleCard(employee: emp, theme: theme);
            },
          ),
        ),
      ],
    );
  }
}

class _EmployeeScheduleCard extends StatelessWidget {
  final ScheduledEmployee employee;
  final FThemeData theme;

  const _EmployeeScheduleCard({required this.employee, required this.theme});

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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                _getInitials(employee.employeeName),
                style: theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.employeeName,
                  style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (employee.role != null && employee.role!.isNotEmpty && employee.role != '-')
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      employee.role!,
                      style: theme.typography.body.xs.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Icon(FLucideIcons.clock, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${employee.shiftName} (${employee.shiftStart} - ${employee.shiftEnd})',
                        style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(FLucideIcons.mapPin, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${employee.areaName} - ${employee.posName}',
                        style: theme.typography.body.xs.copyWith(color: AppColors.gray500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(employee.status).withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              employee.status.toUpperCase(),
              style: theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(employee.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.gray500;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../providers/daily_task_provider.dart';

/// Task Progress List Screen - Show tasks assigned by Team Leader for progress checking
class TaskProgressScreen extends StatefulWidget {
  const TaskProgressScreen({super.key});

  @override
  State<TaskProgressScreen> createState() => _TaskProgressScreenState();
}

class _TaskProgressScreenState extends State<TaskProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyTaskNotifier>().loadProgressTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Monitoring Tugas Harian'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
      ),
      body: Consumer<DailyTaskNotifier>(
        builder: (context, notifier, _) {
          if (notifier.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (notifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.alertCircle, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    notifier.error!,
                    style: const TextStyle(color: AppColors.slate600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => notifier.loadProgressTasks(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final tasks = notifier.progressTasks;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.task, size: 64, color: AppColors.slate300),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada tugas untuk dicek',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tugas yang sedang dikerjakan akan muncul di sini',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifier.loadProgressTasks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskProgressCard(task: task);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TaskProgressCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const _TaskProgressCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] as String? ?? '';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final progressCount = task['progress_check_count'] as int? ?? 0;

    return GestureDetector(
      onTap: () => context.push('/task-progress/${task['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(IconMap.task, size: 18, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        task['item_name'] as String? ?? 'Tugas',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Area
                  if (task['area_name'] != null) ...[
                    Row(
                      children: [
                        Icon(IconMap.locationOn, size: 14,
                            color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Text(
                          task['area_name'] as String,
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Employees
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(IconMap.people, size: 14, color: AppColors.slate500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getEmployeeNames(task),
                          style: const TextStyle(
                            color: AppColors.slate600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress check count
                      Row(
                        children: [
                          Icon(IconMap.visibility, size: 14,
                              color: AppColors.slate500),
                          const SizedBox(width: 4),
                          Text(
                            '$progressCount progress check',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Arrow
                      Icon(IconMap.chevronRight, size: 20,
                          color: AppColors.slate500),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmployeeNames(Map<String, dynamic> task) {
    final employees = task['employees'] as List<dynamic>? ?? [];
    if (employees.isEmpty) {
      return task['employee_name'] as String? ?? '-';
    }
    return employees.map((e) => e['name'] as String? ?? '').where((n) =>
    n.isNotEmpty).join(', ');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'reviewed':
        return AppColors.info;
      default:
        return AppColors.slate500;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'Sedang Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'reviewed':
        return 'Direview';
      default:
        return status;
    }
  }
}

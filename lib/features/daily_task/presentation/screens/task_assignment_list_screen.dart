import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../providers/daily_task_provider.dart';

/// Screen for supervisors to view and manage daily task assignments
class TaskAssignmentListScreen extends StatefulWidget {
  const TaskAssignmentListScreen({super.key});

  @override
  State<TaskAssignmentListScreen> createState() => _TaskAssignmentListScreenState();
}

class _TaskAssignmentListScreenState extends State<TaskAssignmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<DailyTaskNotifier>().loadAssignments();
  }

  Future<void> _deleteAssignment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DailyTaskNotifier>().deleteAssignment(id);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'assigned':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'reviewed':
        return AppColors.primary;
      default:
        return AppColors.slate400;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'assigned':
        return 'Ditugaskan';
      case 'in_progress':
        return 'Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'reviewed':
        return 'Direview';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DailyTaskNotifier>();
    final assignments = notifier.assignments;
    final isLoading = notifier.isLoading;
    final error = notifier.error;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/daily-task-assignment/new'),
            tooltip: 'Tambah Tugas',
          ),
        ],
      ),
      body: error != null && assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : isLoading && assignments.isEmpty
              ? const LoadingIndicator()
              : assignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt,
                            size: 64,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada tugas',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/daily-task-assignment/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Tugas'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadData(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final assignment = assignments[index];
                          final id = assignment['id'] as int?;
                          final employeeName = assignment['employee_name'] as String? ?? '-';
                          final status = assignment['status'] as String?;
                          final targetMinutes = assignment['target_minutes'] as int?;
                          final notes = assignment['notes'] as String?;
                          final assignedDate = assignment['assigned_date'] as String?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                employeeName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withAlpha(26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getStatusLabel(status),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (targetMinutes != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target: $targetMinutes menit',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                  if (assignedDate != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tanggal: ${_formatDate(assignedDate)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                  if (notes != null && notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      notes,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.slate500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: status == 'assigned'
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.danger,
                                      ),
                                      onPressed: () => _deleteAssignment(id!),
                                    )
                                  : null,
                              onTap: () {
                                // Could navigate to detail screen if needed
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

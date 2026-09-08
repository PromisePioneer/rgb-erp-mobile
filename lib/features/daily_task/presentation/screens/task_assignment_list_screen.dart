import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/toast/app_toast.dart';
import '../providers/daily_task_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen for supervisors to view and manage daily task assignments
class TaskAssignmentListScreen extends StatefulWidget {
  const TaskAssignmentListScreen({super.key});

  @override
  State<TaskAssignmentListScreen> createState() => _TaskAssignmentListScreenState();
}

class _TaskAssignmentListScreenState extends State<TaskAssignmentListScreen> {
  bool _canAssignTask = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivilegesAndLoadData();
    });
  }

  void _checkPrivilegesAndLoadData() {
    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.state.user;
    final canAssign = user?.hasPrivilege('daily_task_assign') ?? false;

    setState(() {
      _canAssignTask = canAssign;
    });

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
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DailyTaskNotifier>().deleteAssignment(id);
      if (mounted) {
        AppToast.of(context).show(
          message: 'Tugas berhasil dihapus',
          style: AppToastStyle.success,
        );
      }
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

  Color _getStatusColor(String? status, FThemeData theme) {
    switch (status) {
      case 'assigned':
        return theme.colors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'reviewed':
        return AppColors.info;
      default:
        return theme.colors.mutedForeground;
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
    final theme = context.theme;
    final notifier = context.watch<DailyTaskNotifier>();
    final assignments = notifier.assignments;
    final isLoading = notifier.isLoading;
    final error = notifier.error;

    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
        actions: [
          if (_canAssignTask)
            IconButton(
              onPressed: () => context.push('/daily-task-assignment/new'),
              icon: Icon(IconMap.plus),
              tooltip: 'Tambah Tugas',
            ),
        ],
      ),
      body: error != null && assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.errorOutline, size: 48, color: theme.colors.destructive),
                  const SizedBox(height: 16),
                  Text(error, textAlign: TextAlign.center, style: TextStyle(color: theme.colors.foreground)),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: _checkPrivilegesAndLoadData,
                    variant: FButtonVariant.primary,
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
                          Icon(
                            IconMap.checkCircle,
                            size: 64,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tugas',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_canAssignTask)
                            FButton(
                              onPress: () => context.push('/daily-task-assignment/new'),
                              variant: FButtonVariant.primary,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(IconMap.plus, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text('Tambah Tugas'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _checkPrivilegesAndLoadData(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final assignment = assignments[index];

                          // Debug logging
                          debugPrint('=== ASSIGNMENT CARD DEBUG ===');
                          debugPrint('Keys: ${assignment.keys.toList()}');
                          debugPrint('notes: ${assignment['notes']}');
                          debugPrint('target_note: ${assignment['target_note']}');
                          debugPrint('===========================');

                          final id = assignment['id'] as int?;
                          final employeeNames = assignment['employee_names'] as String? ?? assignment['employee_name'] as String? ?? '-';
                          final employeeCount = assignment['employee_count'] as int?;
                          final status = assignment['status'] as String?;
                          final targetMinutes = assignment['target_minutes'] as int?;
                          final notes = assignment['notes'] as String? ?? assignment['target_note'] as String?;
                          final assignedDate = assignment['assigned_date'] as String?;
                          final statusColor = _getStatusColor(status, theme);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colors.card,
                              borderRadius: AppRadius.radiusLg,
                              border: Border.all(color: theme.colors.border, width: 1),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Could navigate to detail screen if needed
                              },
                              borderRadius: AppRadius.radiusLg,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employeeNames,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.colors.foreground,
                                                ),
                                              ),
                                              if (employeeCount != null && employeeCount > 1) ...[
                                                const SizedBox(height: 2),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: theme.colors.primary.withAlpha(26),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '$employeeCount karyawan',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: theme.colors.primary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (status == 'assigned')
                                          IconButton(
                                            onPressed: () => _deleteAssignment(id!),
                                            icon: Icon(IconMap.trash, color: theme.colors.destructive),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(26),
                                        borderRadius: AppRadius.radiusSm,
                                      ),
                                      child: Text(
                                        _getStatusLabel(status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: statusColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (targetMinutes != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Target: $targetMinutes menit',
                                        style: TextStyle(fontSize: 13, color: theme.colors.foreground),
                                      ),
                                    ],
                                    if (assignedDate != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tanggal: ${_formatDate(assignedDate)}',
                                        style: TextStyle(fontSize: 13, color: theme.colors.foreground),
                                      ),
                                    ],
                                    if (notes != null && notes.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: theme.colors.muted,
                                          borderRadius: AppRadius.radiusSm,
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(IconMap.editNote, size: 14, color: theme.colors.mutedForeground),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                notes,
                                                style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

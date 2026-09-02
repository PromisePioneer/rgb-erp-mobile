import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/daily_task.dart';
import '../providers/daily_task_provider.dart';

/// Task detail screen for Team Leader - read-only view of assigned tasks
class TaskDetailLeaderScreen extends StatefulWidget {
  final int taskId;
  final Map<String, dynamic>? initialData;

  const TaskDetailLeaderScreen({
    super.key,
    required this.taskId,
    this.initialData,
  });

  @override
  State<TaskDetailLeaderScreen> createState() => _TaskDetailLeaderScreenState();
}

class _TaskDetailLeaderScreenState extends State<TaskDetailLeaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final notifier = context.read<DailyTaskNotifier>();
    notifier.loadTaskDetail(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Detail Tugas Karyawan'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconMap.chevronLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(IconMap.pencil),
            onPressed: () => _showEditOptions(context),
          ),
        ],
      ),
      body: Consumer<DailyTaskNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoading && notifier.selectedTask == null) {
            return const Center(child: LoadingIndicator());
          }

          final task = notifier.selectedTask;
          if (task == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.errorOutline,
                      size: 48, color: theme.colors.destructive),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tugas tidak ditemukan',
                    style: TextStyle(color: theme.colors.foreground),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FButton(
                    onPress: () => context.pop(),
                    variant: FButtonVariant.outline,
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Status card
              _buildStatusCard(task, theme),
              const SizedBox(height: AppSpacing.md),

              // Employees card
              _buildEmployeesCard(task, theme),
              const SizedBox(height: AppSpacing.md),

              // Task info card
              _buildTaskInfoCard(task, theme),
              const SizedBox(height: AppSpacing.md),

              // Equipment card
              if (_hasEquipment(task)) ...[
                _buildEquipmentCard(task, theme),
                const SizedBox(height: AppSpacing.md),
              ],

              // Photos card
              if (task.photos.isNotEmpty) ...[
                _buildPhotosCard(task, theme),
                const SizedBox(height: AppSpacing.md),
              ],

              // Review card (if reviewed)
              if (task.reviews != null && task.reviews!.isNotEmpty) ...[
                _buildReviewCard(task, theme),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(DailyTask task, FThemeData theme) {
    final statusColor = _getStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(26),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: statusColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(task.status), color: statusColor, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (task.durationMinutes != null)
                  Text(
                    'Durasi: ${task.durationMinutes} menit',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesCard(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.users, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'KARYAWAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: task.assignedEmployeeNames?.map((name) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: AppRadius.radiusSm,
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList() ?? [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  task.employeeName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoCard(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task name
          Text(
            task.itemName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
          ),
          if (task.itemDescription != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              task.itemDescription!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.mutedForeground,
              ),
            ),
          ],

          const Divider(height: AppSpacing.lg),

          // Area
          if (task.areaName != null) ...[
            _buildInfoRow(IconMap.locationOn, 'Area', task.areaName!, theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Target duration
          if (task.targetMinutes != null) ...[
            _buildInfoRow(IconMap.timer, 'Target', '${task.targetMinutes} menit', theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Assigned by
          if (task.assignedBy != null) ...[
            _buildInfoRow(IconMap.person, 'Ditugaskan oleh', task.assignedBy!, theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Assigned date
          if (task.assignedDate != null) ...[
            _buildInfoRow(IconMap.calendarToday, 'Tanggal', _formatDate(task.assignedDate!), theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Start/End time
          if (task.startAt != null) ...[
            _buildInfoRow(IconMap.playCircle, 'Mulai', _formatDateTime(task.startAt!), theme),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (task.endAt != null) ...[
            _buildInfoRow(IconMap.checkCircle, 'Selesai', _formatDateTime(task.endAt!), theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Notes
          if (task.notes != null && task.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(IconMap.editNote, size: 14, color: theme.colors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.flaskConical, size: 18, color: theme.colors.mutedForeground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'PERALATAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tools
          if (task.tools?.isNotEmpty ?? false) ...[
            _buildEquipmentSection('Alat', task.tools!, theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Chemicals
          if (task.chemicals?.isNotEmpty ?? false) ...[
            _buildEquipmentSection('Chemical', task.chemicals!, theme),
            const SizedBox(height: AppSpacing.sm),
          ],

          // PPEs
          if (task.ppes?.isNotEmpty ?? false) ...[
            _buildEquipmentSection('Alat Pelindung Diri', task.ppes!, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(String label, List<dynamic> items, FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: items.map((item) {
            final name = item is DailyTaskTool
                ? item.name
                : item is DailyTaskChemical
                    ? item.name
                    : item is DailyTaskPpe
                        ? item.name
                        : 'Unknown';
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colors.foreground,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotosCard(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.camera, size: 18, color: theme.colors.mutedForeground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'FOTO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: task.photos.length,
              itemBuilder: (ctx, i) {
                final photo = task.photos[i];
                return GestureDetector(
                  onTap: () => _showFullScreenPhoto(context, photo.url),
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(
                      right: i < task.photos.length - 1 ? AppSpacing.sm : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.radiusSm,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photo.url,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: theme.colors.muted,
                              child: Icon(
                                IconMap.brokenImage,
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                photo.type.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(DailyTask task, FThemeData theme) {
    final review = task.reviews!.first;
    final avg = review.averageScore ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(26),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.warning.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.star, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'REVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warning,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) => Icon(
                    IconMap.star,
                    size: 14,
                    color: i < avg.floor() ? AppColors.warning : theme.colors.mutedForeground,
                  )),
                ],
              ),
            ],
          ),
          if (review.notes != null && review.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.notes!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colors.foreground,
              ),
            ),
          ],
          if (review.scores.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...review.scores.map((s) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.criteriaName ?? 'Kriteria',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colors.foreground,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      IconMap.star,
                      size: 12,
                      color: i < s.score ? AppColors.warning : theme.colors.mutedForeground,
                    )),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, FThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colors.mutedForeground),
        const SizedBox(width: 6),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colors.foreground,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditOptions(BuildContext context) {
    final task = context.read<DailyTaskNotifier>().selectedTask;
    if (task == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(IconMap.pencil),
              title: const Text('Edit Tugas'),
              subtitle: const Text('Ubah detail tugas'),
              onTap: () {
                Navigator.pop(ctx);
                _editTask();
              },
            ),
            if (task.status == 'assigned' || task.status == 'in_progress')
              ListTile(
                leading: Icon(IconMap.trash, color: AppColors.danger),
                title: const Text('Hapus Tugas', style: TextStyle(color: AppColors.danger)),
                subtitle: const Text('Batalkan penugasan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTask();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editTask() {
    final task = context.read<DailyTaskNotifier>().selectedTask;
    if (task == null) return;

    // Build edit data from task
    final editData = {
      'id': task.id,
      'item_id': _getItemId(task),
      'item_name': task.itemName,
      'employees': _getEmployees(task),
      'target_minutes': task.targetMinutes,
      'notes': task.notes,
      'assigned_date': task.assignedDate?.toIso8601String().split('T')[0],
      'tools': task.tools?.map((t) => {'id': t.id, 'name': t.name}).toList(),
      'chemicals': task.chemicals?.map((c) => {'id': c.id, 'name': c.name}).toList(),
      'ppes': task.ppes?.map((p) => {'id': p.id, 'name': p.name}).toList(),
    };

    context.push('/daily-task-assignment/new', extra: editData);
  }

  int? _getItemId(DailyTask task) {
    // Try to get item_id from task - this might need to come from the API
    // For now, we'll use the itemName to find it in the loaded items
    final notifier = context.read<DailyTaskNotifier>();
    final item = notifier.items.firstWhere(
      (i) => i.name == task.itemName,
      orElse: () => DailyTaskMasterItem(id: 0, name: ''),
    );
    return item.id > 0 ? item.id : null;
  }

  List<Map<String, dynamic>> _getEmployees(DailyTask task) {
    if (task.assignedEmployeeNames != null) {
      // Get employee IDs from the loaded employees
      final notifier = context.read<DailyTaskNotifier>();
      return task.assignedEmployeeNames!.map((name) {
        final emp = notifier.mobileAssignEmployees.firstWhere(
          (e) => e['name'] == name,
          orElse: () => {'id': 0, 'name': name},
        );
        return {'id': emp['id'], 'name': emp['name']};
      }).toList();
    }
    return [];
  }

  void _confirmDeleteTask() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: const Text('Tugas akan dibatalkan. Karyawan tidak akan bisa mengerjakannya lagi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTask();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask() async {
    final notifier = context.read<DailyTaskNotifier>();
    final success = await notifier.deleteTask(widget.taskId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.error ?? 'Gagal menghapus tugas'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showFullScreenPhoto(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasEquipment(DailyTask task) {
    return (task.tools?.isNotEmpty ?? false) ||
        (task.chemicals?.isNotEmpty ?? false) ||
        (task.ppes?.isNotEmpty ?? false);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'reviewed':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Ditugaskan';
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return IconMap.schedule;
      case 'in_progress':
        return IconMap.loaderCircle;
      case 'completed':
        return IconMap.checkCircle;
      case 'reviewed':
        return IconMap.star;
      default:
        return IconMap.infoOutline;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    final date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

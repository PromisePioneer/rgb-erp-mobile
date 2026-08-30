import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/daily_task.dart';
import '../providers/daily_task_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Daily task list screen - shows today's tasks and history
class DailyTaskListScreen extends StatefulWidget {
  const DailyTaskListScreen({super.key});

  @override
  State<DailyTaskListScreen> createState() => _DailyTaskListScreenState();
}

class _DailyTaskListScreenState extends State<DailyTaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canAssignTask = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivilegesAndLoadData();
    });
  }

  Future<void> _checkPrivilegesAndLoadData() async {
    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.state.user;
    final canAssign = user?.hasPrivilege('daily_task_assign') ?? false;

    // Update state to trigger rebuild
    setState(() {
      _canAssignTask = canAssign;
    });

    final notifier = context.read<DailyTaskNotifier>();
    notifier.loadTodayTasks();
    notifier.loadHistory();

    // TL: also load their assigned tasks
    if (canAssign) {
      try {
        await notifier.getMyAssignments();
      } catch (e) {
        // Handle error silently or show a non-blocking notification
        debugPrint('Failed to load assignments: $e');
      }
    }
  }

  Future<void> _loadData() async {
    await _checkPrivilegesAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final authNotifier = context.watch<AuthNotifier>();
    final user = authNotifier.state.user;
    final canAssignTask = user?.hasPrivilege('daily_task_assign') ?? false;

    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Tugas Harian'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colors.primary,
          unselectedLabelColor: theme.colors.mutedForeground,
          indicatorColor: theme.colors.primary,
          tabs: const [
            Tab(text: 'Hari Ini'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTasksTab(
            onRefresh: _loadData,
            isTeamLeader: _canAssignTask,
          ),
          _HistoryTasksTab(onRefresh: _loadData),
        ],
      ),
      floatingActionButton: canAssignTask
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/daily-task-assignment/new'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Assign Tugas'),
            )
          : null,
    );
  }
}

class _TodayTasksTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isTeamLeader;

  const _TodayTasksTab({
    required this.onRefresh,
    required this.isTeamLeader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Consumer<DailyTaskNotifier>(
      builder: (context, notifier, child) {
        // Team Leader: show BOTH my tasks AND assigned tasks
        if (isTeamLeader) {
          return _buildTeamLeaderViewWithMyTasks(context, notifier, theme);
        }

        // Regular Employee: show own tasks
        if (notifier.isLoading && notifier.todayTasks.isEmpty) {
          return const Center(child: LoadingIndicator());
        }

        if (notifier.error != null && notifier.todayTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconMap.errorOutline,
                    size: 48, color: theme.colors.destructive),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gagal memuat tugas',
                  style: TextStyle(color: theme.colors.foreground),
                ),
                const SizedBox(height: AppSpacing.md),
                FButton(
                  onPress: onRefresh,
                  variant: FButtonVariant.outline,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (notifier.todayTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconMap.checkCircle,
                    size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tidak ada tugas hari ini',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifier.todayTasks.length,
            itemBuilder: (context, index) {
              final task = notifier.todayTasks[index];
              return _DailyTaskCard(
                task: task,
                onTap: () => context.push('/daily-task/${task.id}'),
              );
            },
          ),
        );
      },
    );
  }

  /// Build Team Leader view with BOTH my tasks and assigned tasks
  Widget _buildTeamLeaderViewWithMyTasks(
    BuildContext context,
    DailyTaskNotifier notifier,
    FThemeData theme,
  ) {
    final hasMyTasks = notifier.todayTasks.isNotEmpty;
    final hasAssignedTasks = notifier.assignments.isNotEmpty;
    final isLoading = notifier.isLoading;

    // If nothing loaded yet, show loading
    if (isLoading && !hasMyTasks && !hasAssignedTasks) {
      return const Center(child: LoadingIndicator());
    }

    // If nothing exists
    if (!hasMyTasks && !hasAssignedTasks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.work, size: 64, color: theme.colors.mutedForeground),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada tugas',
              style: TextStyle(
                fontSize: 16,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tekan tombol + untuk membuat tugas baru',
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // My Tasks Section (tasks assigned TO this user)
          if (hasMyTasks) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(IconMap.person, size: 18, color: theme.colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Tugas Saya',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${notifier.todayTasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...notifier.todayTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DailyTaskCard(
                task: task,
                onTap: () => context.push('/daily-task/${task.id}'),
              ),
            )),
            const SizedBox(height: AppSpacing.md),
          ],

          // Assigned Tasks Section (tasks assigned BY this user to others)
          if (hasAssignedTasks) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(IconMap.work, size: 18, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Tugas Karyawan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${notifier.assignments.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...notifier.assignments.map((assignment) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AssignedTaskCard(assignment: assignment),
            )),
          ],
        ],
      ),
    );
  }
}

class _AssignedTaskCard extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const _AssignedTaskCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    final employeeName = assignment['employee_name'] ?? 'Unknown';
    final itemName = assignment['item_name'] ?? assignment['item']?['name'] ?? '-';
    final areaName = assignment['area_name'] ?? assignment['area']?['name'] ?? '-';
    final status = assignment['status'] ?? 'assigned';
    final assignedDate = assignment['assigned_date'] ?? assignment['date'];
    final targetMinutes = assignment['target_minutes'];
    final notes = assignment['notes'];

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'assigned':
        statusColor = theme.colors.primary;
        statusLabel = 'Ditugaskan';
        statusIcon = IconMap.schedule;
        break;
      case 'in_progress':
        statusColor = AppColors.warning;
        statusLabel = 'Sedang Dikerjakan';
        statusIcon = IconMap.loaderCircle;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Selesai';
        statusIcon = IconMap.checkCircle;
        break;
      case 'reviewed':
        statusColor = AppColors.info;
        statusLabel = 'Direview';
        statusIcon = IconMap.star;
        break;
      default:
        statusColor = theme.colors.mutedForeground;
        statusLabel = status;
        statusIcon = IconMap.infoOutline;
    }

    final taskId = assignment['id'] as int;
    final canReview = status == 'completed';
    final reviewData = assignment['review'] as Map<String, dynamic>?;
    final isReviewed = status == 'reviewed';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          if (canReview) {
            context.push('/daily-task/$taskId/review', extra: assignment);
          } else if (isReviewed) {
            context.push('/daily-task/$taskId/review', extra: assignment);
          }
        },
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isReviewed && reviewData != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _buildReviewStars(reviewData, theme),
                  ],
                  const Spacer(),
                  Icon(
                    IconMap.chevronRight,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(IconMap.person, size: 16, color: theme.colors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      employeeName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(IconMap.person, size: 16, color: theme.colors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      employeeName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                itemName,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colors.foreground,
                ),
              ),
              if (areaName != '-') ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(IconMap.locationOn, size: 16, color: theme.colors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      areaName,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(IconMap.calendarToday, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    assignedDate ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  if (targetMinutes != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Icon(IconMap.timer, size: 16, color: theme.colors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      '$targetMinutes menit',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
              if (notes != null && notes.toString().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
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
                          notes.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colors.mutedForeground,
                          ),
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
  }

  Widget _buildReviewStars(Map<String, dynamic> reviewData, FThemeData theme) {
    final scores = reviewData['scores'] as List<dynamic>? ?? [];
    if (scores.isEmpty) return const SizedBox.shrink();

    double avg = 0;
    for (final s in scores) {
      avg += (s['score'] as int? ?? 0);
    }
    avg = scores.isNotEmpty ? avg / scores.length : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          avg.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 2),
        ...List.generate(5, (i) {
          if (i < avg.floor()) {
            return Icon(IconMap.star, size: 14, color: AppColors.warning);
          } else if (i < avg) {
            return Icon(IconMap.star, size: 14, color: AppColors.warning.withAlpha(128));
          } else {
            return Icon(IconMap.star, size: 14, color: theme.colors.mutedForeground);
          }
        }),
      ],
    );
  }
}

class _HistoryTasksTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HistoryTasksTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Consumer<DailyTaskNotifier>(
      builder: (context, notifier, child) {
        if (notifier.isLoading && notifier.historyTasks.isEmpty) {
          return const Center(child: LoadingIndicator());
        }

        if (notifier.historyTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconMap.hourglass, size: 64, color: theme.colors.mutedForeground),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum ada riwayat tugas',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifier.historyTasks.length,
            itemBuilder: (context, index) {
              final task = notifier.historyTasks[index];
              return _DailyTaskCard(
                task: task,
                onTap: () => context.push('/daily-task/${task.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _DailyTaskCard extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onTap;

  const _DailyTaskCard({
    required this.task,
    required this.onTap,
  });

  Color _getStatusColor(FThemeData theme) {
    switch (task.status) {
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

  IconData _getStatusIcon() {
    switch (task.status) {
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

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final statusColor = _getStatusColor(theme);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          task.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    IconMap.chevronRight,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                task.itemName,
                style: TextStyle(
                  fontSize: 16,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task.areaName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(IconMap.locationOn,
                        size: 16, color: theme.colors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      task.areaName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
              if (task.targetMinutes != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(IconMap.timer,
                        size: 16, color: theme.colors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${task.targetMinutes} menit',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
              if (task.startAt != null && task.endAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(IconMap.accessTime,
                        size: 16, color: theme.colors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      'Durasi: ${task.durationMinutes ?? '-'} menit',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../providers/notification_provider.dart';
import '../widgets/notification_item_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: theme.colors.primary,
        foregroundColor: theme.colors.primaryForeground,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return FButton(
                onPress: () => provider.markAllAsRead(),
                variant: FButtonVariant.ghost,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_all, color: theme.colors.primaryForeground, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Tandai semua baca',
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.primaryForeground,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat notifikasi',
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FButton(
                    onPress: () => provider.fetchNotifications(),
                    variant: FButtonVariant.primary,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi',
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return NotificationItemWidget(
                  notification: notification,
                  onTap: () async {
                    await provider.markAsRead(notification.id);
                    _handleNotificationTap(notification.type, notification.data);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'approval_request':
      case 'request_approved':
      case 'request_rejected':
        final approvalId = data['approval_id'];
        if (approvalId != null) {
          context.push('/approval/$approvalId');
        } else {
          context.go('/approval');
        }
        break;
      case 'patrol_alarm':
        context.go('/patrol');
        break;
      case 'shift_reminder':
        context.go('/attendance');
        break;
      case 'backup_offer':
      case 'backup_assigned':
      case 'backup_escalation':
        final scheduleId = data['schedule_id'];
        if (scheduleId != null) {
          context.push('/schedule-detail/$scheduleId');
        } else {
          context.go('/schedule');
        }
        break;
      case 'task_assigned':
      case 'task_started':
      case 'task_completed':
      case 'task_reviewed':
        final taskId = data['task_id'];
        if (taskId != null) {
          context.push('/daily-task/$taskId');
        } else {
          context.go('/daily-task');
        }
        break;
      default:
        // Do nothing for other types
        break;
    }
  }
}

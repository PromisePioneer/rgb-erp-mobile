import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isRead = notification.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? theme.colors.muted : theme.colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.typography.body.md.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.colors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(FThemeData theme) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'approval_request':
        icon = Icons.assignment_ind;
        color = theme.colors.primary;
        break;
      case 'request_approved':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'request_rejected':
        icon = Icons.cancel;
        color = theme.colors.error;
        break;
      case 'patrol_alarm':
        icon = Icons.warning;
        color = AppColors.warning;
        break;
      case 'shift_reminder':
        icon = Icons.access_time;
        color = theme.colors.primary;
        break;
      case 'backup_offer':
      case 'backup_assigned':
        icon = Icons.swap_horiz;
        color = AppColors.warning;
        break;
      case 'backup_escalation':
        icon = Icons.priority_high;
        color = theme.colors.error;
        break;
      case 'task_assigned':
        icon = Icons.task_alt;
        color = theme.colors.primary;
        break;
      case 'task_started':
        icon = Icons.play_circle;
        color = theme.colors.primary;
        break;
      case 'task_completed':
        icon = Icons.done_all;
        color = AppColors.success;
        break;
      case 'task_reviewed':
        icon = Icons.star;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.notifications;
        color = theme.colors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

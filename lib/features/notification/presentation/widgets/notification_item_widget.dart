import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../core/constants/app_constants.dart';

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
    final isRead = notification.isRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isRead ? 0 : 1,
      color: isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
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
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
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

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'approval_request':
        icon = Icons.assignment_ind;
        color = AppColors.info;
        break;
      case 'request_approved':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'request_rejected':
        icon = Icons.cancel;
        color = AppColors.danger;
        break;
      case 'patrol_alarm':
        icon = Icons.warning;
        color = AppColors.warning;
        break;
      case 'shift_reminder':
        icon = Icons.access_time;
        color = AppColors.info;
        break;
      case 'backup_offer':
      case 'backup_assigned':
        icon = Icons.swap_horiz;
        color = AppColors.warning;
        break;
      case 'backup_escalation':
        icon = Icons.priority_high;
        color = AppColors.danger;
        break;
      case 'task_assigned':
        icon = Icons.task_alt;
        color = AppColors.info;
        break;
      case 'task_started':
        icon = Icons.play_circle;
        color = AppColors.info;
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
        color = AppColors.rgbPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

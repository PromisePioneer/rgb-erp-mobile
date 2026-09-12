import 'package:flutter/material.dart';
import '../../domain/entities/client_notification_entity.dart';
import '../../../../core/core.dart';

/// Widget for displaying a single notification item
class ClientNotificationItemWidget extends StatelessWidget {
  final ClientNotificationEntity notification;
  final VoidCallback? onTap;

  const ClientNotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.info.withValues(alpha: 0.05),
          border: Border(
            left: BorderSide(
              color: isRead ? Colors.transparent : AppColors.rgbPrimary,
              width: 3,
            ),
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(notification.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(notification.iconEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.rgbPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeBadgeColor(notification.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getTypeBadgeColor(notification.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
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

  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case 'daily_task_assigned':
        return Colors.blue.shade50;
      case 'task_started':
        return Colors.orange.shade50;
      case 'task_ended':
        return Colors.green.shade50;
      case 'attendance_recorded':
        return Colors.purple.shade50;
      case 'progress_check':
        return Colors.teal.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getTypeBadgeColor(String type) {
    switch (type) {
      case 'daily_task_assigned':
        return Colors.blue.shade700;
      case 'task_started':
        return Colors.orange.shade700;
      case 'task_ended':
        return Colors.green.shade700;
      case 'attendance_recorded':
        return Colors.purple.shade700;
      case 'progress_check':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

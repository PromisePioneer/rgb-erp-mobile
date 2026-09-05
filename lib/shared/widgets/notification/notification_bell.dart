import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../features/notification/presentation/providers/notification_provider.dart';
import '../../../core/constants/app_constants.dart';

/// Notification bell widget with badge count
/// Can be added to AppBar actions
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined),
              if (provider.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _formatCount(provider.unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notifikasi',
          color: Colors.white,
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count > 99) return '99+';
    return count.toString();
  }
}

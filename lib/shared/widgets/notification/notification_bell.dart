import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../features/notification/presentation/providers/notification_provider.dart';

/// Notification bell widget with badge count
/// Can be added to AppBar actions
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Consumer<NotificationProvider?>(
      builder: (context, provider, _) {
        if (provider == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.notifications_outlined,
                  color: theme.colors.primaryForeground,
                  size: 24,
                ),
              ),
              if (provider.unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _formatCount(provider.unreadCount),
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.primaryForeground,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count > 99) return '99+';
    return count.toString();
  }
}

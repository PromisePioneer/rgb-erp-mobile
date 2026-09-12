import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/client_notification_entity.dart';
import '../providers/client_notification_provider.dart';
import '../widgets/client_notification_item_widget.dart';
import '../../../../core/core.dart';

/// Screen for displaying client notifications
class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() =>
      _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientNotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.rgbPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ClientNotificationProvider>(
            builder: (context, provider, _) {
              if (provider.hasUnread) {
                return TextButton(
                  onPressed: () => _markAllAsRead(context, provider),
                  child: const Text(
                    'Tandai semua dibaca',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ClientNotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.rgbPrimary),
            );
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Gagal memuat notifikasi',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.fetchNotifications(),
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
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi tentang aktivitas karyawan\nakan muncul di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: AppColors.rgbPrimary,
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return ClientNotificationItemWidget(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, ClientNotificationEntity notification) {
    if (!notification.isRead) {
      context.read<ClientNotificationProvider>().markAsRead(notification.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${notification.iconEmoji} ${notification.body}',
          maxLines: 2,
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tutup',
          onPressed: () {},
        ),
      ),
    );
  }

  void _markAllAsRead(
      BuildContext context, ClientNotificationProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tandai Semua Dibaca'),
        content: const Text(
            'Apakah Anda yakin ingin menandai semua notifikasi sebagai sudah dibaca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.markAllAsRead();
              Navigator.pop(dialogContext);
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Callback untuk foreground task - harus top-level function
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

/// Foreground Task Handler - menjaga app tetap jalan
class FirstTaskHandler extends TaskHandler {
  int _eventCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize notification for foreground service
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Setup notification channel untuk foreground service
    const androidNotificationDetails = AndroidNotificationDetails(
      'foreground_service',
      'Layanan Latar',
      channelDescription: 'RGB ERP sedang berjalan di latar belakang',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      enableVibration: false,
      playSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Show persistent notification
    await flutterLocalNotificationsPlugin.show(
      999,
      'RGB ERP Aktif',
      'Patroli & Absensi berjalan di latar belakang',
      notificationDetails,
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    _eventCount++;

    // Heartbeat - pastikan service masih hidup
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidNotificationDetails = AndroidNotificationDetails(
      'foreground_service',
      'Layanan Latar',
      channelDescription: 'RGB ERP sedang berjalan',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      enableVibration: false,
      playSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      'RGB ERP Aktif',
      'Patroli & Absensi berjalan',
      notificationDetails,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Cleanup
  }

  @override
  void onNotificationPressed() {
    // Buka app saat notification di-tap
    FlutterForegroundTask.launchApp();
  }
}

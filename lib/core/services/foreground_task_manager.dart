import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Manager for foreground service to keep app alive
class ForegroundTaskManager {
  static final ForegroundTaskManager _instance = ForegroundTaskManager._internal();
  factory ForegroundTaskManager() => _instance;
  ForegroundTaskManager._internal();

  bool _initialized = false;

  /// Initialize foreground task
  Future<void> init() async {
    if (_initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'RGB 86',
        channelDescription: 'App berjalan di background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
      ),
    );

    _initialized = true;
  }

  /// Start foreground service
  Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      notificationTitle: 'RGB 86',
      notificationText: 'App berjalan di background',
      callback: startCallback,
    );
  }

  /// Stop foreground service
  Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}

/// Start callback for foreground task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ExampleTaskHandler());
}

/// Example task handler
class ExampleTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Called when task starts
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called every repeat interval (if set)
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Called when task is destroyed
  }

  @override
  void onNotificationPressed() {
    // Called when notification is pressed
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Called when notification button is pressed
  }
}

/// Global instance
final foregroundTaskManager = ForegroundTaskManager();

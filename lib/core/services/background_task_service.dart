import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Nama task untuk WorkManager
const String periodicTaskName = 'rgb_erp_background_sync';

/// Callback dispatcher untuk WorkManager (HARUS @pragma)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[BackgroundTask] Task started: $task');

    try {
      if (task == periodicTaskName) {
        // Periodic sync task - jalankan setiap 15 menit
        await _performBackgroundSync();
      }
      return true;
    } catch (e) {
      debugPrint('[BackgroundTask] Error: $e');
      return false;
    }
  });
}

/// Task periodic yang dijalankan di background
Future<void> _performBackgroundSync() async {
  debugPrint('[BackgroundTask] Performing background sync...');

  // Disini bisa tambahkan logic sync data:
  // - Sync attendance data
  // - Sync patrol status
  // - Update location
  // - Check for new notifications

  // Contoh:
  // await syncAttendanceData();
  // await syncPatrolData();
  // await refreshNotifications();

  debugPrint('[BackgroundTask] Background sync completed');
}

/// Service untuk manage background tasks dan foreground service
class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  bool _isInitialized = false;
  bool _isForegroundServiceRunning = false;

  bool get isInitialized => _isInitialized;
  bool get isForegroundServiceRunning => _isForegroundServiceRunning;

  /// Initialize WorkManager dan Foreground Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[BackgroundTask] Initializing...');

    // 1. Initialize WorkManager
    await _initWorkManager();

    // 2. Initialize Foreground Service
    await _initForegroundService();

    // 3. Request battery optimization exemption
    await _requestBatteryOptimization();

    _isInitialized = true;
    debugPrint('[BackgroundTask] Initialization complete');
  }

  /// Initialize WorkManager untuk periodic background tasks
  Future<void> _initWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Register periodic task (minimum 15 menit di Android)
    await Workmanager().registerPeriodicTask(
      periodicTaskName,
      periodicTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false, // Tetap jalan walau battery low
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    debugPrint('[BackgroundTask] WorkManager initialized with periodic task');
  }

  /// Initialize Foreground Service dengan persistent notification
  Future<void> _initForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'rgb_erp_foreground',
        channelName: 'RGB ERP Running',
        channelDescription: 'Aplikasi RGB ERP sedang berjalan di background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start Foreground Service
  Future<void> startForegroundService() async {
    if (_isForegroundServiceRunning) return;

    if (await FlutterForegroundTask.isRunningService) {
      _isForegroundServiceRunning = true;
      return;
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'RGB ERP',
      notificationText: 'Aplikasi sedang berjalan di background',
    );

    if (result is ServiceRequestSuccess) {
      _isForegroundServiceRunning = true;
      debugPrint('[BackgroundTask] Foreground service started');
    } else {
      debugPrint('[BackgroundTask] Foreground service failed to start: $result');
    }
  }

  /// Stop Foreground Service
  Future<void> stopForegroundService() async {
    if (!_isForegroundServiceRunning) return;

    await FlutterForegroundTask.stopService();
    _isForegroundServiceRunning = false;
    debugPrint('[BackgroundTask] Foreground service stopped');
  }

  /// Restart Foreground Service (jika sudah berhenti)
  Future<void> restartForegroundService() async {
    await stopForegroundService();
    await startForegroundService();
  }

  /// Request battery optimization exemption
  Future<void> _requestBatteryOptimization() async {
    try {
      // Check if already ignored
      final isIgnored = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (isIgnored) {
        debugPrint('[BackgroundTask] Battery optimization already ignored');
        return;
      }

      // Request ignore battery optimization - akan muncul system dialog
      final granted = await FlutterForegroundTask.requestIgnoreBatteryOptimization();

      if (granted) {
        debugPrint('[BackgroundTask] Battery optimization exemption granted');
      } else {
        debugPrint('[BackgroundTask] Battery optimization exemption denied');
      }
    } catch (e) {
      debugPrint('[BackgroundTask] Battery optimization request failed: $e');
    }
  }

  /// Open battery optimization settings
  Future<void> openBatteryOptimizationSettings() async {
    await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    await stopForegroundService();
    debugPrint('[BackgroundTask] All tasks cancelled');
  }

  /// Get task status info
  Future<void> debugPrintTaskStatus() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    debugPrint('[BackgroundTask] Foreground service running: $isRunning');
    debugPrint('[BackgroundTask] WorkManager initialized: $_isInitialized');
  }
}

/// Global instance
final backgroundTaskService = BackgroundTaskService();

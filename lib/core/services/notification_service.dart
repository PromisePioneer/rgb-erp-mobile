import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../constants/app_constants.dart';
import '../di/injection.dart';
import 'storage_service.dart';

// Import PatrolNotifier for static callback
import '../../features/patrol/presentation/providers/patrol_provider.dart';

/// Model for a notification item
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String? type;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

/// Service for handling push notifications (FCM) and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  final AudioPlayer _alarmPlayer = AudioPlayer();

  NotificationApi? _notificationApi;
  StorageService? _storage;

  bool _isInitialized = false;
  bool _isAlarmPlaying = false;
  bool _isAlarmDismissed = false;
  bool _isRegisteringToken = false;

  /// List of received notifications
  final List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  /// Callback when patrol alarm is received (foreground only)
  void Function(String? message)? onPatrolAlarmReceived;

  /// Callback when shift reminder is received (foreground only)
  void Function(String? message, String? scheduleId)? onShiftReminderReceived;

  /// Callback when backup offer is received (foreground only)
  void Function(String? message, String? offerId, String? scheduleId)? onBackupOfferReceived;

  /// Callback when new notification is received
  void Function(NotificationItem)? onNotificationReceived;

  /// Initialize notification service
  /// Call this after Firebase.initializeApp() in main()
  Future<void> init({
    NotificationApi? notificationApi,
    StorageService? storage,
  }) async {
    if (_isInitialized) return;

    _notificationApi = notificationApi;
    _storage = storage;

    // Initialize timezone for scheduled notifications
    tz_data.initializeTimeZones();

    // Configure alarm audio player for looping
    await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    await _alarmPlayer.setVolume(1.0);

    // Setup local notifications
    await _initLocalNotifications();

    // Setup FCM handlers
    await _initFcm();

    _isInitialized = true;
  }

  /// Initialize local notifications plugin
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Create patrol alarm channel (Android only)
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'patrol_alarm',
        'Alarm Patroli',
        description: 'Notifikasi wajib patroli checkpoint berikutnya',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        // Note: custom sound requires file in android/app/src/main/res/raw/
        // If file not present, use default sound
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Create default channel for regular notifications (shift reminders, etc.)
      const defaultChannel = AndroidNotificationChannel(
        'default',
        'Notifikasi',
        description: 'Notifikasi umum',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(defaultChannel);

      // Create shift reminder channel (alarm-like notification)
      if (Platform.isAndroid) {
        const shiftReminderChannel = AndroidNotificationChannel(
          'shift_reminder',
          'Pengingat Shift',
          description: 'Pengingat jadwal shift kerja',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _localNotif
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(shiftReminderChannel);
      }
    }
  }

  /// Initialize FCM
  Future<void> _initFcm() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      
      // Permission denied - could show explanation in Settings screen
    }

    // Handle initial message (app opened from terminated state via notification)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleFcmTap(initialMessage);
    }

    // Handle when app is opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmTap);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen to token refresh (instance member)
    _fcm.onTokenRefresh.listen(_registerToken);
  }

  /// Handle foreground FCM message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    
    
    

    final data = message.data;
    final title = message.notification?.title ?? 'Notifikasi';
    final body = message.notification?.body ?? 'Pesan baru';

    final isPatrolAlarm = data['type'] == 'patrol_alarm';
    final isShiftReminder = data['type'] == 'shift_reminder';
    final isBackupOffer = data['type'] == 'backup_offer';

    // Check if this is a patrol alarm
    if (isPatrolAlarm && !_isAlarmDismissed) {
      
      _isAlarmPlaying = true;
      // Play looping alarm sound
      try {
        await _alarmPlayer.stop();
        await _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));
        
      } catch (e) {
        
      }

      // Navigate to alarm screen via static callback
      final alarmMessage = message.notification?.body ??
          'Waktunya patroli checkpoint berikutnya!';
      PatrolNotifier.onAlarmNavigated?.call(alarmMessage);
    }

    // Check if this is a shift reminder - play alarm like patrol
    if (isShiftReminder && !_isAlarmDismissed) {
      
      _isAlarmPlaying = true;
      // Play looping alarm sound
      try {
        await _alarmPlayer.stop();
        await _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));
      } catch (e) {
      }

      // Navigate to attendance screen via static callback
      final reminderMessage = message.notification?.body ??
          'Waktunya absen shift!';
      final scheduleId = data['schedule_id'];
      onShiftReminderReceived?.call(reminderMessage, scheduleId);
    }

    // Check if this is a backup offer notification
    if (isBackupOffer) {
      
      final offerId = data['backup_offer_id'];
      final scheduleId = data['schedule_id'];
      final offerMessage = message.notification?.body ??
          'Anda mendapat perintah backup!';

      // Stop alarm if playing
      _stopAlarmSound();

      // Trigger callback for backup offer
      onBackupOfferReceived?.call(offerMessage, offerId, scheduleId);
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: data['type'] ?? 'default',
      isAlarm: isPatrolAlarm || isShiftReminder,
      channelId: isPatrolAlarm
          ? 'patrol_alarm'
          : (isShiftReminder ? 'shift_reminder' : (isBackupOffer
          ? 'backup_offer'
          : 'default')),
    );

    // Add to notification list
    _addNotification(
      title: title,
      body: body,
      type: data['type'],
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isAlarm = false,
    String? channelId,
  }) async {
    final effectiveChannelId = channelId ?? (isAlarm ? 'default' : 'default');
    final isShiftReminder = effectiveChannelId == 'shift_reminder';
    final isPatrolAlarm = effectiveChannelId == 'patrol_alarm';
    final isBackupOffer = effectiveChannelId == 'backup_offer';

    final androidDetails = AndroidNotificationDetails(
      effectiveChannelId,
      isPatrolAlarm
          ? 'Alarm Patroli'
          : (isShiftReminder ? 'Pengingat Shift' : (isBackupOffer
          ? 'Backup Jaga'
          : 'Notifikasi')),
      channelDescription: isPatrolAlarm
          ? 'Notifikasi patroli checkpoint'
          : (isShiftReminder ? 'Pengingat jadwal shift' : (isBackupOffer
          ? 'Tawaran backup jaga'
          : 'Notifikasi umum')),
      importance: isAlarm ? Importance.max : Importance.high,
      priority: isAlarm ? Priority.high : Priority.high,
      ongoing: isAlarm,
      autoCancel: !isAlarm,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use appropriate notification ID based on type
    final notificationId = isShiftReminder
        ? AppConstants.shiftReminderNotificationId
        : (isPatrolAlarm
        ? AppConstants.patrolAlarmNotificationId
        : (isBackupOffer
        ? AppConstants.patrolAlarmNotificationId +
        1 // Different ID for backup offers
        : DateTime
        .now()
        .millisecondsSinceEpoch ~/ 1000));

    await _localNotif.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap (FCM - background/terminated)
  void _handleFcmTap(RemoteMessage message) {
    

    final type = message.data['type'];

    // Stop alarm sound for patrol alarms
    if (type == 'patrol_alarm') {
      _stopAlarmSound();
      _navigateToPatrol();
    } else if (type == 'shift_reminder') {
      // Stop alarm sound for shift reminders and navigate to attendance
      _stopAlarmSound();
      _navigateToAttendance();
    } else if (type == 'backup_offer') {
      // Navigate to backup offer screen
      _navigateToBackupOffer();
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == 'patrol_alarm') {
      // Stop alarm sound and navigate to patrol screen
      _stopAlarmSound();
      _navigateToPatrol();
    } else if (payload == 'shift_reminder') {
      // Stop alarm sound and navigate to shift response screen
      _stopAlarmSound();
      // Call the callback to load data and navigate (no scheduleId from local notification)
      onShiftReminderReceived?.call(null, null);
    } else if (payload == 'backup_offer') {
      // Stop alarm sound
      _stopAlarmSound();
      // Call the callback to load data and navigate
      onBackupOfferReceived?.call(null, null, null);
    } else {
      // Navigate to schedule screen for other notifications
      _navigateToSchedule();
    }
  }

  /// Stop alarm sound and reset state
  void _stopAlarmSound() {
    if (_isAlarmPlaying) {
      _alarmPlayer.stop();
      _isAlarmPlaying = false;
      _isAlarmDismissed = false; // Reset for next alarm
      
    }
  }

  /// Reset alarm dismissed state (call when patrol round is complete)
  void resetAlarmDismissed() {
    _isAlarmDismissed = false;
  }

  /// Navigate to patrol screen
  void _navigateToPatrol() {
    // This will be called from main.dart which handles actual navigation
    // We use a callback mechanism instead of directly accessing router
    
  }

  /// Navigate to schedule screen
  void _navigateToSchedule() {
    // This will be called from main.dart which handles actual navigation
    // We use a callback mechanism instead of directly accessing router
    
  }

  /// Navigate to attendance screen
  void _navigateToAttendance() {
    // This will be called from main.dart which handles actual navigation
    // We use a callback mechanism instead of directly accessing router
    
  }

  /// Navigate to backup offer screen
  void _navigateToBackupOffer() {
    // This will be called from main.dart which handles actual navigation
    // We use a callback mechanism instead of directly accessing router
    
  }

  /// Register FCM token with backend
  Future<void> _registerToken(String token) async {
    

    // Prevent multiple simultaneous registrations
    if (_isRegisteringToken) {
      return;
    }
    _isRegisteringToken = true;

    if (_notificationApi == null || _storage == null) {
      
      _isRegisteringToken = false;
      return;
    }

    try {
      // Get or generate device ID
      String? deviceId = await _storage!.deviceId;
      

      if (deviceId == null || deviceId.isEmpty) {
        deviceId = _generateDeviceId();
        await _storage!.setDeviceId(deviceId);
        
      } else {
        
      }

      // Determine platform
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // Register with backend
      await _notificationApi!.registerDeviceToken(
        token: token,
        platform: platform,
        deviceId: deviceId,
      );

      // Store token locally
      await _storage!.setFcmToken(token);

      
    } finally {
      _isRegisteringToken = false;
    }
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    return 'device_${DateTime
        .now()
        .millisecondsSinceEpoch}_${(DateTime
        .now()
        .microsecond % 10000).toString().padLeft(4, '0')}';
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return _fcm.getToken();
  }

  /// Register current token (call after login when user is authenticated)
  Future<void> registerCurrentToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      
    }
  }

  /// Unregister FCM token (call on logout)
  Future<void> unregisterToken() async {
    if (_notificationApi == null) return;

    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _notificationApi!.unregisterDeviceToken(token);
        if (_storage != null) {
          await _storage!.removeFcmToken();
        }
      }
    } catch (e) {
      
    }
  }

  /// Schedule patrol alarm notification
  Future<void> schedulePatrolAlarm({
    required DateTime scheduledTime,
    String? roundInfo,
  }) async {
    if (!_isInitialized) {
      
      return;
    }

    // Cancel any existing patrol alarm notification first
    await cancelPatrolAlarm();

    // Don't schedule if time is in the past
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'patrol_alarm',
      'Alarm Patroli',
      channelDescription: 'Notifikasi wajib patroli checkpoint berikutnya',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        roundInfo ??
            'Waktunya patroli checkpoint berikutnya! Segera lakukan scan checkpoint.',
        contentTitle: 'Alarm Patroli - Checkpoint Berikutnya',
        summaryText: 'Patroli',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotif.zonedSchedule(
      AppConstants.patrolAlarmNotificationId,
      'Alarm Patroli',
      roundInfo ?? 'Waktunya patroli checkpoint berikutnya!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'patrol_alarm',
    );

    
  }

  /// Cancel patrol alarm notification
  Future<void> cancelPatrolAlarm() async {
    await _localNotif.cancel(AppConstants.patrolAlarmNotificationId);
    
  }

  /// Show immediate patrol alarm notification
  Future<void> _showPatrolAlarmNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'patrol_alarm',
      'Alarm Patroli',
      channelDescription: 'Notifikasi wajib patroli checkpoint berikutnya',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotif.show(
      AppConstants.patrolAlarmNotificationId,
      title,
      body,
      details,
      payload: 'patrol_alarm',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _localNotif.cancelAll();
  }

  /// Request notification permission (for Android 13+)
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final android = _localNotif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final android = _localNotif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
    }
    return true;
  }

  /// Stop alarm sound (call this when user dismisses alarm)
  Future<void> stopAlarm() async {
    _stopAlarmSound();
  }

  /// Check if alarm is currently playing
  bool get isAlarmPlaying => _isAlarmPlaying;

  /// Get count of unread notifications
  int get unreadCount =>
      _notifications
          .where((n) => !n.isRead)
          .length;

  /// Add a notification to the list
  void _addNotification({
    required String title,
    required String body,
    String? type,
  }) {
    final item = NotificationItem(
      id: DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, item);
    onNotificationReceived?.call(item);
  }

  /// Mark a notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        timestamp: _notifications[index].timestamp,
        isRead: true,
      );
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = NotificationItem(
        id: _notifications[i].id,
        title: _notifications[i].title,
        body: _notifications[i].body,
        type: _notifications[i].type,
        timestamp: _notifications[i].timestamp,
        isRead: true,
      );
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  /// Clear old notifications (older than 7 days)
  void clearOld() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoff));
  }
}

/// Top-level background handler for FCM (REQUIRED to be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If Firebase is not yet initialized, initialize it
  // This is called when app is in background/terminated
  final type = message.data['type'];

  // Handle patrol alarm if it's a patrol notification
  if (type == 'patrol_alarm') {
    
    // Background handler - notification will be shown by system
    // Just log for now
  }

  // Handle shift reminder - also shows as alarm notification
  if (type == 'shift_reminder') {
    
    // Background handler - notification will be shown by system
    // Just log for now
  }

  // Handle backup offer
  if (type == 'backup_offer') {
    
    // Background handler - notification will be shown by system
    // Just log for now
  }
}

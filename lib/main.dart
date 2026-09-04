import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forui/forui.dart';

import 'core/core.dart';
import 'core/theme/app_ftheme.dart';
import 'core/services/notification_dialog_handler.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/attendance/presentation/providers/attendance_provider.dart';
import 'features/face_enrollment/presentation/providers/face_enrollment_provider.dart';
import 'features/patrol/presentation/providers/patrol_provider.dart';
import 'features/schedule/presentation/providers/schedule_provider.dart';
import 'features/payroll/presentation/providers/payroll_provider.dart';
import 'features/leave/presentation/providers/leave_provider.dart';
import 'features/panic/presentation/providers/panic_provider.dart';
import 'features/violation_report/presentation/providers/violation_report_provider.dart';
import 'features/report/presentation/providers/report_provider.dart';
import 'features/daily_task/data/repositories/daily_task_repository.dart';
import 'features/daily_task/presentation/providers/daily_task_provider.dart';
import 'features/client/presentation/providers/client_dashboard_provider.dart';
import 'features/client/presentation/providers/client_attendance_provider.dart';
import 'features/client/presentation/providers/client_reports_provider.dart';
import 'features/client/presentation/providers/client_schedule_provider.dart';
import 'navigation/app_router.dart';

/// Global notification service instance
final notificationService = globalNotificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (optional, will fallback to defaults)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    
  }

  // Initialize environment configuration
  await EnvironmentConfig.init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Foreground service disabled for now (causes crash)
  // await foregroundTaskManager.init();
  // await foregroundTaskManager.startService();

  // Register background message handler (REQUIRED - for FCM when app is killed)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Create services
  final storageService = StorageService();
  final locationService = LocationService();
  final biometricService = BiometricService();

  // Create Dio with proper configuration
  final apiFactory = ApiClientFactory(storage: storageService);
  final dio = apiFactory.create();

  // Create notification API
  final notificationApi = NotificationApi(dio);

  // Initialize notification service (FCM + local notifications)
  
  await notificationService.init(notificationApi: notificationApi, storage: storageService);
  
  
  final fcmToken = await notificationService.getToken();
  

  // Create repositories
  final authRepository = AuthRepository(
    api: AuthApi(dio),
    storage: storageService,
    biometric: biometricService,
  );

  // Create notifiers
  final authNotifier = AuthNotifier(authRepository);

  // Initialize router with auth notifier
  initRouter(authNotifier);

  // Setup notification service alarm callback
  notificationService.onPatrolAlarmReceived = (message) {
    
    // Trigger patrol provider alarm alert
    // Note: PatrolNotifier will be lazily created, but we use static callback for navigation
  };

  // Setup global alarm navigation callback
  _setupAlarmNavigation();

  // Setup notification tap handler to navigate to patrol screen
  _setupNotificationNavigation();

  runApp(
    MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),

        // Attendance Provider (lazy loaded)
        ChangeNotifierProvider<AttendanceNotifier>(
          create: (_) => AttendanceNotifier(
            createAttendanceRepository(dio),
            locationService,
          ),
        ),

        // Face Enrollment Provider (lazy loaded)
        ChangeNotifierProvider<FaceEnrollmentNotifier>(
          create: (_) => FaceEnrollmentNotifier(
            createFaceEnrollmentRepository(dio),
          ),
        ),

        // Patrol Provider (lazy loaded)
        ChangeNotifierProvider<PatrolNotifier>(
          create: (_) => PatrolNotifier(
            createPatrolRepository(dio),
            locationService,
            notificationService: notificationService,
          ),
        ),

        // Schedule Provider (lazy loaded)
        ChangeNotifierProvider<ScheduleNotifier>(
          create: (_) => ScheduleNotifier(
            createScheduleRepository(dio),
          ),
        ),

        // Payroll Provider (lazy loaded)
        ChangeNotifierProvider<PayrollNotifier>(
          create: (_) => PayrollNotifier(
            createPayrollRepository(dio),
          ),
        ),

        // Leave Provider (lazy loaded)
        ChangeNotifierProvider<LeaveNotifier>(
          create: (_) => LeaveNotifier(
            createLeaveRepository(dio),
          ),
        ),

        // Panic Alert Provider (lazy loaded)
        ChangeNotifierProvider<PanicNotifier>(
          create: (_) => PanicNotifier(
            createPanicRepository(dio),
          ),
        ),

        // Violation Report Provider (lazy loaded)
        ChangeNotifierProvider<ViolationReportNotifier>(
          create: (_) => ViolationReportNotifier(
            createViolationReportRepository(dio),
            locationService,
          ),
        ),

        // Report Provider (lazy loaded)
        ChangeNotifierProvider<ReportNotifier>(
          create: (_) => ReportNotifier(
            createReportRepository(dio),
            locationService,
          ),
        ),

        // Daily Task Provider (lazy loaded)
        ChangeNotifierProvider<DailyTaskNotifier>(
          create: (_) => DailyTaskNotifier(
            createDailyTaskRepository(dio),
          ),
        ),

        // Client Dashboard Provider (lazy loaded)
        ChangeNotifierProvider<ClientDashboardNotifier>(
          create: (_) => ClientDashboardNotifier(
            ClientApi(dio),
          ),
        ),

        // Client Attendance Provider (lazy loaded)
        ChangeNotifierProvider<ClientAttendanceNotifier>(
          create: (_) => ClientAttendanceNotifier(
            ClientApi(dio),
          ),
        ),

        // Client Reports Provider (lazy loaded)
        ChangeNotifierProvider<ClientReportsNotifier>(
          create: (_) => ClientReportsNotifier(
            ClientApi(dio),
          ),
        ),

        // Client Schedule Provider (lazy loaded)
        ChangeNotifierProvider<ClientScheduleNotifier>(
          create: (_) => ClientScheduleNotifier(
            ClientApi(dio),
          ),
        ),
      ],
      child: const RGBERPApp(),
    ),
  );
}

/// Setup global alarm navigation callback
void _setupAlarmNavigation() {
  
  // Import PatrolNotifier and set global navigation callback
  // This allows navigation to alarm screen from anywhere
  PatrolNotifier.onAlarmNavigated = (message) {
    
    _navigateToAlarm(message ?? 'Waktunya patroli checkpoint berikutnya!');
  };

  // Setup shift reminder notification callback - show dialog
  notificationService.onShiftReminderReceived = (message, scheduleId) {
    
    notificationDialogHandler.handleShiftReminderNotification(message: message, scheduleId: scheduleId);
  };

  // Setup backup offer notification callback - show dialog
  notificationService.onBackupOfferReceived = (message, offerId, scheduleId) {
    
    notificationDialogHandler.handleBackupOfferNotification(
      message: message,
      offerId: offerId,
      scheduleId: scheduleId,
    );
  };
}

/// Setup notification tap navigation
void _setupNotificationNavigation() {
  // Handle when app is opened from terminated state via notification
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      final type = message.data['type'];
      if (type == 'patrol_alarm') {
        _navigateToPatrol();
      } else if (type == 'shift_reminder') {
        _navigateToAttendance(null);
      } else {
        _navigateToSchedule();
      }
    }
  });

  // Handle when app is opened from background via notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final type = message.data['type'];
    if (type == 'patrol_alarm') {
      _navigateToPatrol();
    } else if (type == 'shift_reminder') {
      _navigateToAttendance(null);
    } else {
      _navigateToSchedule();
    }
  });
}

/// Navigate to patrol screen
void _navigateToPatrol() {
  try {
    appRouterProvider.go('/patrol');
  } catch (e) {
    // Router not yet initialized, ignore
  }
}

/// Navigate to patrol alarm screen
void _navigateToAlarm(String message) {
  
  try {
    final encodedMsg = Uri.encodeComponent(message);
    
    appRouterProvider.push('/patrol/alarm?message=$encodedMsg');
  } catch (e) {
    
  }
}

/// Navigate to schedule screen
void _navigateToSchedule() {
  
  try {
    appRouterProvider.go('/schedule');
  } catch (e) {
    
  }
}

/// Navigate to attendance screen
void _navigateToAttendance(String? message) {
  
  try {
    if (message != null) {
      final encodedMsg = Uri.encodeComponent(message);
      appRouterProvider.push('/attendance?message=$encodedMsg');
    } else {
      appRouterProvider.go('/attendance');
    }
  } catch (e) {
    
  }
}

class RGBERPApp extends StatefulWidget {
  const RGBERPApp({super.key});

  @override
  State<RGBERPApp> createState() => _RGBERPAppState();
}

class _RGBERPAppState extends State<RGBERPApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification dialog handler
    notificationDialogHandler.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RGB 86',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouterProvider,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return FTheme(
          data: AppFTheme.light,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

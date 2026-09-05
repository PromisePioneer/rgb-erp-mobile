import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../shared/utils/tutorial_keys.dart';

// Features imports
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/client/presentation/screens/client_dashboard_screen.dart';
import '../features/client/presentation/screens/client_attendance_screen.dart';
import '../features/client/presentation/screens/client_reports_screen.dart';
import '../features/client/presentation/screens/client_employee_list_screen.dart';
import '../features/client/presentation/screens/client_area_list_screen.dart';
import '../features/client/presentation/screens/client_schedule_screen.dart';
import '../features/hr_dashboard/presentation/screens/hr_dashboard_screen.dart';
import '../features/hr_dashboard/presentation/screens/edit_menu_screen.dart';
import '../features/leave/presentation/screens/leave_form_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/change_password_screen.dart';
import '../features/attendance/presentation/screens/attendance_home_screen.dart';
import '../features/attendance/presentation/screens/attendance_capture_screen.dart';
import '../features/attendance/presentation/screens/shift_response_screen.dart';
import '../features/attendance/presentation/screens/backup_offer_screen.dart';
import '../features/face_enrollment/presentation/screens/face_enrollment_status_screen.dart';
import '../features/face_enrollment/presentation/screens/face_enrollment_capture_screen.dart';
import '../features/patrol/presentation/screens/patrol_home_screen.dart';
import '../features/patrol/presentation/screens/patrol_scanner_screen.dart';
import '../features/patrol/presentation/screens/patrol_alarm_screen.dart';
import '../features/for_you/presentation/screens/for_you_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';
import '../features/payroll/presentation/screens/payroll_screen.dart';
import '../features/payroll/presentation/screens/payroll_detail_screen.dart';
import '../features/leave/presentation/screens/leave_screen.dart';
import '../features/purchase_request/presentation/screens/purchase_request_screen.dart';
import '../features/purchase_request/presentation/screens/purchase_request_form_screen.dart';
import '../features/purchase_request/presentation/screens/purchase_request_detail_screen.dart';
import '../features/violation_report/presentation/screens/violation_report_form_screen.dart';
import '../features/violation_report/presentation/screens/violation_report_history_screen.dart';
import '../features/violation_report/presentation/screens/violation_report_detail_screen.dart';
import '../features/report/presentation/screens/report_list_screen.dart';
import '../features/report/presentation/screens/report_form_screen.dart';
import '../features/daily_task/presentation/screens/daily_task_list_screen.dart';
import '../features/daily_task/presentation/screens/task_detail_screen.dart';
import '../features/daily_task/presentation/screens/task_detail_leader_screen.dart';
import '../features/daily_task/presentation/screens/task_review_screen.dart';
import '../features/daily_task/presentation/screens/task_assignment_list_screen.dart';
import '../features/daily_task/presentation/screens/task_assignment_form_screen.dart';
import '../features/approval/presentation/screens/approval_list_screen.dart';
import '../features/approval/presentation/screens/approval_detail_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';

// Navigation imports
import '../shared/widgets/navigation/app_bottom_nav.dart';

// Tutorial imports
import '../core/services/onboarding_service.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Global router provider that will be initialized in main.dart
GoRouter? _router;

GoRouter get appRouterProvider {
  if (_router == null) {
    throw Exception('Router not initialized. Call initRouter() first.');
  }
  return _router!;
}

void initRouter(AuthNotifier authNotifier) {
  _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.state.isAuthenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';

      if (isOnSplash) return null;

      if (!isLoggedIn && !isOnLogin) {
        return '/login';
      }

      if (isLoggedIn && isOnLogin) {
        // Auto-detect destination based on user type
        final isClient = authNotifier.state.isClient;
        return isClient ? '/client/dashboard' : '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // ===== INDEXED BRANCHES (shown in bottom nav) =====
          // Branch 0: Dashboard (Home tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const HRDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Attendance (Presensi tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                name: 'attendance',
                builder: (context, state) => const AttendanceHomeScreen(),
              ),
            ],
          ),
          // Branch 2: For You (For You tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/for-you',
                name: 'for-you',
                builder: (context, state) => const ForYouScreen(),
              ),
            ],
          ),
          // Branch 3: Settings (Akun tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),

          // ===== NON-INDEXED BRANCHES (hidden in bottom nav, but still inside shell) =====
          // Branch 4: Daily Task - ALL related routes nested under one parent
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/daily-task',
                name: 'daily-task',
                builder: (context, state) => const DailyTaskListScreen(),
                routes: [
                  // Employee task detail - with actions
                  GoRoute(
                    path: ':id',
                    name: 'daily-task-detail',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      final isLeader = state.extra as bool? ?? false;
                      if (isLeader) {
                        return TaskDetailLeaderScreen(taskId: id);
                      }
                      return TaskDetailScreen(taskId: id);
                    },
                    routes: [
                      // Nested route for task review
                      GoRoute(
                        path: 'review',
                        name: 'task-review',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          final taskData = state.extra as Map<String, dynamic>?;
                          if (taskData == null) {
                            return const Scaffold(
                              body: Center(child: Text('Data tugas tidak ditemukan')),
                            );
                          }
                          return TaskReviewScreen(taskId: id, taskData: taskData);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 7: Task Assignment List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/daily-task-assignment/list',
                name: 'task-assignment-list',
                builder: (context, state) => const TaskAssignmentListScreen(),
              ),
            ],
          ),
          // Branch 8: Task Assignment Form
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/daily-task-assignment/new',
                name: 'task-assignment-new',
                builder: (context, state) {
                  final editData = state.extra as Map<String, dynamic>?;
                  return TaskAssignmentFormScreen(editData: editData);
                },
              ),
            ],
          ),
          // Branch 9: Report List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report',
                name: 'report',
                builder: (context, state) => const ReportListScreen(),
              ),
            ],
          ),
          // Branch 10: Report Form
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report/form',
                name: 'report-form',
                builder: (context, state) => const ReportFormScreen(),
              ),
            ],
          ),
          // Branch 11: Edit Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/edit-menu',
                name: 'edit-menu',
                builder: (context, state) => const EditMenuScreen(),
              ),
            ],
          ),
          // Branch 12: Shift Response
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance/shift-response',
                name: 'shift-response',
                builder: (context, state) {
                  final shiftId = state.uri.queryParameters['shiftId'] ?? '';
                  return ShiftResponseScreen(shiftId: shiftId);
                },
              ),
            ],
          ),
          // Branch 13: Backup Offer
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance/backup-offer',
                name: 'backup-offer',
                builder: (context, state) {
                  final offerId = state.uri.queryParameters['offerId'] ?? '';
                  return BackupOfferScreen(offerId: offerId);
                },
              ),
            ],
          ),
          // Branch 14: Violation Report - ALL related routes nested under one parent
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/violation-report',
                name: 'violation-report',
                builder: (context, state) => const ViolationReportHistoryScreen(),
                routes: [
                  // Nested parameterized route for violation detail
                  GoRoute(
                    path: ':id',
                    name: 'violation-report-detail',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ViolationReportDetailScreen(violationId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 15: Violation Report Form
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/violation-report/form',
                name: 'violation-report-form',
                builder: (context, state) => const ViolationReportFormScreen(),
              ),
            ],
          ),
          // Branch 16: Change Password
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/change-password',
                name: 'change-password',
                builder: (context, state) => const ChangePasswordScreen(),
              ),
            ],
          ),
          // Branch 17: Face Enrollment
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/face-enrollment',
                name: 'face-enrollment',
                builder: (context, state) => const FaceEnrollmentStatusScreen(),
              ),
            ],
          ),
          // Branch 18: Patrol
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patrol',
                name: 'patrol',
                builder: (context, state) => const PatrolHomeScreen(),
              ),
            ],
          ),
          // Branch 19: Schedule
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                name: 'schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          // Branch 20: Payroll
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payroll',
                name: 'payroll',
                builder: (context, state) => const PayrollScreen(),
              ),
            ],
          ),
          // Branch 21: Payroll Detail
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payroll/detail',
                name: 'payroll-detail',
                builder: (context, state) {
                  final payslip = state.extra as dynamic;
                  return PayrollDetailScreen(payslip: payslip);
                },
              ),
            ],
          ),
          // Branch 22: Leave
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leave',
                name: 'leave',
                builder: (context, state) => const LeaveScreen(),
              ),
            ],
          ),
          // Branch 23: Leave Form
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leave/form',
                name: 'leave-form',
                builder: (context, state) => const LeaveFormScreen(),
              ),
            ],
          ),
          // Branch 24: Purchase Request List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/purchase-request',
                name: 'purchase-request',
                builder: (context, state) => const PurchaseRequestScreen(),
                routes: [
                  // Form route MUST be before parameterized route
                  GoRoute(
                    path: 'form',
                    name: 'purchase-request-form',
                    builder: (context, state) {
                      final editId = state.uri.queryParameters['edit'];
                      return PurchaseRequestFormScreen(
                        editId: editId != null ? int.tryParse(editId) : null,
                      );
                    },
                  ),
                  // Detail route - only match numeric IDs
                  GoRoute(
                    path: ':id',
                    name: 'purchase-request-detail',
                    builder: (context, state) {
                      final idParam = state.pathParameters['id'];
                      final id = int.tryParse(idParam ?? '');
                      if (id == null) {
                        return const Scaffold(
                          body: Center(child: Text('ID tidak valid')),
                        );
                      }
                      return PurchaseRequestDetailScreen(purchaseRequestId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Approval routes (outside shell - full screen)
      GoRoute(
        path: '/approval',
        name: 'approval-list',
        builder: (context, state) => const ApprovalListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'approval-detail',
            builder: (context, state) {
              final approval = state.extra as dynamic;
              if (approval == null) {
                return const Scaffold(
                  body: Center(child: Text('Data approval tidak ditemukan')),
                );
              }
              return ApprovalDetailScreen(approval: approval);
            },
          ),
        ],
      ),

      // Notification route (outside shell - full screen)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),

      // Immersive/Modal routes (outside shell, full-screen without bottom nav)
      GoRoute(
        path: '/client/dashboard',
        name: 'client-dashboard',
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/client/employees',
        name: 'client-employees',
        builder: (context, state) => const ClientEmployeeListScreen(),
      ),
      GoRoute(
        path: '/client/areas',
        name: 'client-areas',
        builder: (context, state) => const ClientAreaListScreen(),
      ),
      GoRoute(
        path: '/client/attendance',
        name: 'client-attendance',
        builder: (context, state) => const ClientAttendanceScreen(),
      ),
      GoRoute(
        path: '/client/tasks',
        name: 'client-tasks',
        builder: (context, state) => const ClientReportsScreen(reportType: 'tasks'),
      ),
      GoRoute(
        path: '/client/patrol',
        name: 'client-patrol',
        builder: (context, state) => const ClientReportsScreen(reportType: 'patrol'),
      ),
      GoRoute(
        path: '/client/field-reports',
        name: 'client-field-reports',
        builder: (context, state) => const ClientReportsScreen(reportType: 'field'),
      ),
      GoRoute(
        path: '/client/schedules',
        name: 'client-schedules',
        builder: (context, state) => const ClientScheduleScreen(),
      ),

      // Full-screen camera routes (outside shell - no bottom nav)
      GoRoute(
        path: '/attendance/capture',
        name: 'attendance-capture',
        builder: (context, state) => const AttendanceCaptureScreen(),
      ),
      GoRoute(
        path: '/face-enrollment/capture',
        name: 'face-enrollment-capture',
        builder: (context, state) => const FaceEnrollmentCaptureScreen(),
      ),
      GoRoute(
        path: '/patrol/scan',
        name: 'patrol-scan',
        builder: (context, state) => const PatrolScannerScreen(),
      ),
      GoRoute(
        path: '/patrol/alarm',
        name: 'patrol-alarm',
        builder: (context, state) {
          final message =
              state.uri.queryParameters['message'] ??
              'Waktunya patroli checkpoint berikutnya!';
          return PatrolAlarmScreen(message: message);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Main shell with bottom navigation bar
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final OnboardingService _onboardingService = OnboardingService(
    StorageService(),
  );
  bool _hasShownOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  Future<void> _checkAndShowOnboarding() async {
    if (_hasShownOnboarding) return;

    final hasSeen = await _onboardingService.hasSeenOnboarding();
    if (hasSeen) {
      _hasShownOnboarding = true;
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final targets = _buildTutorialTargets();

    if (targets.isEmpty) {
      _hasShownOnboarding = true;
      return;
    }

    _showTutorial(targets);
  }

  List<TargetFocus> _buildTutorialTargets() {
    final targets = <TargetFocus>[];

    if (TutorialKeys.menuGridKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'menuGrid',
        keyTarget: TutorialKeys.menuGridKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialCard(
              'Menu Layanan',
              'Akses semua fitur aplikasi dari sini.',
            ),
          ),
        ],
      ));
    }

    if (TutorialKeys.notificationKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'notification',
        keyTarget: TutorialKeys.notificationKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialCard(
              'Notifikasi',
              'Lihat notifikasi dan pengumuman penting.',
            ),
          ),
        ],
      ));
    }

    if (TutorialKeys.scanButtonKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'scanButton',
        keyTarget: TutorialKeys.scanButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialCard(
              'Tombol Scan',
              'Tekan untuk scan wajah saat absen.',
            ),
          ),
        ],
      ));
    }

    if (TutorialKeys.panicButtonKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'panicButton',
        keyTarget: TutorialKeys.panicButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialCard(
              'Tombol Panic / SOS',
              'Tekan dan tahan 3 detik saat darurat.',
            ),
          ),
        ],
      ));
    }

    if (TutorialKeys.homeKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'homeTab',
        keyTarget: TutorialKeys.homeKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialCard('Tab Home', 'Kembali ke dashboard.'),
          ),
        ],
      ));
    }

    if (TutorialKeys.presensiKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'presensiTab',
        keyTarget: TutorialKeys.presensiKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialCard('Tab Absensi', 'Catat kehadiran.'),
          ),
        ],
      ));
    }

    if (TutorialKeys.forYouKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'forYouTab',
        keyTarget: TutorialKeys.forYouKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialCard('Tab For You', 'Konten personalisasi.'),
          ),
        ],
      ));
    }

    if (TutorialKeys.akunKey.currentContext != null) {
      targets.add(TargetFocus(
        identify: 'akunTab',
        keyTarget: TutorialKeys.akunKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialCard('Tab Akun', 'Kelola akun Anda.'),
          ),
        ],
      ));
    }

    return targets;
  }

  Widget _buildTutorialCard(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppColors.slate600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showTutorial(List<TargetFocus> targets) {
    if (!mounted || targets.isEmpty) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primary.withAlpha(179),
      textSkip: 'LEWATI',
      textStyleSkip: const TextStyle(
        color: AppColors.slate700,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {
        _onboardingService.markOnboardingSeen();
        _hasShownOnboarding = true;
      },
      onSkip: () {
        _onboardingService.markOnboardingSeen();
        _hasShownOnboarding = true;
        return true;
      },
    ).show(context: context);

    _hasShownOnboarding = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _getNavIndex(),
        onTap: (index) => _onTabTapped(index),
        homeKey: TutorialKeys.homeKey,
        presensiKey: TutorialKeys.presensiKey,
        forYouKey: TutorialKeys.forYouKey,
        akunKey: TutorialKeys.akunKey,
        scanButtonKey: TutorialKeys.scanButtonKey,
      ),
      extendBody: true,
    );
  }

  int _getNavIndex() {
    // Branches 0-3 are indexed (shown in bottom nav)
    if (widget.navigationShell.currentIndex < 4) {
      return widget.navigationShell.currentIndex;
    }

    // For non-indexed branches (4+), detect which tab should be active
    final path = _getCurrentPath();

    // Dashboard tab routes
    if (_isDashboardRoute(path)) {
      return 0;
    }
    // Attendance tab routes
    if (_isAttendanceRoute(path)) {
      return 1;
    }
    // For You tab routes
    if (_isForYouRoute(path)) {
      return 2;
    }
    // Settings tab routes
    if (_isSettingsRoute(path)) {
      return 3;
    }

    // Default to first tab
    return 0;
  }

  String _getCurrentPath() {
    try {
      final router = GoRouter.of(context);
      final config = router.routerDelegate.currentConfiguration;
      return config.uri.toString();
    } catch (_) {
      return '';
    }
  }

  bool _isDashboardRoute(String path) =>
      path.startsWith('/daily-task') ||
      path.startsWith('/daily-task-assignment') ||
      path.startsWith('/report') ||
      path == '/edit-menu';

  bool _isAttendanceRoute(String path) =>
      path.startsWith('/attendance/shift-response') ||
      path.startsWith('/attendance/backup-offer');

  bool _isForYouRoute(String path) =>
      path.startsWith('/violation-report');

  bool _isSettingsRoute(String path) =>
      path == '/change-password';

  void _onTabTapped(int index) {
    // Only handle tabs 0-3
    if (index < 4) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index != widget.navigationShell.currentIndex,
      );
    }
  }
}

/// Splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    try {
      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.hydrate().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    } catch (_) {}

    if (!mounted) return;

    final authNotifier = context.read<AuthNotifier>();
    final isAuthenticated = authNotifier.state.isAuthenticated;
    final isClient = authNotifier.state.isClient;

    String destination;
    if (isAuthenticated) {
      destination = isClient ? '/client/dashboard' : '/dashboard';
    } else {
      destination = '/login';
    }

    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.go(destination);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(borderRadius: AppRadius.radiusXl),
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                child: Image(
                  image: AssetImage('assets/images/rajawali.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'RGB ERP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Forgot password screen placeholder
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: const Center(child: Text('Forgot Password Screen - Coming Soon')),
    );
  }
}

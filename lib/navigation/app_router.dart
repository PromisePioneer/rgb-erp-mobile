import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../shared/utils/tutorial_keys.dart';

// Features imports
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/hr_dashboard/presentation/screens/hr_dashboard_screen.dart';
import '../features/hr_dashboard/presentation/screens/edit_menu_screen.dart';
import '../features/leave/presentation/screens/leave_form_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/change_password_screen.dart';
import '../features/attendance/presentation/screens/attendance_home_screen.dart';
import '../features/face_enrollment/presentation/screens/face_enrollment_status_screen.dart';
import '../features/face_enrollment/presentation/screens/face_enrollment_capture_screen.dart';
import '../features/attendance/presentation/screens/attendance_capture_screen.dart';
import '../features/patrol/presentation/screens/patrol_home_screen.dart';
import '../features/patrol/presentation/screens/patrol_scanner_screen.dart';
import '../features/patrol/presentation/screens/patrol_alarm_screen.dart';
import '../features/for_you/presentation/screens/for_you_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';
import '../features/payroll/presentation/screens/payroll_screen.dart';
import '../features/payroll/presentation/screens/payroll_detail_screen.dart';
import '../features/leave/presentation/screens/leave_screen.dart';
import '../features/violation_report/presentation/screens/violation_report_form_screen.dart';
import '../features/violation_report/presentation/screens/violation_report_history_screen.dart';
import '../features/violation_report/presentation/screens/violation_report_detail_screen.dart';
import '../features/report/presentation/screens/report_list_screen.dart';
import '../features/report/presentation/screens/report_form_screen.dart';

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
        return '/dashboard';
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
          // Branch 0: Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const HRDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Presensi
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                name: 'attendance',
                builder: (context, state) => const AttendanceHomeScreen(),
              ),
            ],
          ),
          // Branch 2: For You
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/for-you',
                name: 'for-you',
                builder: (context, state) => const ForYouScreen(),
              ),
            ],
          ),
          // Branch 3: Akun / Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          // Branch 4: Face Enrollment (non-indexed, but part of shell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/face-enrollment',
                name: 'face-enrollment',
                builder: (context, state) => const FaceEnrollmentStatusScreen(),
              ),
            ],
          ),
          // Branch 5: Patrol (non-indexed, but part of shell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patrol',
                name: 'patrol',
                builder: (context, state) => const PatrolHomeScreen(),
              ),
            ],
          ),
          // Branch 6: Schedule (non-indexed, but part of shell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                name: 'schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          // Branch 7: Payroll (non-indexed, but part of shell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payroll',
                name: 'payroll',
                builder: (context, state) => const PayrollScreen(),
              ),
            ],
          ),
          // Branch 8: Leave (non-indexed, but part of shell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leave',
                name: 'leave',
                builder: (context, state) => const LeaveScreen(),
              ),
            ],
          ),
        ],
      ),

      // Immersive/Modal routes (outside shell, full-screen without bottom nav)
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

      // Edit Menu Screen (full-screen modal)
      GoRoute(
        path: '/edit-menu',
        name: 'edit-menu',
        builder: (context, state) => const EditMenuScreen(),
      ),

      // Change Password Screen (full-screen modal)
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Payroll Detail Screen (full-screen modal)
      GoRoute(
        path: '/payroll/detail',
        name: 'payroll-detail',
        builder: (context, state) {
          final payslip = state.extra as dynamic;
          return PayrollDetailScreen(payslip: payslip);
        },
      ),

      // Leave Form Screen (full-screen modal)
      GoRoute(
        path: '/leave/form',
        name: 'leave-form',
        builder: (context, state) => const LeaveFormScreen(),
      ),

      // Violation Report History Screen
      GoRoute(
        path: '/violation-report',
        name: 'violation-report',
        builder: (context, state) => const ViolationReportHistoryScreen(),
      ),

      // Violation Report Detail Screen
      GoRoute(
        path: '/violation-report/:id',
        name: 'violation-report-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ViolationReportDetailScreen(violationId: id);
        },
      ),

      // Violation Report Form Screen (full-screen modal)
      GoRoute(
        path: '/violation-report/form',
        name: 'violation-report-form',
        builder: (context, state) => const ViolationReportFormScreen(),
      ),

      // Field Report List Screen
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) => const ReportListScreen(),
      ),

      // Field Report Form Screen (full-screen modal)
      GoRoute(
        path: '/report/form',
        name: 'report-form',
        builder: (context, state) => const ReportFormScreen(),
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
    // Show onboarding after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  Future<void> _checkAndShowOnboarding() async {
    // Only show once per session
    if (_hasShownOnboarding) return;

    final hasSeen = await _onboardingService.hasSeenOnboarding();
    if (hasSeen) {
      _hasShownOnboarding = true;
      return;
    }

    // Wait for widgets to build
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Build tutorial targets
    final targets = _buildTutorialTargets();

    if (targets.isEmpty) {
      _hasShownOnboarding = true;
      return;
    }

    // Create and show tutorial
    _showTutorial(targets);
  }

  List<TargetFocus> _buildTutorialTargets() {
    final targets = <TargetFocus>[];

    // Menu Grid
    if (TutorialKeys.menuGridKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'menuGrid',
          keyTarget: TutorialKeys.menuGridKey,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialCard(
                'Menu Layanan',
                'Akses semua fitur aplikasi dari sini. Tap untuk masuk ke fitur yang diinginkan.',
              ),
            ),
          ],
        ),
      );
    }

    // Notification
    if (TutorialKeys.notificationKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'notification',
          keyTarget: TutorialKeys.notificationKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialCard(
                'Notifikasi',
                'Lihat notifikasi dan pengumuman penting di sini.',
              ),
            ),
          ],
        ),
      );
    }

    // Scan Button
    if (TutorialKeys.scanButtonKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'scanButton',
          keyTarget: TutorialKeys.scanButtonKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialCard(
                'Tombol Scan',
                'Tekan untuk scan wajah saat absen atau scan QR saat patroli.',
              ),
            ),
          ],
        ),
      );
    }

    // Panic Button
    if (TutorialKeys.panicButtonKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'panicButton',
          keyTarget: TutorialKeys.panicButtonKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialCard(
                'Tombol Panic / SOS',
                'Tekan dan tahan 3 detik saat darurat. Lokasi Anda akan dikirim ke tim keamanan.',
              ),
            ),
          ],
        ),
      );
    }

    // Bottom Nav Tabs
    if (TutorialKeys.homeKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'homeTab',
          keyTarget: TutorialKeys.homeKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialCard(
                'Tab Home',
                'Kembali ke dashboard utama.',
              ),
            ),
          ],
        ),
      );
    }

    if (TutorialKeys.presensiKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'presensiTab',
          keyTarget: TutorialKeys.presensiKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialCard(
                'Tab Absensi',
                'Catat kehadiran masuk dan pulang melalui tab ini.',
              ),
            ),
          ],
        ),
      );
    }

    if (TutorialKeys.forYouKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'forYouTab',
          keyTarget: TutorialKeys.forYouKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialCard(
                'Tab For You',
                'Dapatkan konten dan informasi yang dipersonalisasi.',
              ),
            ),
          ],
        ),
      );
    }

    if (TutorialKeys.akunKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'akunTab',
          keyTarget: TutorialKeys.akunKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialCard(
                'Tab Akun',
                'Kelola profil, pengaturan, dan informasi akun Anda.',
              ),
            ),
          ],
        ),
      );
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
        currentIndex: _getNavIndex(widget.navigationShell.currentIndex),
        onTap: (index) {
          // Map nav index back to branch index
          final branchIndex = _getBranchIndex(index);
          widget.navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == widget.navigationShell.currentIndex,
          );
        },
        homeKey: TutorialKeys.homeKey,
        presensiKey: TutorialKeys.presensiKey,
        forYouKey: TutorialKeys.forYouKey,
        akunKey: TutorialKeys.akunKey,
        scanButtonKey: TutorialKeys.scanButtonKey,
      ),
      extendBody: true,
    );
  }

  /// Map navigation bar index to branch index
  /// Branches 0-3 are indexed (shown in bottom nav)
  /// Branches 4+ are non-indexed (not shown in bottom nav)
  int _getBranchIndex(int navIndex) => navIndex;

  /// Map branch index to navigation bar index
  /// Only indexed branches (0-3) are shown
  int _getNavIndex(int branchIndex) {
    if (branchIndex >= 4) {
      // Non-indexed branches show the first tab as active
      return 0;
    }
    return branchIndex;
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
    // Delay hydrate until after first frame to avoid setState during build
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
    final destination = authNotifier.state.isAuthenticated
        ? '/dashboard'
        : '/login';

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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/banners/banner_carousel.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../../shared/utils/tutorial_keys.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../panic/presentation/providers/panic_provider.dart';
import '../../domain/menu_access.dart';
import '../widgets/menu_grid_carousel.dart';

/// Notifier that wraps notification service for rebuilding UI
class _NotificationRebuildNotifier extends ChangeNotifier {
  _NotificationRebuildNotifier() {
    globalNotificationService.onNotificationReceived = (_) {
      notifyListeners();
    };
  }
}

// Menu items with Forui icons
final _menuItems = <MenuItemData>[
  MenuItemData(label: 'Absen', icon: IconMap.accessTime, route: '/attendance'),
  MenuItemData(label: 'Pendaftaran Wajah', icon: IconMap.face, route: '/face-enrollment', badge: 'NEW'),
  MenuItemData(label: 'Jadwal', icon: IconMap.calendarToday, route: '/schedule'),
  MenuItemData(label: 'Cuti', icon: IconMap.beachAccess, route: '/leave'),
  MenuItemData(label: 'Payroll', icon: IconMap.accountBalanceWallet, route: '/payroll'),
  MenuItemData(label: 'Approval', icon: IconMap.checklist),
  MenuItemData(label: 'Patroli', icon: IconMap.security),
  MenuItemData(label: 'Laporan Patroli', icon: IconMap.reportProblem, route: '/violation-report'),
  MenuItemData(label: 'Laporan Mutasi', icon: IconMap.editNote, route: '/report'),
  MenuItemData(label: 'Tugas Harian', icon: IconMap.task, route: '/daily-task'),
];

final _patrolPoints = [
  {'name': 'Pos Gerbang Utama', 'done': true, 'time': '08:02'},
  {'name': 'Area Parkir B2', 'done': true, 'time': '08:15'},
  {'name': 'Gudang Belakang', 'done': false, 'time': null},
  {'name': 'Rooftop', 'done': false, 'time': null},
];

// TODO: Replace with actual promo images from backend/CMS
final _promoBanners = [
  'https://picsum.photos/800/200?random=1',
  'https://picsum.photos/800/200?random=2',
  'https://picsum.photos/800/200?random=3',
];

/// HR Dashboard - My BCA style
class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  bool _showPatroli = false;
  bool _panicHolding = false;
  double _panicProgress = 0;
  LocationData? _panicLocation;
  String? _panicError;

  static const _panicTypes = [
    'Kebakaran',
    'Kecelakaan',
    'Ancaman Keamanan',
    'Medis',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceNotifier>().loadTodayAttendance();
    });
  }

  void _startPanicHold() {
    
    setState(() {
      _panicHolding = true;
      _panicProgress = 0;
      _panicLocation = null;
      _panicError = null;
    });

    // Get location in background (runs in parallel with animation)
    _getLocationInBackground();

    // Start progress animation immediately with Timer
    const totalMs = 2000; // 2 seconds for panic hold
    const intervalMs = 16; // ~60fps

    int elapsed = 0;
    _panicTimer?.cancel();
    _panicTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!_panicHolding) {
        timer.cancel();
        return;
      }

      elapsed += intervalMs;
      final progress = (elapsed / totalMs * 100).clamp(0.0, 100.0);

      if (mounted) {
        setState(() {
          _panicProgress = progress;
        });
      }

      if (elapsed >= totalMs) {
        timer.cancel();
        if (_panicHolding && mounted) {
          _panicHolding = false;
          _showPanicTypeSheet();
        }
      }
    });
  }

  Timer? _panicTimer;

  void _cancelPanicHold() {
    _panicTimer?.cancel();
    setState(() {
      _panicHolding = false;
      _panicProgress = 0;
      _panicLocation = null;
      _panicError = null;
    });
  }

  Future<void> _getLocationInBackground() async {
    try {
      final locationService = LocationService();
      _panicLocation = await locationService.getCurrentLocation();
    } on LocationException catch (e) {
      _panicError = e.message;
    } catch (_) {
      _panicError = 'Gagal mendapatkan lokasi';
    }
  }

  Future<void> _onRefresh() async {
    await context.read<AttendanceNotifier>().loadTodayAttendance();
  }

  void _showPanicTypeSheet() {
    
    // Show error if location failed
    if (_panicError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_panicError!),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_panicLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi belum tersedia, coba lagi'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Jenis Kejadian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tekan sekali untuk memilih jenis darurat',
              style: TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            ...List.generate(_panicTypes.length, (index) {
              final type = _panicTypes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _submitPanic(type);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        ),
      ),
    );
  }

  void _submitPanic(String type) async {
    if (_panicLocation == null) return;

    

    final notifier = context.read<PanicNotifier>();
    final success = await notifier.sendPanicAlert(
      type: type,
      latitude: _panicLocation!.latitude,
      longitude: _panicLocation!.longitude,
    );

    

    if (!mounted) return;

    if (success) {
      final userName = context.read<AuthNotifier>().state.user?.name ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS $type berhasil dikirim — lokasi & identitas ($userName) sudah sampai ke tim keamanan',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.state.sendError ?? 'Gagal mengirim SOS'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    setState(() {
      _panicLocation = null;
      _panicError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.state.user;

    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildMenuGrid(),
                    const SizedBox(height: 20),
                    // Promo banner section - ALWAYS VISIBLE for all positions
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.card,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Promo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BannerCarousel(
                            images: _promoBanners,
                            height: 160,
                            borderRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
              // Panic button - only visible if user has panic_button privilege
              if (user?.hasPrivilege('panic_button') == true)
                _buildPanicButton(),
              if (_showPatroli) _buildPatroliSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authNotifier = context.read<AuthNotifier>();
    final userName = authNotifier.state.user?.name ?? 'User';
    final userPosition = authNotifier.state.user?.position ?? '';
    final theme = FTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat datang,',
              style: TextStyle(fontSize: 14, color: AppColors.slate500),
            ),
            const SizedBox(height: 2),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slate800,
              ),
            ),
            if (userPosition.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                userPosition,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        Row(children: [
          ChangeNotifierProvider(
            create: (_) => _NotificationRebuildNotifier(),
            child: Consumer<_NotificationRebuildNotifier>(
              builder: (context, _, _) => _NotificationButton(key: TutorialKeys.notificationKey),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final notifier = context.watch<AttendanceNotifier>();
    final data = notifier.state.todayData;
    final hasCheckedIn = data?.hasCheckedIn ?? false;
    final hasCheckedOut = data?.hasCheckedOut ?? false;
    final checkInTime = data?.checkInTime;
    final nextAction = data?.nextAction ?? 'check_in';
    final theme = FTheme.of(context);

    // Determine status
    String statusText;
    if (!hasCheckedIn) {
      statusText = 'Belum Absen';
    } else if (hasCheckedOut) {
      statusText = 'Selesai';
    } else {
      statusText = 'Sudah Absen';
    }

    // Format check-in time
    String timeText = '--:--';
    if (checkInTime != null) {
      timeText =
          '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
    }

    // Next action text
    String nextActionText = nextAction == 'check_out'
        ? 'Langkah selanjutnya: Absen Pulang'
        : 'Langkah selanjutnya: Absen Masuk';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Hari Ini',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    hasCheckedIn ? IconMap.checkCircle : IconMap.schedule,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$statusText · $timeText',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                nextActionText,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Jam Kerja',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              SizedBox(height: 4),
              Text(
                '142/160j',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    // Use watch to rebuild when auth state changes (e.g., hasFaceEnrollment updated)
    final user = context.watch<AuthNotifier>().state.user;
    final theme = FTheme.of(context);

    // Filter menu items based on user privileges
    List<Map<String, dynamic>> filteredMenuItems;
    if (user != null) {
      final filtered = filterMenuByPrivileges(_menuItems, user);
      filteredMenuItems = filtered.map((item) {
        return {
          'label': item.label,
          'icon': item.icon,
          'bg': theme.colors.muted,
          'fg': theme.colors.primary,
          'route': item.route,
          'badge': item.badge,
        };
      }).toList();
    } else {
      filteredMenuItems = _menuItems.map((item) {
        return {
          'label': item.label,
          'icon': item.icon,
          'bg': theme.colors.muted,
          'fg': theme.colors.primary,
          'route': item.route,
          'badge': item.badge,
        };
      }).toList();
    }

    return Container(
      key: TutorialKeys.menuGridKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Layanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              InkWell(
                onTap: () => context.push('/edit-menu'),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IconMap.tune, size: 18, color: theme.colors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MenuGridCarousel(menuItems: filteredMenuItems, itemsPerPage: 8),
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    return Positioned(
      bottom: 0,
      right: 20,
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: GestureDetector(
          key: TutorialKeys.panicButtonKey,
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) {
            
            _startPanicHold();
          },
          onLongPressEnd: (_) {
            
            _cancelPanicHold();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_panicHolding)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: _panicProgress / 100,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withAlpha(89),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.red600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red600.withAlpha(102),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(IconMap.warning, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatroliSheet() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showPatroli = false),
        child: Container(
          color: Colors.black38,
          child: GestureDetector(
            onTap: () {},
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Checklist Patroli',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                            Text(
                              'Shift Pagi · 08:00–16:00',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showPatroli = false),
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              IconMap.close,
                              size: 18,
                              color: AppColors.slate500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.teal600,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              IconMap.qrCodeScanner,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan QR di setiap titik',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.teal700,
                                  ),
                                ),
                                Text(
                                  '2 dari 4 titik selesai dicek',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.teal600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_patrolPoints.length, (index) {
                      final p = _patrolPoints[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: p['done'] as bool
                                    ? AppColors.emerald100
                                    : AppColors.slate200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                IconMap.locationOn,
                                size: 20,
                                color: p['done'] as bool
                                    ? AppColors.emerald600
                                    : AppColors.slate400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate800,
                                    ),
                                  ),
                                  Text(
                                    p['done'] as bool
                                        ? 'Dicek ${p['time']}'
                                        : 'Belum dicek',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (p['done'] as bool)
                              Icon(
                                IconMap.checkCircle,
                                color: AppColors.emerald500,
                                size: 24,
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Scan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.teal600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = globalNotificationService;
    final unreadCount = notifService.unreadCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNotificationsSheet(context, notifService),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                IconMap.notifications,
                color: AppColors.slate600,
                size: 22,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.red500,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, NotificationService notifService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => GestureDetector(
        onTap: () => Navigator.pop(sheetContext),
        behavior: HitTestBehavior.opaque,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) => GestureDetector(
            onTap: () {}, // Consume tap to prevent closing when tapping sheet content
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Material(
                color: Colors.white,
                child: Column(
                  children: [
                    // Handle bar
                    GestureDetector(
                      onTap: () {}, // Consume tap
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slate300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifikasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate800,
                            ),
                          ),
                          if (notifService.unreadCount > 0)
                            TextButton(
                              onPressed: () {
                                notifService.markAllAsRead();
                              },
                              child: const Text('Tandai semua dibaca'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Notification list
                    Expanded(
                      child: notifService.notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconMap.notifications, size: 64, color: AppColors.slate300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada notifikasi',
                                    style: TextStyle(color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: notifService.notifications.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                              itemBuilder: (context, index) {
                                final notif = notifService.notifications[index];
                                return _NotificationItem(
                                  notification: notif,
                                  onTap: () {
                                    notifService.markAsRead(notif.id);
                                    Navigator.pop(sheetContext);
                                    // Navigate based on type
                                    if (notif.type == 'patrol_alarm') {
                                      context.push('/patrol');
                                    } else if (notif.type == 'shift_reminder') {
                                      context.push('/attendance');
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _getIconBg(notification.type),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          _getIcon(notification.type),
          color: _getIconColor(notification.type),
          size: 22,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          color: AppColors.slate800,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.slate500, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.timestamp),
            style: TextStyle(color: AppColors.slate400, fontSize: 11),
          ),
        ],
      ),
      trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'patrol_alarm':
        return IconMap.security;
      case 'shift_reminder':
        return IconMap.accessTime;
      default:
        return IconMap.notifications;
    }
  }

  Color _getIconBg(String? type) {
    switch (type) {
      case 'patrol_alarm':
        return AppColors.teal100;
      case 'shift_reminder':
        return AppColors.amber100;
      default:
        return AppColors.slate100;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'patrol_alarm':
        return AppColors.teal600;
      case 'shift_reminder':
        return AppColors.amber600;
      default:
        return AppColors.slate600;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${time.day}/${time.month}/${time.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/banners/banner_carousel.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../../shared/utils/tutorial_keys.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../panic/presentation/providers/panic_provider.dart';
import '../widgets/menu_grid_carousel.dart';

// Data
final _menuGrid = [
  {'label': 'Presensi', 'icon': Icons.access_time, 'bg': AppColors.sky100, 'fg': AppColors.sky600, 'route': '/attendance', 'badge': null},
  {'label': 'Pendaftaran Wajah', 'icon': Icons.face, 'bg': AppColors.indigo100, 'fg': AppColors.indigo600, 'route': '/face-enrollment', 'badge': 'NEW'},
  {'label': 'Jadwal', 'icon': Icons.calendar_today, 'bg': AppColors.amber100, 'fg': AppColors.amber600, 'route': '/schedule', 'badge': null},
  {'label': 'Cuti', 'icon': Icons.beach_access, 'bg': AppColors.emerald100, 'fg': AppColors.emerald600, 'route': '/leave', 'badge': null},
  {'label': 'Payroll', 'icon': Icons.account_balance_wallet, 'bg': AppColors.amber100, 'fg': AppColors.amber600, 'route': '/payroll', 'badge': null},
  {'label': 'Approval', 'icon': Icons.checklist, 'bg': AppColors.indigo100, 'fg': AppColors.indigo600, 'route': null, 'badge': null},
  {'label': 'Patroli', 'icon': Icons.security, 'bg': AppColors.teal100, 'fg': AppColors.teal600, 'route': null, 'badge': null},
  {'label': 'Laporan Patroli', 'icon': Icons.report_problem, 'bg': AppColors.rose100, 'fg': AppColors.rose600, 'route': '/violation-report', 'badge': null},
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

  static const _panicTypes = ['Kebakaran', 'Kecelakaan', 'Ancaman Keamanan', 'Medis', 'Lainnya'];

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
    _runPanicTimer();
  }

  void _runPanicTimer() async {
    // Get location in background while holding
    _panicLocation = null;
    _panicError = null;

    try {
      final locationService = LocationService();
      _panicLocation = await locationService.getCurrentLocation();
    } on LocationException catch (e) {
      _panicError = e.message;
    } catch (_) {
      _panicError = 'Gagal mendapatkan lokasi';
    }

    // Continue progress animation even if location fails
    const totalMs = 3000;
    const intervalMs = 50;
    int elapsed = 0;
    while (_panicHolding && elapsed < totalMs) {
      await Future.delayed(const Duration(milliseconds: intervalMs));
      if (!_panicHolding) break;
      elapsed += intervalMs;
      if (mounted) {
        setState(() {
          _panicProgress = (elapsed / totalMs * 100).clamp(0, 100);
        });
      }
    }
    if (_panicHolding && _panicProgress >= 100) {
      _panicHolding = false;
      _showPanicTypeSheet();
    }
  }

  void _cancelPanicHold() {
    setState(() {
      _panicHolding = false;
      _panicProgress = 0;
      _panicLocation = null;
      _panicError = null;
    });
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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
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
                    // Promo banner section
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat datang,', style: TextStyle(fontSize: 14, color: AppColors.slate500)),
            const SizedBox(height: 2),
            Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate800)),
          ],
        ),
        Row(
          children: [
            _NotificationButton(key: TutorialKeys.notificationKey),
          ],
        ),
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
      timeText = '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
    }

    // Next action text
    String nextActionText = nextAction == 'check_out' ? 'Langkah selanjutnya: Absen Pulang' : 'Langkah selanjutnya: Absen Masuk';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.indigo600, AppColors.indigo500]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Hari Ini', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(hasCheckedIn ? Icons.check_circle : Icons.schedule, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('$statusText · $timeText', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              Text(nextActionText, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('Jam Kerja', style: TextStyle(fontSize: 12, color: Colors.white70)),
              SizedBox(height: 4),
              Text('142/160j', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
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
              const Text('Menu Layanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate800)),
              InkWell(
                onTap: () => context.push('/edit-menu'),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 18, color: AppColors.slate500),
                      SizedBox(width: 4),
                      Text('Edit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MenuGridCarousel(
            menuItems: _menuGrid,
            itemsPerPage: 8,
          ),
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
          onLongPressStart: (_) => _startPanicHold(),
          onLongPressEnd: (_) => _cancelPanicHold(),
          child: Stack(alignment: Alignment.center, children: [
            if (_panicHolding)
              SizedBox(
                width: 72, height: 72,
                child: CircularProgressIndicator(
                  value: _panicProgress / 100, strokeWidth: 4,
                  backgroundColor: Colors.white.withAlpha(89),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.red600,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.red600.withAlpha(102), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 28),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPatroliSheet() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showPatroli = false),
        child: Container(color: Colors.black38, child: GestureDetector(
          onTap: () {},
          child: Align(alignment: Alignment.bottomCenter, child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Checklist Patroli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                  Text('Shift Pagi · 08:00–16:00', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                ]),
                IconButton(
                  onPressed: () => setState(() => _showPatroli = false),
                  icon: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.close, size: 18, color: AppColors.slate500),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.teal50, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.teal600, borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Scan QR di setiap titik', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal700)),
                    Text('2 dari 4 titik selesai dicek', style: TextStyle(fontSize: 11, color: AppColors.teal600)),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
              ...List.generate(_patrolPoints.length, (index) {
                final p = _patrolPoints[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: p['done'] as bool ? AppColors.emerald100 : AppColors.slate200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.location_on, size: 20, color: p['done'] as bool ? AppColors.emerald600 : AppColors.slate400),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate800)),
                      Text(p['done'] as bool ? 'Dicek ${p['time']}' : 'Belum dicek', style: TextStyle(fontSize: 11, color: AppColors.slate400)),
                    ])),
                    if (p['done'] as bool)
                      const Icon(Icons.check_circle, color: AppColors.emerald500, size: 24)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.teal50, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal600)),
                      ),
                  ]),
                );
              }),
            ]),
          )),
        )),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_outlined, color: AppColors.slate600, size: 22),
            Positioned(
              top: 10, right: 10,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: AppColors.red500, shape: BoxShape.circle),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

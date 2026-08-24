import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// Bottom navigation bar with floating center button (myBCA style)
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// GlobalKeys for tutorial targets
  final GlobalKey? homeKey;
  final GlobalKey? presensiKey;
  final GlobalKey? forYouKey;
  final GlobalKey? akunKey;
  final GlobalKey? scanButtonKey;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.homeKey,
    this.presensiKey,
    this.forYouKey,
    this.akunKey,
    this.scanButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Extra height for FAB overlap
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom nav bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    globalKey: homeKey,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    globalKey: presensiKey,
                    icon: Icons.access_time_outlined,
                    activeIcon: Icons.access_time_filled,
                    label: 'Presensi',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const SizedBox(width: 64), // Space for FAB
                  _NavItem(
                    globalKey: forYouKey,
                    icon: Icons.star_outline,
                    activeIcon: Icons.star,
                    label: 'For You',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    globalKey: akunKey,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Akun',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
          // Floating center button (FAB)
          Positioned(
            left: 0,
            right: 0,
            bottom: 32, // Half of FAB height (64/2) minus overlap
            child: Center(
              child: GestureDetector(
                key: scanButtonKey,
                onTap: () => _showScanBottomSheet(context),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06B6D4),
                        Color(0xFF0891B2),
                      ], // Cyan gradient
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pilih Metode Scan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Scan options
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  // Scan Presensi
                  _ScanOptionTile(
                    icon: Icons.fingerprint,
                    iconColor: AppColors.indigo600,
                    iconBg: AppColors.indigo100,
                    title: 'Absen',
                    subtitle: 'Absen dengan wajah',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/attendance/capture');
                    },
                  ),
                  const SizedBox(height: 12),
                  // Scan Patroli
                  _ScanOptionTile(
                    icon: Icons.qr_code_scanner,
                    iconColor: AppColors.teal600,
                    iconBg: AppColors.teal100,
                    title: 'Patroli',
                    subtitle: 'Scan QR di titik patroli',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/patrol/scan');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final GlobalKey? globalKey;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    this.globalKey,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: Colors.white.withAlpha(isActive ? 255 : 179),
              // 70% opacity when inactive
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: Colors.white.withAlpha(isActive ? 255 : 179),
              ),
            ),
          ],
        ),
      ),
    );

    if (globalKey != null) {
      return Container(key: globalKey, child: widget);
    }

    return widget;
  }
}

class _ScanOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.slate400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

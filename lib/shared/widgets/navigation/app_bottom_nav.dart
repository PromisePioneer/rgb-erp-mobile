import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

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
    final theme = context.theme;
    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.state.user;
    final hasPresensiPrivilege = user?.hasPrivilege('presensi') == true;

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withAlpha(128),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom nav bar items
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: SizedBox(
              height: 64,
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
                    isEnabled: hasPresensiPrivilege,
                    onTap: () {
                      if (hasPresensiPrivilege) {
                        onTap(1);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Anda tidak memiliki akses Presensi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
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
            bottom: 32 + MediaQuery.of(context).padding.bottom,
            child: Center(
              child: GestureDetector(
                key: scanButtonKey,
                onTap: () => _showScanBottomSheet(context),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gray300.withAlpha(102),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: theme.colors.primaryForeground,
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
    final theme = context.theme;
    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.state.user;

    // Check privileges
    final hasPresensiPrivilege = user?.hasPrivilege('presensi') == true;
    final hasPatrolPrivilege = user?.hasPrivilege('patrol') == true;

    // If no privileges at all, show message and return
    if (!hasPresensiPrivilege && !hasPatrolPrivilege) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak memiliki akses scan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: const BorderRadius.vertical(
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
                color: theme.colors.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pilih Metode Scan',
                style: theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Scan options
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  // Scan Presensi (requires 'presensi' privilege)
                  if (hasPresensiPrivilege) ...[
                    _ScanOptionTile(
                      icon: Icons.fingerprint,
                      iconColor: theme.colors.primary,
                      iconBg: theme.colors.muted,
                      title: 'Absen',
                      subtitle: 'Absen dengan wajah',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/attendance/capture');
                      },
                    ),
                    if (hasPatrolPrivilege) const SizedBox(height: 12),
                  ],
                  // Scan Patroli (requires 'patrol' privilege)
                  if (hasPatrolPrivilege)
                    _ScanOptionTile(
                      icon: Icons.qr_code_scanner,
                      iconColor: theme.colors.primary,
                      iconBg: theme.colors.muted,
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
  final bool isEnabled;
  final VoidCallback onTap;

  const _NavItem({
    this.globalKey,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final activeColor = theme.colors.primaryForeground;
    final disabledColor = theme.colors.primaryForeground.withAlpha(102); // 40% opacity
    final inactiveColor = theme.colors.primaryForeground.withAlpha(179); // 70% opacity

    final isDisabled = !isEnabled;
    final iconColor = isActive
        ? activeColor
        : isDisabled
            ? disabledColor
            : inactiveColor;

    final widget = GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.typography.body.xs.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: iconColor,
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
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colors.muted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colors.border),
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
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colors.mutedForeground,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

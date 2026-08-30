import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Settings screen with biometric toggle
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = context.read<AuthNotifier>();
      final authState = authNotifier.state;

      if (value) {
        await authNotifier.enableBiometric(authState.savedNik ?? '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint berhasil diaktifkan'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await authNotifier.disableBiometric();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint dinonaktifkan'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;

    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Pengaturan'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.slate800,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Biometric Section
            _buildSectionHeader('Keamanan'),
            _buildSettingsCard([
            _SettingsTile(
              icon: IconMap.fingerprint,
              iconColor: AppColors.primary,
              title: 'Login Fingerprint',
              subtitle: authState.biometricAvailable
                  ? 'Gunakan sidik jari untuk login'
                  : 'Fingerprint tidak tersedia di perangkat ini',
              trailing: authState.biometricAvailable
                  ? FSwitch(
                      value: authState.biometricEnabled,
                      onChange: _isLoading ? null : (value) => _toggleBiometric(value),
                    )
                  : null,
              onTap: authState.biometricAvailable
                  ? () => _toggleBiometric(!authState.biometricEnabled)
                  : null,
            ),
          ]),

          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader('Tentang Aplikasi'),
          _buildSettingsCard([
            _SettingsTile(
              icon: IconMap.infoOutline,
              iconColor: AppColors.slate500,
              title: 'Versi Aplikasi',
              subtitle: '1.0.0',
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: IconMap.business,
              iconColor: AppColors.slate500,
              title: 'RGB ERP Mobile',
              subtitle: 'Employee Self Service',
            ),
          ]),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Akun'),
          _buildSettingsCard([
            _SettingsTile(
              icon: IconMap.lock,
              iconColor: AppColors.primary,
              title: 'Ganti Password',
              subtitle: 'Ubah password akun Anda',
              onTap: () => context.push('/change-password'),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: IconMap.logout,
              iconColor: AppColors.danger,
              title: 'Logout',
              subtitle: 'Keluar dari aplikasi',
              onTap: () => _showLogoutDialog(context),
            ),
          ]),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'RGB ERP Mobile v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.slate400,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.slate500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await LogoutDialog.show(context);

    if (confirmed == true && mounted) {
      await context.read<AuthNotifier>().logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                Icon(
                  IconMap.chevronRight,
                  color: AppColors.slate400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

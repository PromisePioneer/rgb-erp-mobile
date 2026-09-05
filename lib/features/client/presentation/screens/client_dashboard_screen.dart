import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/client_dashboard_provider.dart';

/// Client dashboard screen - overview stats
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientDashboardNotifier>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.watch<ClientDashboardNotifier>().state;
    final data = dashboardState.data;
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Client'),
        automaticallyImplyLeading: false,
        actions: [
          FButton.icon(
            onPress: () {
              context.read<ClientDashboardNotifier>().refresh();
            },
            child: Icon(IconMap.refreshCcw),
          ),
          const SizedBox(width: 8),
          FButton.icon(
            onPress: () {
              _handleLogout(context);
            },
            child: Icon(IconMap.logOut),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ClientDashboardNotifier>().refresh();
        },
        child: dashboardState.isLoading && data == null
            ? const Center(child: LoadingIndicator())
            : dashboardState.error != null && data == null
                ? _buildError(dashboardState.error!)
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _buildWelcomeCard(context, theme),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Employee',
                              value: '${data?.totalEmployees ?? 0}',
                              icon: IconMap.users,
                              color: AppColors.primary,
                              onTap: () => context.push('/client/employees'),
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Area',
                              value: '${data?.totalAreas ?? 0}',
                              icon: IconMap.mapPin,
                              color: AppColors.info,
                              onTap: () => context.push('/client/areas'),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        title: 'Hadir Hari Ini',
                        value: '${data?.attendanceToday.checkedIn ?? 0}',
                        subtitle: 'Pending: ${data?.attendanceToday.pending ?? 0}',
                        icon: IconMap.checkCircle,
                        color: AppColors.success,
                        onTap: () => context.push('/client/attendance'),
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        title: 'Laporan Hari Ini',
                        value: '${(data?.tasksSummary.total ?? 0) + (data?.patrolSummary.total ?? 0) + (data?.fieldReportsToday ?? 0)}',
                        subtitle: 'Tugas: ${data?.tasksSummary.total ?? 0} • Patrol: ${data?.patrolSummary.total ?? 0} • Field: ${data?.fieldReportsToday ?? 0}',
                        icon: IconMap.fileText,
                        color: AppColors.info,
                        onTap: () => context.push('/client/tasks'),
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        title: 'Jadwal Karyawan',
                        value: 'Calendar',
                        subtitle: 'Lihat jadwal dan kehadiran',
                        icon: IconMap.calendar,
                        color: AppColors.warning,
                        onTap: () => context.push('/client/schedules'),
                        theme: theme,
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang!',
            style: theme.typography.display.lg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Monitoring Karyawan Anda',
            style: theme.typography.body.md.copyWith(
                  color: Colors.white.withAlpha(230),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconMap.alertCircle, color: AppColors.danger, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Gagal memuat data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gray600),
          ),
          const SizedBox(height: AppSpacing.lg),
          FButton(
            onPress: () {
              context.read<ClientDashboardNotifier>().fetchDashboard();
            },
            variant: FButtonVariant.primary,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _LogoutDialog(
        onLogout: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true && context.mounted) {
      // Actually call logout on AuthNotifier
      await context.read<AuthNotifier>().logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onCancel;

  const _LogoutDialog({
    required this.onLogout,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Logout',
                style: theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda yakin ingin logout?',
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      onPress: onCancel,
                      variant: FButtonVariant.ghost,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: onLogout,
                      variant: FButtonVariant.primary,
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final FThemeData theme;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusMd,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: AppRadius.radiusMd,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.typography.body.sm.copyWith(
                      color: AppColors.slate500,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.typography.display.lg.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.typography.body.xs.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(IconMap.chevronRight, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Client'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ClientDashboardNotifier>().refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _handleLogout(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ClientDashboardNotifier>().refresh();
        },
        child: dashboardState.isLoading && data == null
            ? const Center(child: CircularProgressIndicator())
            : dashboardState.error != null && data == null
                ? _buildError(dashboardState.error!)
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _buildWelcomeCard(context),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Employee',
                              value: '${data?.totalEmployees ?? 0}',
                              icon: Icons.people_outline,
                              color: AppColors.primary,
                              onTap: () => context.push('/client/employees'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Area',
                              value: '${data?.totalAreas ?? 0}',
                              icon: Icons.location_on_outlined,
                              color: AppColors.info,
                              onTap: () => context.push('/client/areas'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        title: 'Hadir Hari Ini',
                        value: '${data?.attendanceToday.checkedIn ?? 0}',
                        subtitle: 'Pending: ${data?.attendanceToday.pending ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onTap: () => context.push('/client/attendance'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        title: 'Laporan Hari Ini',
                        value: '${(data?.tasksSummary.total ?? 0) + (data?.patrolSummary.total ?? 0) + (data?.fieldReportsToday ?? 0)}',
                        subtitle: 'Tugas: ${data?.tasksSummary.total ?? 0} • Patrol: ${data?.patrolSummary.total ?? 0} • Field: ${data?.fieldReportsToday ?? 0}',
                        icon: Icons.summarize_outlined,
                        color: AppColors.info,
                        onTap: () => context.push('/client/tasks'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        title: 'Jadwal Karyawan',
                        value: 'Calendar',
                        subtitle: 'Lihat jadwal dan kehadiran',
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.warning,
                        onTap: () => context.push('/client/schedules'),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Monitoring Karyawan Anda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
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
          ElevatedButton(
            onPressed: () {
              context.read<ClientDashboardNotifier>().fetchDashboard();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
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
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

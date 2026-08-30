import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../../domain/domain.dart';
import '../providers/violation_report_provider.dart';

/// Violation report history screen - shows logged in user's violation reports
class ViolationReportHistoryScreen extends StatefulWidget {
  const ViolationReportHistoryScreen({super.key});

  @override
  State<ViolationReportHistoryScreen> createState() => _ViolationReportHistoryScreenState();
}

class _ViolationReportHistoryScreenState extends State<ViolationReportHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ViolationReportNotifier>().loadUserViolations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return TopGradientBackground(
      gradientHeight: 120,
      child: Scaffold(
        backgroundColor: theme.colors.muted,
        appBar: AppBar(
          title: const Text('Riwayat Laporan Patroli'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(IconMap.arrowBack, color: theme.colors.foreground),
            onPressed: () => context.pop(),
          ),
        ),
        body: Consumer<ViolationReportNotifier>(
          builder: (context, notifier, child) {
            if (notifier.state.isLoadingViolations) {
              return Center(
                child: LoadingIndicator(size: 32),
              );
            }

            if (notifier.state.violationsError != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconMap.errorOutline, size: 64, color: theme.colors.destructive),
                    SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        notifier.state.violationsError!,
                        style: TextStyle(color: theme.colors.mutedForeground),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 150,
                      child: PrimaryButton(
                        label: 'Coba Lagi',
                        onPressed: () => notifier.loadUserViolations(),
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
              );
            }

            final violations = notifier.state.violations;

            if (violations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colors.muted,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(IconMap.inbox, size: 48, color: theme.colors.mutedForeground),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Belum ada laporan patroli',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Klik tombol + untuk menambah',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => notifier.loadUserViolations(),
              child: ListView.builder(
                padding: EdgeInsets.all(AppSpacing.md),
                itemCount: violations.length,
                itemBuilder: (context, index) {
                  final violation = violations[index];
                  return _ViolationCard(violation: violation);
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/violation-report/form'),
          backgroundColor: theme.colors.primary,
          child: Icon(IconMap.add, color: theme.colors.primaryForeground),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 0, // Default to home
          onTap: (index) => _onNavTap(context, index),
        ),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/attendance');
        break;
      case 2:
        context.go('/for-you');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}

class _ViolationCard extends StatelessWidget {
  final ViolationReportResult violation;

  const _ViolationCard({required this.violation});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/violation-report/${violation.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colors.destructive.withAlpha(25),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colors.destructive.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(IconMap.warning, color: theme.colors.destructive, size: 24),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            violation.violationTypeName ?? 'Pelanggaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colors.foreground,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            violation.areaName ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(IconMap.chevronRight, color: theme.colors.mutedForeground),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: IconMap.person,
                      label: 'Pelanggar',
                      value: violation.employeeName ?? '-',
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: IconMap.calendarToday,
                      label: 'Waktu',
                      value: _formatDateTime(violation.capturedAt),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: IconMap.locationOn,
                      label: 'Lokasi',
                      value: violation.latitude != null && violation.longitude != null
                          ? '${violation.latitude!.toStringAsFixed(5)}, ${violation.longitude!.toStringAsFixed(5)}'
                          : '-',
                    ),
                    if (violation.action != null && violation.action!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: IconMap.build,
                        label: 'Tindakan',
                        value: violation.action!,
                      ),
                    ],
                    if (violation.photoCount > 0) ...[
                      SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: IconMap.cameraAlt,
                        label: 'Foto',
                        value: '${violation.photoCount} foto',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colors.mutedForeground),
        SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colors.foreground,
            ),
          ),
        ),
      ],
    );
  }
}

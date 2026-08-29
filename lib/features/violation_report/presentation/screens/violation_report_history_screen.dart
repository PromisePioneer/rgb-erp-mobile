import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
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
    return TopGradientBackground(
      gradientHeight: 120,
      child: Scaffold(
        backgroundColor: AppColors.slate100,
        appBar: AppBar(
          title: const Text('Riwayat Laporan Patroli'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.slate800),
            onPressed: () => context.pop(),
          ),
        ),
        body: Consumer<ViolationReportNotifier>(
          builder: (context, notifier, child) {
            if (notifier.state.isLoadingViolations) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (notifier.state.violationsError != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                    SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        notifier.state.violationsError!,
                        style: TextStyle(color: AppColors.slate600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => notifier.loadUserViolations(),
                      child: Text('Coba Lagi'),
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
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(Icons.inbox, size: 48, color: AppColors.slate400),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Belum ada laporan patroli',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Klik tombol + untuk menambah',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate500,
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
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add, color: Colors.white),
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
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.rose100.withAlpha(77),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.rose100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.warning, color: AppColors.rose600, size: 24),
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
                              color: AppColors.slate800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            violation.areaName ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.slate400),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Pelanggar',
                      value: violation.employeeName ?? '-',
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Waktu',
                      value: _formatDateTime(violation.capturedAt),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Lokasi',
                      value: violation.latitude != null && violation.longitude != null
                          ? '${violation.latitude!.toStringAsFixed(5)}, ${violation.longitude!.toStringAsFixed(5)}'
                          : '-',
                    ),
                    if (violation.action != null && violation.action!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.build,
                        label: 'Tindakan',
                        value: violation.action!,
                      ),
                    ],
                    if (violation.photoCount > 0) ...[
                      SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.camera_alt,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slate500),
        SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate800,
            ),
          ),
        ),
      ],
    );
  }
}

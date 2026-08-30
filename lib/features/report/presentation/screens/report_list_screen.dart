import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../../domain/domain.dart';
import '../providers/report_provider.dart';

/// Field report list screen - grouped by area
class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportNotifier>().loadReportsByArea();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Laporan Mutasi'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReportNotifier>().loadReportsByArea(),
          ),
        ],
      ),
      body: Consumer<ReportNotifier>(
        builder: (context, notifier, child) {
          if (notifier.state.isLoadingAreas) {
            return const Center(
              child: LoadingIndicator(size: 32),
            );
          }

          if (notifier.state.areasError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.errorOutline, size: 48, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    notifier.state.areasError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 150,
                    child: PrimaryButton(
                      label: 'Coba Lagi',
                      onPressed: () => notifier.loadReportsByArea(),
                      fullWidth: false,
                    ),
                  ),
                ],
              ),
            );
          }

          if (notifier.state.areas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconMap.calendarToday,
                    size: 64,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Belum ada laporan mutasi',
                    style: TextStyle(fontSize: 16, color: AppColors.gray500),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifier.loadReportsByArea(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifier.state.areas.length,
              itemBuilder: (ctx, index) {
                final area = notifier.state.areas[index];
                return _buildAreaSection(area);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/report/form'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) => _onNavTap(context, index),
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

  Widget _buildAreaSection(ReportArea area) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Area header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(IconMap.locationOn, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  area.areaName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${area.count} laporan',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Reports in this area
        ...area.reports.map((report) => _buildReportCard(report)),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildReportCard(Report report) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.calendarToday, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                '${report.date} ${report.time}',
                style: TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
              const Spacer(),
              if (report.image != null)
                Icon(IconMap.cameraAlt, size: 14, color: AppColors.gray400),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.description,
            style: const TextStyle(fontSize: 14, color: AppColors.slate800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                IconMap.locationOn,
                size: 14,
                color: AppColors.gray400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (report.employeeName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(IconMap.person, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(
                  report.employeeName!,
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

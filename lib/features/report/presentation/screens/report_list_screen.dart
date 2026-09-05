import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
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
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Laporan Mutasi'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(IconMap.refresh),
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
                  Icon(IconMap.errorOutline, size: 48, color: theme.colors.destructive),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    notifier.state.areasError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colors.destructive),
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
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Belum ada laporan mutasi',
                    style: TextStyle(fontSize: 16, color: theme.colors.mutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifier.loadReportsByArea(),
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
          onPressed: () => context.push('/report/form'),
          backgroundColor: theme.colors.primary,
          foregroundColor: theme.colors.primaryForeground,
          child: Icon(IconMap.add),
        ),
      ),
    );
  }

  Widget _buildAreaSection(ReportArea area) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Area header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colors.primary,
            borderRadius: AppRadius.radiusMd,
          ),
          child: Row(
            children: [
              Icon(IconMap.locationOn, color: theme.colors.primaryForeground, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  area.areaName,
                  style: TextStyle(
                    color: theme.colors.primaryForeground,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colors.primaryForeground.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${area.count} laporan',
                  style: TextStyle(color: theme.colors.primaryForeground, fontSize: 12),
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
    final theme = context.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.calendarToday, size: 14, color: theme.colors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                '${report.date} ${report.time}',
                style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
              ),
              const Spacer(),
              if (report.image != null)
                Icon(IconMap.cameraAlt, size: 14, color: theme.colors.mutedForeground),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.description,
            style: TextStyle(fontSize: 14, color: theme.colors.foreground),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                IconMap.locationOn,
                size: 14,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (report.employeeName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(IconMap.person, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  report.employeeName!,
                  style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

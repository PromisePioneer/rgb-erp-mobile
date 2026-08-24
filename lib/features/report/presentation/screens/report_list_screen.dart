import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
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
        title: const Text('Laporan Lapangan'),
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
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (notifier.state.areasError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    notifier.state.areasError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => notifier.loadReportsByArea(),
                    child: const Text('Coba Lagi'),
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
                  Icon(Icons.assignment_outlined, size: 64, color: AppColors.gray400),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Belum ada laporan lapangan',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/report/form'),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Laporan Baru'),
                  ),
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
    );
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
              Icon(Icons.location_on, color: Colors.white, size: 18),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
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
              Icon(Icons.calendar_today, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                '${report.date} ${report.time}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                ),
              ),
              const Spacer(),
              if (report.image != null)
                Icon(Icons.photo, size: 14, color: AppColors.gray400),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (report.employeeName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(
                  report.employeeName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../providers/schedule_provider.dart';
import '../widgets/date_strip.dart';

/// Schedule screen showing work schedules
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleNotifier>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 140,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Consumer<ScheduleNotifier>(
            builder: (context, notifier, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Kerja',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(notifier.state.selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date strip
                  const DateStrip(),

                  const SizedBox(height: 16),

                  // Schedule content
                  Expanded(
                    child: notifier.state.isLoading
                        ? const Center(child: LoadingIndicator())
                        : notifier.state.error != null
                            ? _buildError(notifier)
                            : notifier.state.schedulesForSelectedDate.isEmpty
                                ? _buildEmptyState()
                                : _buildScheduleList(notifier.state.schedulesForSelectedDate),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildError(ScheduleNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => notifier.loadSchedules(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.slate300,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Tidak ada jadwal di tanggal ini',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List schedules) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(dynamic schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            schedule.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 12),

          // Time
          if (schedule.time != null) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.indigo100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: AppColors.indigo600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  schedule.time!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Location / Area & Client
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.teal600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Area name
                    Text(
                      schedule.areaName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate700,
                      ),
                    ),
                    // Client name (if different from area)
                    if (schedule.clientName != null && schedule.clientName != schedule.areaName) ...[
                      const SizedBox(height: 2),
                      Text(
                        schedule.clientName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

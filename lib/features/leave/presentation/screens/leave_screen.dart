import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../domain/models/leave_request_item.dart';
import '../providers/leave_provider.dart';

/// Leave screen showing list of leave requests
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveNotifier>().loadLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 120,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Cuti',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              Expanded(
                child: Consumer<LeaveNotifier>(
                  builder: (context, notifier, child) {
                    if (notifier.state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (notifier.state.error != null) {
                      return _buildError(notifier);
                    }

                    if (notifier.state.leaves.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildLeaveList(notifier.state.leaves);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/leave/form'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Ajukan Cuti'),
          ),
        ),
      ),
    );
  }

  Widget _buildError(LeaveNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => notifier.loadLeaves(),
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
          Icon(Icons.beach_access, size: 64, color: AppColors.slate300),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Belum ada pengajuan cuti',
            style: TextStyle(fontSize: 16, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList(List<LeaveRequestItem> leaves) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) => _buildLeaveCard(leaves[index]),
    );
  }

  Widget _buildLeaveCard(LeaveRequestItem leave) {
    final statusColor = _getStatusColor(leave.status);
    final statusBg = _getStatusBg(leave.status);

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leave.dateRange,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate600,
                      ),
                    ),
                    if (leave.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        leave.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leave.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (leave.durationInDays > 1) ...[
            const SizedBox(height: 8),
            Text(
              '${leave.durationInDays} hari',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.successBg;
      case 'Rejected':
        return AppColors.dangerBg;
      default:
        return AppColors.warningBg;
    }
  }
}

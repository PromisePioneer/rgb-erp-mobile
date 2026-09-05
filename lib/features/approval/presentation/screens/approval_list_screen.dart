import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../domain/models/approval.dart';
import '../providers/approval_provider.dart';

class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovalNotifier>().loadApprovals();
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Persetujuan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              Expanded(
                child: Consumer<ApprovalNotifier>(
                  builder: (context, notifier, child) {
                    if (notifier.state.isLoading) {
                      return const Center(child: LoadingIndicator());
                    }
                    if (notifier.state.error != null) {
                      return _buildError(notifier);
                    }
                    if (notifier.state.approvals.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildList(notifier.state.approvals);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ApprovalNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(notifier.state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.loadApprovals(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.slate300),
          SizedBox(height: 16),
          Text(
            'Tidak ada persetujuan tertunda',
            style: TextStyle(fontSize: 16, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Approval> approvals) {
    return RefreshIndicator(
      onRefresh: () => context.read<ApprovalNotifier>().loadApprovals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: approvals.length,
        itemBuilder: (context, index) => _buildCard(approvals[index]),
      ),
    );
  }

  Widget _buildCard(Approval approval) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/approval/${approval.id}', extra: approval),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeIcon(approval.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            approval.typeLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          if (approval.request?.code != null)
                            Text(
                              approval.request!.code!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.slate500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildLevelBadge(approval.level),
                  ],
                ),
                if (approval.request?.total != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    approval.request!.formattedTotal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;
    if (type.contains('Purchase')) {
      icon = Icons.shopping_cart;
      color = AppColors.primary;
    } else if (type.contains('Leave') || type.contains('Cuti')) {
      icon = Icons.beach_access;
      color = AppColors.info;
    } else {
      icon = Icons.approval;
      color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildLevelBadge(int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Level $level',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

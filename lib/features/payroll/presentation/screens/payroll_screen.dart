import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../domain/models/payslip.dart';
import '../providers/payroll_provider.dart';

/// Payroll screen showing list of payslips
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayrollNotifier>().loadPayslips();
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Text(
                  'Payroll',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Consumer<PayrollNotifier>(
                  builder: (context, notifier, child) {
                    if (notifier.state.isLoading) {
                      return const Center(child: LoadingIndicator());
                    }

                    if (notifier.state.error != null) {
                      return _buildError(notifier);
                    }

                    if (notifier.state.payslips.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildPayslipList(notifier.state.payslips);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(PayrollNotifier notifier) {
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
              onPressed: () => notifier.loadPayslips(),
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
        children: const [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: AppColors.slate300,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada data payroll',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipList(List<Payslip> payslips) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payslips.length,
      itemBuilder: (context, index) {
        final payslip = payslips[index];
        return _buildPayslipCard(payslip);
      },
    );
  }

  Widget _buildPayslipCard(Payslip payslip) {
    final isPaid = payslip.status == 'Paid';

    return GestureDetector(
      onTap: () => context.push('/payroll/detail', extra: payslip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Month/Year
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payslip.period,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.successBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payslip.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Net amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(payslip.net),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gaji Bersih',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.slate400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

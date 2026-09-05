import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

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
    final theme = context.theme;

    return TopGradientBackground(
      gradientHeight: 120,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Text(
                  'Payroll',
                  style: theme.typography.body.xl.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Consumer<PayrollNotifier>(
                  builder: (context, notifier, child) {
                    if (notifier.state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (notifier.state.error != null) {
                      return _buildError(notifier, theme);
                    }

                    if (notifier.state.payslips.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    return _buildPayslipList(notifier.state.payslips, theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(PayrollNotifier notifier, FThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error!,
              textAlign: TextAlign.center,
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FButton(
              onPress: () => notifier.loadPayslips(),
              variant: FButtonVariant.primary,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada data payroll',
            style: theme.typography.body.md.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipList(List<Payslip> payslips, FThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payslips.length,
      itemBuilder: (context, index) {
        final payslip = payslips[index];
        return _buildPayslipCard(payslip, theme);
      },
    );
  }

  Widget _buildPayslipCard(Payslip payslip, FThemeData theme) {
    final isPaid = payslip.status == 'Paid';

    return GestureDetector(
      onTap: () => context.push('/payroll/detail', extra: payslip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colors.background,
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
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
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
                      style: theme.typography.body.xs.copyWith(
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
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gaji Bersih',
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colors.mutedForeground,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

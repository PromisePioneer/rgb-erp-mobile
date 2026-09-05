import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../domain/models/payslip.dart';

/// Payroll detail screen showing breakdown of a payslip
class PayrollDetailScreen extends StatelessWidget {
  final Payslip payslip;

  const PayrollDetailScreen({
    super.key,
    required this.payslip,
  });

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

    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: Text(payslip.period),
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: payslip.status == 'Paid'
                    ? AppColors.successBg
                    : AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payslip.status,
                style: theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.w600,
                  color: payslip.status == 'Paid'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Earnings section
            _buildSection(
              theme: theme,
              title: 'Pendapatan',
              icon: Icons.add_circle_outline,
              iconColor: AppColors.success,
              items: payslip.earnings,
              total: payslip.totalEarnings,
              isPositive: true,
            ),
            const SizedBox(height: 16),

            // Deductions section
            _buildSection(
              theme: theme,
              title: 'Potongan',
              icon: Icons.remove_circle_outline,
              iconColor: AppColors.danger,
              items: payslip.deductions,
              total: payslip.totalDeductions,
              isPositive: false,
            ),
            const SizedBox(height: 16),

            // Net salary highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colors.primary, theme.colors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Gaji Bersih',
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.primaryForeground.withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(payslip.net),
                    style: theme.typography.display.xl2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.primaryForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required FThemeData theme,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<PayslipLine> items,
    required double total,
    required bool isPositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colors.border),

          // Items
          ...items.map((item) => _buildLineItem(theme, item.name, item.amount, isPositive)),

          // Total
          Divider(height: 1, color: theme.colors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total $title',
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
                Text(
                  _formatCurrency(total),
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPositive ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(FThemeData theme, String name, double amount, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.typography.body.md.copyWith(
                color: theme.colors.foreground,
              ),
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'} ${_formatCurrency(amount)}',
            style: theme.typography.body.md.copyWith(
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

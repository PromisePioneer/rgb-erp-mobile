import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: Text(payslip.period),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
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
                style: TextStyle(
                  fontSize: 12,
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
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Gaji Bersih',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(payslip.net),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<PayslipLine> items,
    required double total,
    required bool isPositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items
          ...items.map((item) => _buildLineItem(item.name, item.amount, isPositive)),

          // Total
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total $title',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
                  ),
                ),
                Text(
                  _formatCurrency(total),
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildLineItem(String name, double amount, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate700,
              ),
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'} ${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 14,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

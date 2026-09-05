import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../providers/client_dashboard_provider.dart';

/// Client employee list screen
class ClientEmployeeListScreen extends StatelessWidget {
  const ClientEmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Karyawan'),
        actions: [
          FButton.icon(
            onPress: () => context.read<ClientDashboardNotifier>().fetchEmployees(),
            child: Icon(IconMap.refreshCcw),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ClientDashboardNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoadingEmployees) {
            return const Center(child: LoadingIndicator());
          }

          if (notifier.employeesError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.alertCircle, size: 64, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text('Gagal memuat: ${notifier.employeesError}', style: theme.typography.body.md),
                  const SizedBox(height: AppSpacing.lg),
                  FButton(
                    onPress: () => notifier.fetchEmployees(),
                    variant: FButtonVariant.primary,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (notifier.employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.users, size: 64, color: AppColors.gray400),
                  const SizedBox(height: AppSpacing.md),
                  Text('Belum ada karyawan', style: theme.typography.body.md),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifier.fetchEmployees(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifier.employees.length,
              itemBuilder: (context, index) {
                final employee = notifier.employees[index];
                return _EmployeeCard(employee: employee, theme: theme);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final ClientEmployee employee;
  final FThemeData theme;

  const _EmployeeCard({required this.employee, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(24),
              image: employee.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(employee.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: employee.photoUrl == null
                ? Center(
                    child: Text(
                      _getInitials(employee.name),
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray600,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIK: ${employee.code.isNotEmpty ? employee.code : '-'}',
                  style: theme.typography.body.sm.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                if (employee.role != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      employee.role!,
                      style: theme.typography.body.xs.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

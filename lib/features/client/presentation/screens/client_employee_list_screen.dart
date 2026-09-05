import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../providers/client_dashboard_provider.dart';

/// Client employee list screen
class ClientEmployeeListScreen extends StatelessWidget {
  const ClientEmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Karyawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ClientDashboardNotifier>().fetchEmployees(),
          ),
        ],
      ),
      body: Consumer<ClientDashboardNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoadingEmployees) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifier.employeesError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text('Gagal memuat: ${notifier.employeesError}'),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => notifier.fetchEmployees(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (notifier.employees.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: AppColors.gray400),
                  SizedBox(height: AppSpacing.md),
                  Text('Belum ada karyawan'),
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
                return _EmployeeCard(employee: employee);
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

  const _EmployeeCard({required this.employee});

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
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gray200,
            backgroundImage: employee.photoUrl != null
                ? NetworkImage(employee.photoUrl!)
                : null,
            child: employee.photoUrl == null
                ? Text(
                    _getInitials(employee.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray600,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIK: ${employee.code.isNotEmpty ? employee.code : '-'}',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
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
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../hr_dashboard/domain/menu_access.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';

/// For You screen - Menu for PR, PO, Fund Request, and Reception
class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final user = authNotifier.state.user;
    final canAccessPurchasing = user != null && hasAnyPurchasingPrivilege(user);
    final theme = Theme.of(context);

    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Purchasing'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.slate800,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MenuCard(
              icon: IconMap.description,
              title: 'Purchase Request',
              subtitle: 'Ajukan permintaan pembelian',
              hasAccess: user?.hasPrivilege('purchase_request') ?? false,
              onTap: canAccessPurchasing
                  ? () => context.push('/purchase-request')
                  : null,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: IconMap.shoppingCart,
              title: 'Purchase Order',
              subtitle: 'Buat order dari PR yang disetujui',
              hasAccess: user?.hasPrivilege('purchase_order') ?? false,
              onTap: canAccessPurchasing
                  ? () => context.push('/purchase-order')
                  : null,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: IconMap.accountBalanceWallet,
              title: 'Fund Request',
              subtitle: 'Ajukan permintaan dana',
              hasAccess: user?.hasPrivilege('fund_request') ?? false,
              onTap: canAccessPurchasing
                  ? () => context.push('/fund-request')
                  : null,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: IconMap.inventory,
              title: 'Penerimaan Barang',
              subtitle: 'Terima barang dari supplier',
              hasAccess: user?.hasPrivilege('reception') ?? false,
              onTap: canAccessPurchasing
                  ? () => context.push('/reception')
                  : null,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasAccess;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hasAccess,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = hasAccess && onTap != null;
    final textColor = isEnabled ? AppColors.slate800 : AppColors.gray400;
    final iconBgColor = isEnabled
        ? theme.colorScheme.primary.withAlpha(26)
        : AppColors.gray200;
    final iconColor = isEnabled
        ? theme.colorScheme.primary
        : AppColors.gray400;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isEnabled ? AppColors.slate500 : AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEnabled)
                    Icon(
                      IconMap.chevronRight,
                      color: AppColors.gray400,
                      size: 24,
                    )
                  else
                    Icon(
                      IconMap.lock,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

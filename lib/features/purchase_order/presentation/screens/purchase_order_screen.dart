import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../domain/models/models.dart';
import '../providers/purchase_order_provider.dart';

/// Purchase Order list screen
class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedStatus;

  static const _statusOptions = [
    {'value': '', 'label': 'Semua'},
    {'value': 'draft', 'label': 'Draft'},
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'approved', 'label': 'Disetujui'},
    {'value': 'rejected', 'label': 'Ditolak'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<PurchaseOrderNotifier>();
      notifier.loadPurchaseOrders(refresh: true);

      _scrollController.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = context.read<PurchaseOrderNotifier>();
      if (!notifier.state.isLoading && notifier.state.hasMore) {
        notifier.loadMore();
      }
    }
  }

  void _onSearch(String query) {
    context.read<PurchaseOrderNotifier>().applyFilters(
          search: query.isEmpty ? null : query,
          status: _selectedStatus?.isEmpty == true ? null : _selectedStatus,
        );
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<PurchaseOrderNotifier>().applyFilters(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          status: status?.isEmpty == true ? null : status,
        );
  }

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 140,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Purchase Order',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kode atau supplier...',
                    prefixIcon: Icon(IconMap.search, color: AppColors.gray400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(IconMap.close, color: AppColors.gray400),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearch,
                ),
              ),

              const SizedBox(height: 12),

              // Status filter chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statusOptions.length,
                  separatorBuilder: (_, sep) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final option = _statusOptions[index];
                    final isSelected = _selectedStatus == option['value'];
                    return _StatusChip(
                      label: option['label']!,
                      isSelected: isSelected,
                      onTap: () => _onStatusChanged(option['value']),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: Consumer<PurchaseOrderNotifier>(
                  builder: (context, notifier, child) {
                    final state = notifier.state;

                    if (state.isLoading && state.items.isEmpty) {
                      return Center(child: LoadingIndicator());
                    }

                    if (state.error != null && state.items.isEmpty) {
                      return _buildError(notifier);
                    }

                    if (state.items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildList(state.items, state.hasMore);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: _FAB(
            onPressed: () => context.push('/purchase-order/form'),
            icon: IconMap.plus,
            label: 'Buat PO',
          ),
        ),
      ),
    );
  }

  Widget _buildError(PurchaseOrderNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.errorOutline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 150,
              child: PrimaryButton(
                label: 'Coba Lagi',
                onPressed: () => notifier.loadPurchaseOrders(refresh: true),
              ),
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
          Icon(IconMap.shoppingCartOutline, size: 64, color: AppColors.slate300),
          SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada purchase order',
            style: TextStyle(fontSize: 16, color: AppColors.slate500),
          ),
          SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk membuat baru',
            style: TextStyle(fontSize: 14, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PurchaseOrder> items, bool hasMore) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LoadingIndicator(),
            ),
          );
        }
        return _buildCard(items[index]);
      },
    );
  }

  Widget _buildCard(PurchaseOrder po) {
    final statusColor = _getStatusColor(po.status);
    final statusBg = _getStatusBg(po.status);

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
          onTap: () => context.push('/purchase-order/${po.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            po.code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            po.formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        po.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (po.supplier != null && po.supplier!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(IconMap.business, size: 16, color: AppColors.gray400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          po.supplier!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.slate500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      po.formattedTotal,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(IconMap.inventoryOutline, size: 14, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          '${po.details.length} item',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'pending':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'approved':
        return AppColors.successBg;
      case 'rejected':
        return AppColors.dangerBg;
      case 'pending':
        return AppColors.infoBg;
      default:
        return AppColors.warningBg;
    }
  }
}

/// Custom status chip widget
class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(26) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.slate200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.slate600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom FAB widget
class _FAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _FAB({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

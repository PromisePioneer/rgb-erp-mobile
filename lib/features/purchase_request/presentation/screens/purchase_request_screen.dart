import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../domain/models/models.dart';
import '../providers/purchase_request_provider.dart';

/// Purchase Request list screen
class PurchaseRequestScreen extends StatefulWidget {
  const PurchaseRequestScreen({super.key});

  @override
  State<PurchaseRequestScreen> createState() => _PurchaseRequestScreenState();
}

class _PurchaseRequestScreenState extends State<PurchaseRequestScreen> {
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
      final notifier = context.read<PurchaseRequestNotifier>();
      notifier.loadPurchaseRequests(refresh: true);

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
      final notifier = context.read<PurchaseRequestNotifier>();
      if (!notifier.state.isLoading && notifier.state.hasMore) {
        notifier.loadMore();
      }
    }
  }

  void _onSearch(String query) {
    context.read<PurchaseRequestNotifier>().applyFilters(
          search: query.isEmpty ? null : query,
          status: _selectedStatus?.isEmpty == true ? null : _selectedStatus,
        );
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<PurchaseRequestNotifier>().applyFilters(
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Purchase Request',
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
                    prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.slate400),
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
                    return FilterChip(
                      label: Text(option['label']!),
                      selected: isSelected,
                      onSelected: (_) => _onStatusChanged(option['value']),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary.withAlpha(26),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.slate600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.slate200,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: Consumer<PurchaseRequestNotifier>(
                  builder: (context, notifier, child) {
                    final state = notifier.state;

                    if (state.isLoading && state.items.isEmpty) {
                      return const Center(child: LoadingIndicator());
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
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/purchase-request/form'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Buat PR'),
          ),
        ),
      ),
    );
  }

  Widget _buildError(PurchaseRequestNotifier notifier) {
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
              onPressed: () => notifier.loadPurchaseRequests(refresh: true),
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
          Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.slate300),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Belum ada purchase request',
            style: TextStyle(fontSize: 16, color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tekan tombol + untuk membuat baru',
            style: TextStyle(fontSize: 14, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PurchaseRequest> items, bool hasMore) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
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

  Widget _buildCard(PurchaseRequest pr) {
    final statusColor = _getStatusColor(pr.status);
    final statusBg = _getStatusBg(pr.status);

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
          onTap: () => context.push('/purchase-request/${pr.id}'),
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
                            pr.code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pr.formattedDate,
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
                        pr.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (pr.supplier != null && pr.supplier!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: AppColors.slate400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pr.supplier!,
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
                      pr.formattedTotal,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          '${pr.details.length} item',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate400,
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

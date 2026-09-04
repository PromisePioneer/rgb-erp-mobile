import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../domain/models/models.dart';
import '../providers/purchase_request_provider.dart';

/// Purchase Request detail screen
class PurchaseRequestDetailScreen extends StatefulWidget {
  final int purchaseRequestId;

  const PurchaseRequestDetailScreen({super.key, required this.purchaseRequestId});

  @override
  State<PurchaseRequestDetailScreen> createState() => _PurchaseRequestDetailScreenState();
}

class _PurchaseRequestDetailScreenState extends State<PurchaseRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseRequestNotifier>().loadDetail(widget.purchaseRequestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Detail Purchase Request'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        actions: [
          Consumer<PurchaseRequestNotifier>(
            builder: (context, notifier, child) {
              final item = notifier.state.selectedItem;
              if (item == null || !item.canEdit) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/purchase-request/form?edit=${item.id}');
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, notifier);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.danger),
                        SizedBox(width: 12),
                        Text('Hapus', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<PurchaseRequestNotifier>(
        builder: (context, notifier, child) {
          if (notifier.state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifier.state.error != null && notifier.state.selectedItem == null) {
            return _buildError(notifier);
          }

          final item = notifier.state.selectedItem;
          if (item == null) {
            return _buildEmptyState();
          }

          return _buildContent(item, notifier);
        },
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
              onPressed: () => notifier.loadDetail(widget.purchaseRequestId),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.slate300),
          SizedBox(height: AppSpacing.md),
          Text(
            'Purchase request tidak ditemukan',
            style: TextStyle(fontSize: 16, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PurchaseRequest item, PurchaseRequestNotifier notifier) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              _buildHeaderCard(item),
              const SizedBox(height: 16),

              // Details card
              _buildDetailsCard(item),
              const SizedBox(height: 16),

              // Approval timeline
              if (item.approvals.isNotEmpty) ...[
                _buildApprovalCard(item),
                const SizedBox(height: 16),
              ],

              // Submit button
              if (item.canSubmit) _buildSubmitSection(notifier),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(PurchaseRequest item) {
    final statusColor = _getStatusColor(item.status);
    final statusBg = _getStatusBg(item.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.slate400),
              const SizedBox(width: 8),
              Text(
                item.formattedDate,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
          if (item.supplier != null && item.supplier!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: AppColors.slate400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.supplier!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
              Text(
                item.formattedTotal,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(PurchaseRequest item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.slate600),
              const SizedBox(width: 8),
              const Text(
                'Daftar Produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
              const Spacer(),
              Text(
                '${item.details.length} item',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...item.details.map((detail) => _buildDetailItem(detail)),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 16, color: AppColors.slate400),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keterangan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(PurchaseRequestDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.productName ?? 'Produk #${detail.productId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${detail.formattedQty} x ${detail.formattedTotal}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            detail.formattedTotal,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(PurchaseRequest item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.approval, size: 20, color: AppColors.slate600),
              SizedBox(width: 8),
              Text(
                'Riwayat Persetujuan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...item.approvals.asMap().entries.map((entry) {
            final index = entry.key;
            final approval = entry.value;
            final isLast = index == item.approvals.length - 1;
            return _buildApprovalTimeline(approval, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildApprovalTimeline(PurchaseRequestApproval approval, bool isLast) {
    final isPending = approval.isPending;
    final isApproved = approval.isApproved;
    final isRejected = approval.isRejected;

    Color dotColor;
    IconData? icon;

    if (isApproved) {
      dotColor = AppColors.success;
      icon = Icons.check;
    } else if (isRejected) {
      dotColor = AppColors.danger;
      icon = Icons.close;
    } else if (isPending) {
      dotColor = AppColors.warning;
      icon = Icons.schedule;
    } else {
      dotColor = AppColors.slate300;
      icon = null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: dotColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? Icon(icon, size: 16, color: dotColor)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.slate200,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${approval.level}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  approval.statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: dotColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (approval.formattedActedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    approval.formattedActedAt!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
                if (approval.note != null && approval.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    approval.note!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitSection(PurchaseRequestNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ajukan untuk persetujuan?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: notifier.state.isSubmitting
                ? null
                : () => _submitForApproval(notifier),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.slate300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: notifier.state.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Ajukan Persetujuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          if (notifier.state.submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              notifier.state.submitError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitForApproval(PurchaseRequestNotifier notifier) async {
    final success = await notifier.submitForApproval(widget.purchaseRequestId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase request berhasil diajukan untuk persetujuan'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.state.submitError ?? 'Gagal mengajukan'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, PurchaseRequestNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Purchase Request?'),
        content: const Text(
          'Purchase request akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await notifier.deletePurchaseRequest(widget.purchaseRequestId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Purchase request berhasil dihapus'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(notifier.state.deleteError ?? 'Gagal menghapus'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
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

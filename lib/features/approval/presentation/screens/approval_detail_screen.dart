import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../domain/models/approval.dart';
import '../providers/approval_provider.dart';

/// Approval detail screen with approve/reject actions
class ApprovalDetailScreen extends StatelessWidget {
  final Approval approval;

  const ApprovalDetailScreen({super.key, required this.approval});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Detail Persetujuan'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: Consumer<ApprovalNotifier>(
        builder: (context, notifier, child) {
          final state = notifier.state;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(approval),
              const SizedBox(height: 16),
              _buildRequestInfo(approval),
              if (approval.requestDetails != null) ...[
                const SizedBox(height: 16),
                _buildItemsList(approval.requestDetails!),
              ],
              const SizedBox(height: 16),
              _buildNotes(approval),
              const SizedBox(height: 24),
              _buildActions(context, notifier, approval, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Approval approval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTypeIcon(approval.type),
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.typeLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                if (approval.request?.code != null)
                  Text(
                    approval.request!.code!,
                    style: const TextStyle(fontSize: 14, color: AppColors.slate500),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Level ${approval.level}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestInfo(Approval approval) {
    final total = approval.requestDetails?.total ?? approval.request?.total ?? approval.amount;

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
              Icon(Icons.info_outline, size: 20, color: AppColors.slate600),
              SizedBox(width: 8),
              Text(
                'Informasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRow('Tipe', approval.typeLabel),
          if (approval.request?.code != null) _buildRow('Kode', approval.request!.code!),
          if (approval.requestDetails?.purchaseRequestCode != null)
            _buildRow('Kode PR', approval.requestDetails!.purchaseRequestCode!),
          if (approval.requestDetails?.supplier != null)
            _buildRow('Supplier', approval.requestDetails!.supplier!),
          if (approval.requester != null)
            _buildRow('Pengaju', approval.requester!.name),
          if (approval.formattedRequestDate != null)
            _buildRow('Tanggal', approval.formattedRequestDate!),
          if (approval.reason != null && approval.reason!.isNotEmpty)
            _buildRow('Alasan', approval.reason!),
          if (total != null) ...[
            const Divider(height: 16),
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
                  approval.requestDetails?.formattedTotal ?? approval.formattedAmount,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.slate500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildItemsList(ApprovalRequestDetails details) {
    if (details.items.isEmpty) return const SizedBox.shrink();

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
                '${details.items.length} item',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(ApprovalItem item) {
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
                  item.productName ?? 'Produk',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.formattedQty} x ${item.formattedTotal}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.formattedTotal,
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

  Widget _buildNotes(Approval approval) {
    final notes = approval.requestDetails?.notes ?? approval.reason;
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

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
              Icon(Icons.notes, size: 20, color: AppColors.slate600),
              SizedBox(width: 8),
              Text(
                'Keterangan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ApprovalNotifier notifier,
    Approval approval,
    ApprovalState state,
  ) {
    // Only show action buttons for pending approvals
    if (!approval.isPending) {
      return _buildStatusResult(approval);
    }

    return Column(
      children: [
        if (state.actError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(state.actError!, style: const TextStyle(color: AppColors.danger))),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isActing
                    ? null
                    : () => _showRejectDialog(context, notifier, approval),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tolak',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: state.isActing
                    ? null
                    : () => _act(context, notifier, approval, true, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isActing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Setujui'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusResult(Approval approval) {
    final isApproved = approval.isApproved;
    final color = isApproved ? AppColors.success : AppColors.danger;
    final bg = isApproved ? AppColors.successBg : AppColors.dangerBg;
    final icon = isApproved ? Icons.check_circle : Icons.cancel;
    final label = isApproved ? 'Disetujui' : 'Ditolak';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (approval.formattedActedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              '• ${approval.formattedActedAt}',
              style: TextStyle(
                fontSize: 14,
                color: color.withAlpha(179),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ApprovalNotifier notifier, Approval approval) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Persetujuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan penolakan (opsional):'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Keterangan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _act(context, notifier, approval, false, noteController.text.isNotEmpty ? noteController.text : null);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    ApprovalNotifier notifier,
    Approval approval,
    bool approve,
    String? note,
  ) async {
    final success = approve
        ? await notifier.approve(approval.id, note: note)
        : await notifier.reject(approval.id, note: note);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Disetujui' : 'Ditolak'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('Purchase') || type.contains('purchase')) {
      return Icons.shopping_cart;
    } else if (type.contains('Leave') || type.contains('Cuti')) {
      return Icons.beach_access;
    } else if (type.contains('Expense') || type.contains('Biaya')) {
      return Icons.receipt_long;
    }
    return Icons.approval;
  }
}

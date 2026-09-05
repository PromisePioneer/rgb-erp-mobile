import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
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
        title: Text('Detail Persetujuan'),
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
          Row(
            children: [
              Icon(IconMap.infoOutline, size: 20, color: AppColors.slate600),
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
                Text(
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
              Icon(IconMap.inventory, size: 20, color: AppColors.slate600),
              const SizedBox(width: 8),
              Text(
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
          Row(
            children: [
              Icon(IconMap.notes, size: 20, color: AppColors.slate600),
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
                Icon(IconMap.errorOutline, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(state.actError!, style: const TextStyle(color: AppColors.danger))),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Tolak',
                isDanger: true,
                isLoading: state.isActing,
                onPressed: () => _showRejectDialog(context, notifier, approval),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FButton(
                  onPress: state.isActing
                      ? null
                      : () => _act(context, notifier, approval, true, null),
                  variant: FButtonVariant.primary,
                  child: state.isActing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingIndicator(
                          ),
                        )
                      : Text('Setujui'),
                ),
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
    final icon = isApproved ? IconMap.checkCircle : IconMap.cancel;
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tolak Persetujuan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Berikan alasan penolakan (opsional):',
                style: TextStyle(color: AppColors.slate600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Keterangan...',
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 40,
                    child: FButton(
                      onPress: () => Navigator.pop(dialogContext),
                      variant: FButtonVariant.ghost,
                      child: Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: FButton(
                      onPress: () {
                        Navigator.pop(dialogContext);
                        _act(context, notifier, approval, false, noteController.text.isNotEmpty ? noteController.text : null);
                      },
                      variant: FButtonVariant.destructive,
                      child: Text('Tolak'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      return IconMap.shoppingCart;
    } else if (type.contains('Leave') || type.contains('Cuti')) {
      return IconMap.beachAccess;
    } else if (type.contains('Expense') || type.contains('Biaya')) {
      return IconMap.receipt;
    }
    return IconMap.checklist;
  }
}

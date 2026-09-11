import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/models.dart';
import '../providers/reception_provider.dart';

/// Reception detail screen
class ReceptionDetailScreen extends StatefulWidget {
  final int receptionId;

  const ReceptionDetailScreen({super.key, required this.receptionId});

  @override
  State<ReceptionDetailScreen> createState() => _ReceptionDetailScreenState();
}

class _ReceptionDetailScreenState extends State<ReceptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceptionNotifier>().loadDetail(widget.receptionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: Text('Detail Penerimaan'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        actions: [
          Consumer<ReceptionNotifier>(
            builder: (context, notifier, child) {
              final item = notifier.state.selectedItem;
              if (item == null || !item.canEdit) return SizedBox.shrink();

              return _MoreMenu(
                onEdit: () => context.push('/reception/form?edit=${item.id}'),
                onDelete: () => _showDeleteDialog(context, notifier),
              );
            },
          ),
        ],
      ),
      body: Consumer<ReceptionNotifier>(
        builder: (context, notifier, child) {
          if (notifier.state.isLoading) {
            return Center(child: LoadingIndicator());
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

  Widget _buildError(ReceptionNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.errorOutline, size: 64, color: AppColors.danger),
            SizedBox(height: AppSpacing.md),
            Text(
              notifier.state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500),
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 150,
              child: PrimaryButton(
                label: 'Coba Lagi',
                onPressed: () => notifier.loadDetail(widget.receptionId),
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
          Icon(IconMap.searchOff, size: 64, color: AppColors.slate300),
          SizedBox(height: AppSpacing.md),
          Text(
            'Penerimaan tidak ditemukan',
            style: TextStyle(fontSize: 16, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Reception item, ReceptionNotifier notifier) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              _buildHeaderCard(item),
              SizedBox(height: 16),

              // Details card
              _buildDetailsCard(item),
              SizedBox(height: 16),

              // Approval timeline
              if (item.approvals.isNotEmpty) ...[
                _buildApprovalCard(item),
                SizedBox(height: 16),
              ],

              // Submit button
              if (item.canSubmit) _buildSubmitSection(notifier),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(Reception item) {
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
          SizedBox(height: 12),
          Row(
            children: [
              Icon(IconMap.calendarToday, size: 16, color: AppColors.gray400),
              SizedBox(width: 8),
              Text(
                item.formattedDate,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
          if (item.purchaseOrderCode != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(IconMap.link, size: 16, color: AppColors.gray400),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PO: ${item.purchaseOrderCode}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (item.supplier != null && item.supplier!.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(IconMap.business, size: 16, color: AppColors.gray400),
                SizedBox(width: 8),
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
          if (item.warehouseName != null && item.warehouseName!.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(IconMap.warehouse, size: 16, color: AppColors.gray400),
                SizedBox(width: 8),
                Text(
                  'Gudang: ${item.warehouseName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
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

  Widget _buildDetailsCard(Reception item) {
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
              Icon(IconMap.inventoryOutline, size: 20, color: AppColors.slate600),
              SizedBox(width: 8),
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
                '${item.details.length} item',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...item.details.map((detail) => _buildDetailItem(detail)),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconMap.notes, size: 16, color: AppColors.gray400),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keterangan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
                      SizedBox(height: 4),
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

  Widget _buildDetailItem(ReceptionDetail detail) {
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
                SizedBox(height: 2),
                Text(
                  '${detail.formattedQty} x ${detail.formattedUnitCost}',
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

  Widget _buildApprovalCard(Reception item) {
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
              Icon(IconMap.checklist, size: 20, color: AppColors.slate600),
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
          SizedBox(height: 16),
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

  Widget _buildApprovalTimeline(ReceptionApproval approval, bool isLast) {
    final isPending = approval.isPending;
    final isApproved = approval.isApproved;
    final isRejected = approval.isRejected;

    Color dotColor;
    IconData icon;

    if (isApproved) {
      dotColor = AppColors.success;
      icon = IconMap.check;
    } else if (isRejected) {
      dotColor = AppColors.danger;
      icon = IconMap.close;
    } else if (isPending) {
      dotColor = AppColors.warning;
      icon = IconMap.schedule;
    } else {
      dotColor = AppColors.slate300;
      icon = IconMap.circle;
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
              child: Icon(icon, size: 16, color: dotColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.slate200,
              ),
          ],
        ),
        SizedBox(width: 12),
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
                SizedBox(height: 2),
                Text(
                  approval.statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: dotColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (approval.formattedActedAt != null) ...[
                  SizedBox(height: 4),
                  Text(
                    approval.formattedActedAt!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
                if (approval.note != null && approval.note!.isNotEmpty) ...[
                  SizedBox(height: 4),
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

  Widget _buildSubmitSection(ReceptionNotifier notifier) {
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
          Text(
            'Ajukan untuk persetujuan?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FButton(
              onPress: notifier.state.isSubmitting
                  ? null
                  : () => _submitForApproval(notifier),
              variant: FButtonVariant.primary,
              child: notifier.state.isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: LoadingIndicator(),
                    )
                  : Text(
                      'Ajukan Persetujuan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          if (notifier.state.submitError != null) ...[
            SizedBox(height: 8),
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

  Future<void> _submitForApproval(ReceptionNotifier notifier) async {
    final success = await notifier.submitForApproval(widget.receptionId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penerimaan berhasil diajukan untuk persetujuan'),
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

  void _showDeleteDialog(BuildContext context, ReceptionNotifier notifier) {
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
            children: [
              Icon(
                IconMap.warning,
                size: 48,
                color: AppColors.danger,
              ),
              SizedBox(height: 16),
              Text(
                'Hapus Penerimaan?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Penerimaan akan dihapus. Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate500,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FButton(
                        onPress: () => Navigator.pop(dialogContext),
                        variant: FButtonVariant.outline,
                        child: Text('Batal'),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FButton(
                        onPress: () async {
                          Navigator.pop(dialogContext);
                          final success = await notifier.deleteReception(widget.receptionId);
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Penerimaan berhasil dihapus'),
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
                        variant: FButtonVariant.destructive,
                        child: Text('Hapus'),
                      ),
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

/// More menu popup
class _MoreMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MoreMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(IconMap.moreVertical),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(IconMap.pencil, size: 20, color: AppColors.slate600),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(IconMap.delete, size: 20, color: AppColors.danger),
              SizedBox(width: 12),
              Text('Hapus', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}

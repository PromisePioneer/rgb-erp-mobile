import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../domain/entities/korwil_visit_entity.dart';
import '../providers/korwil_visit_provider.dart';

/// Korwil Visit Detail Screen
class KorwilVisitDetailScreen extends StatefulWidget {
  final int visitId;

  const KorwilVisitDetailScreen({super.key, required this.visitId});

  @override
  State<KorwilVisitDetailScreen> createState() => _KorwilVisitDetailScreenState();
}

class _KorwilVisitDetailScreenState extends State<KorwilVisitDetailScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<KorwilVisitNotifier>().loadVisitDetail(widget.visitId);
  }

  Future<void> _submitVisit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Laporan'),
        content: const Text(
          'Setelah disubmit, laporan tidak dapat diedit lagi. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FButton(
            onPress: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    final success = await context.read<KorwilVisitNotifier>().submitVisit(widget.visitId);

    if (success && mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil disubmit')),
      );
      // Reload detail to get updated data
      await _loadData();
    } else if (mounted) {
      setState(() => _isSubmitting = false);
      final error = context.read<KorwilVisitNotifier>().state.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal submit laporan')),
      );
    }
  }

  Future<void> _deleteVisit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kunjungan'),
        content: const Text('Apakah Anda yakin ingin menghapus kunjungan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<KorwilVisitNotifier>().deleteVisit(widget.visitId);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kunjungan'),
        actions: [
          Consumer<KorwilVisitNotifier>(
            builder: (context, notifier, _) {
              if (notifier.state.selectedVisit == null) return const SizedBox();

              final visit = notifier.state.selectedVisit!;
              final menuItems = <PopupMenuEntry<String>>[];

              // Only show edit if can_edit is true
              if (visit.canEdit) {
                menuItems.add(
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(IconMap.edit, size: 20),
                        const SizedBox(width: 8),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                );
              }

              // Delete is only allowed for draft
              if (visit.isDraft) {
                menuItems.add(
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(IconMap.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                );
              }

              if (menuItems.isEmpty) return const SizedBox();

              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/korwil-visit/${widget.visitId}/edit');
                  } else if (value == 'delete') {
                    _deleteVisit();
                  }
                },
                itemBuilder: (context) => menuItems,
              );
            },
          ),
        ],
      ),
      body: Consumer<KorwilVisitNotifier>(
        builder: (context, notifier, _) {
          if (notifier.state.isLoading && notifier.state.selectedVisit == null) {
            return const Center(child: LoadingIndicator());
          }

          if (notifier.state.error != null && notifier.state.selectedVisit == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.errorOutline, size: 64, color: AppColors.slate300),
                  const SizedBox(height: 16),
                  Text(
                    notifier.state.error!,
                    style: const TextStyle(color: AppColors.slate500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: _loadData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final visit = notifier.state.selectedVisit;
          if (visit == null) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildContent(visit),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<KorwilVisitNotifier>(
        builder: (context, notifier, _) {
          if (notifier.state.selectedVisit == null) return const SizedBox.shrink();

          final visit = notifier.state.selectedVisit!;

          // Show submit button only if draft and not submitting
          if (!visit.isDraft || _isSubmitting) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.card,
            ),
            child: SafeArea(
              child: FButton(
                onPress: _submitVisit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Laporan'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(KorwilVisitEntity visit) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          _buildStatusBadge(visit),
          const SizedBox(height: 16),

          // Client info card
          _buildClientCard(visit),
          const SizedBox(height: 16),

          // Time info card
          _buildTimeCard(visit),
          const SizedBox(height: 16),

          // Notes
          if (visit.clientNote != null || visit.fieldFindings != null)
            _buildNotesCard(visit),

          // Media
          if (visit.photos.isNotEmpty || visit.videos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMediaCard(visit),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(KorwilVisitEntity visit) {
    final isDraft = visit.isDraft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDraft ? AppColors.amber100 : AppColors.success.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDraft ? AppColors.amber400 : AppColors.success,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDraft ? IconMap.edit : IconMap.checkCircle,
            size: 16,
            color: isDraft ? AppColors.amber600 : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            visit.submissionStatusLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDraft ? AppColors.amber600 : AppColors.success,
            ),
          ),
          if (!visit.canEdit && !isDraft) ...[
            const SizedBox(width: 8),
            Text(
              '- Tidak dapat diedit',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.slate500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(KorwilVisitEntity visit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.rgbPrimary.withAlpha(26),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  IconMap.business,
                  color: AppColors.rgbPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.clientName ?? 'Klien',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                    ),
                    if (visit.clientAddress != null)
                      Text(
                        visit.clientAddress!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(IconMap.locationOn, size: 18, color: AppColors.slate400),
              const SizedBox(width: 8),
              const Text('Area: ', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
              Expanded(
                child: Text(
                  visit.areaName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate800),
                ),
              ),
            ],
          ),
          if (visit.position != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(IconMap.person, size: 18, color: AppColors.slate400),
                const SizedBox(width: 8),
                const Text('Posisi: ', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                Expanded(
                  child: Text(
                    visit.position!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate800),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCard(KorwilVisitEntity visit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(IconMap.login, color: AppColors.success, size: 24),
                const SizedBox(height: 8),
                const Text('Waktu Masuk', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                const SizedBox(height: 4),
                Text(
                  visit.inTime != null
                      ? '${visit.inTime!.day}/${visit.inTime!.month}/${visit.inTime!.year}\n${visit.inTime!.hour.toString().padLeft(2, '0')}:${visit.inTime!.minute.toString().padLeft(2, '0')}'
                      : '--/--/---- --:--',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate800),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: AppColors.slate200),
          Expanded(
            child: Column(
              children: [
                Icon(IconMap.logout, color: AppColors.rgbPrimary, size: 24),
                const SizedBox(height: 8),
                const Text('Waktu Pulang', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                const SizedBox(height: 4),
                Text(
                  visit.outTime != null
                      ? '${visit.outTime!.day}/${visit.outTime!.month}/${visit.outTime!.year}\n${visit.outTime!.hour.toString().padLeft(2, '0')}:${visit.outTime!.minute.toString().padLeft(2, '0')}'
                      : '--/--/---- --:--',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate800),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(KorwilVisitEntity visit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate800)),
          const SizedBox(height: 16),
          if (visit.clientNote != null) ...[
            const Text('Catatan Klien', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate600)),
            const SizedBox(height: 4),
            Text(visit.clientNote!, style: const TextStyle(fontSize: 14, color: AppColors.slate700)),
            const SizedBox(height: 12),
          ],
          if (visit.fieldFindings != null) ...[
            const Text('Temuan Lapangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate600)),
            const SizedBox(height: 4),
            Text(visit.fieldFindings!, style: const TextStyle(fontSize: 14, color: AppColors.slate700)),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaCard(KorwilVisitEntity visit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Foto & Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate800)),
              const Spacer(),
              Text(
                '${visit.photos.length} foto, ${visit.videos.length} video',
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visit.photos.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visit.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final photo = visit.photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo.photoUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: AppColors.slate200,
                        child: Icon(IconMap.photoLibrary),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

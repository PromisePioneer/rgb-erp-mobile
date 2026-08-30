import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../backup_offer/domain/models/backup_offer.dart';
import '../../../backup_offer/data/repositories/backup_offer_repository.dart';
import '../../../backup_offer/presentation/providers/backup_offer_provider.dart';

/// Screen for responding to backup offer notification
class BackupOfferScreen extends StatefulWidget {
  final String offerId;

  const BackupOfferScreen({super.key, required this.offerId});

  @override
  State<BackupOfferScreen> createState() => _BackupOfferScreenState();
}

class _BackupOfferScreenState extends State<BackupOfferScreen> {
  late final BackupOfferNotifier _notifier;
  BackupOffer? _offer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    final dio = ApiClientFactory(storage: storage).create();
    final repo = BackupOfferRepository(dio);
    _notifier = BackupOfferNotifier(repo);
    _loadOffer();
  }

  Future<void> _loadOffer() async {
    await _notifier.loadPendingOffers();
    final offers = _notifier.state.offers;
    final found = offers.where((o) => o.id == widget.offerId).firstOrNull;

    setState(() {
      _offer = found;
      _isLoading = false;
      if (found == null) {
        _error = 'Offer tidak ditemukan';
      }
    });
  }

  Future<void> _accept() async {
    setState(() => _isSubmitting = true);
    try {
      await _notifier.acceptOffer(widget.offerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup offer diterima'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _isSubmitting = true);
    try {
      await _notifier.rejectOffer(widget.offerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup offer ditolak'), backgroundColor: AppColors.warning),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawaran Backup Jaga'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(size: 32))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colors.destructive)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final theme = FTheme.of(context);
    final offer = _offer!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Center(
            child: Icon(IconMap.swapHoriz, size: 64, color: theme.colors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Center(
            child: Text(
              'Tawaran Backup Jaga',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Anda ditawari untuk jaga menggantikan',
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: AppRadius.radiusLg,
            ),
            child: Column(
              children: [
                _buildRow(IconMap.locationOn, 'Area', offer.areaName ?? '-'),
                const SizedBox(height: AppSpacing.md),
                _buildRow(IconMap.calendarToday, 'Tanggal', offer.date),
                const SizedBox(height: AppSpacing.md),
                _buildRow(IconMap.schedule, 'Shift', offer.shiftName ?? '-'),
                const SizedBox(height: AppSpacing.md),
                _buildRow(IconMap.place, 'POS', offer.posName ?? '-'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Expiry info
          if (offer.expiresAt != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Row(
                children: [
                  Icon(IconMap.timer, color: theme.colors.secondaryForeground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Berlaku hingga: ${_formatDateTime(offer.expiresAt!)}',
                      style: TextStyle(color: theme.colors.secondaryForeground),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // Buttons
          SizedBox(
            height: 50,
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'TOLAK',
                    onPressed: _isSubmitting ? null : _reject,
                    isDanger: true,
                    isLoading: _isSubmitting,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'TERIMA',
                    onPressed: _isSubmitting ? null : _accept,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    final theme = FTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colors.mutedForeground),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: TextStyle(color: theme.colors.mutedForeground)),
        Expanded(
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colors.foreground)),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

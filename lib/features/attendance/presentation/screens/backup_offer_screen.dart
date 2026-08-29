import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawaran Backup Jaga'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final offer = _offer!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          const Center(
            child: Icon(Icons.swap_horiz, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          const Center(
            child: Text(
              'Tawaran Backup Jaga',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Anda ditawari untuk jaga menggantikan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.sky50,
              borderRadius: AppRadius.radiusLg,
            ),
            child: Column(
              children: [
                _buildRow(Icons.location_on, 'Area', offer.areaName ?? '-'),
                const SizedBox(height: AppSpacing.md),
                _buildRow(Icons.calendar_today, 'Tanggal', offer.date),
                const SizedBox(height: AppSpacing.md),
                _buildRow(Icons.access_time, 'Shift', offer.shiftName ?? '-'),
                const SizedBox(height: AppSpacing.md),
                _buildRow(Icons.place, 'POS', offer.posName ?? '-'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Expiry info
          if (offer.expiresAt != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.amber200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.amber600),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Berlaku hingga: ${_formatDateTime(offer.expiresAt!)}',
                      style: const TextStyle(color: AppColors.amber600),
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
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('TOLAK'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('TERIMA'),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

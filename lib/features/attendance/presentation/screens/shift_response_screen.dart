import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
import '../../../backup_offer/domain/models/shift_response.dart';
import '../../../backup_offer/data/repositories/shift_response_repository.dart';
import '../../../backup_offer/presentation/providers/shift_response_provider.dart';

/// Screen for responding to shift reminder notification
class ShiftResponseScreen extends StatefulWidget {
  final String shiftId;

  const ShiftResponseScreen({super.key, required this.shiftId});

  @override
  State<ShiftResponseScreen> createState() => _ShiftResponseScreenState();
}

class _ShiftResponseScreenState extends State<ShiftResponseScreen> {
  late final ShiftResponseNotifier _notifier;
  PendingShiftResponse? _shift;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    final dio = ApiClientFactory(storage: storage).create();
    final repo = ShiftResponseRepository(dio);
    _notifier = ShiftResponseNotifier(repo);
    _loadShift();
  }

  Future<void> _loadShift() async {
    // Load pending responses to check if this shift exists and show details
    await _notifier.loadPendingResponses();
    final shifts = _notifier.state.pendingShifts;
    final found = shifts.where((s) => s.id == widget.shiftId).firstOrNull;

    setState(() {
      _shift = found;
      _isLoading = false;
      // Note: We don't show error even if not found - accept/reject will still work
      // The backend will validate if user has access to this schedule
    });
  }

  Future<void> _accept() async {
    setState(() => _isSubmitting = true);
    try {
      await _notifier.acceptShift(widget.shiftId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift berhasil dikonfirmasi'), backgroundColor: AppColors.success),
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
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _notifier.rejectShift(widget.shiftId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift ditolak'), backgroundColor: AppColors.warning),
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

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Contoh: Sakit, Urusan keluarga, dll',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Harap isi alasan')),
                );
                return;
              }
              Navigator.pop(ctx, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Jadwal Shift'),
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
    final shift = _shift;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.sky50,
              borderRadius: AppRadius.radiusLg,
            ),
            child: shift != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow(Icons.calendar_today, 'Tanggal', shift.date),
                      const SizedBox(height: AppSpacing.sm),
                      if (shift.areaName != null) _buildRow(Icons.location_on, 'Area', shift.areaName!),
                      if (shift.posName != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildRow(Icons.place, 'POS', shift.posName!),
                      ],
                      if (shift.shiftName != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildRow(Icons.access_time, 'Shift', shift.shiftName!),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _buildRow(Icons.schedule, 'Jam Mulai', shift.shiftStartTime),
                    ],
                  )
                : const Text(
                    'Loading shift details...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Warning
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.amber50,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.amber200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.amber600),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Jika ditolak, sistem akan mencari backup secara otomatis.',
                    style: TextStyle(color: AppColors.amber600, fontSize: 13),
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
}

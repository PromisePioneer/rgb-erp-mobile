import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/notification/notification_helper.dart';
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
        NotificationHelper.showSuccess(context, 'Shift berhasil dikonfirmasi');
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        NotificationHelper.showError(context, 'Error: $e');
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
        NotificationHelper.showWarning(context, 'Shift ditolak');
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        NotificationHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    String? errorText;

    return showFDialog<String>(
      context: context,
      builder: (context, style, animation) => FDialog(
        builder: (context, dialogStyle) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alasan Penolakan',
              style: dialogStyle.titleTextStyle,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: controller,
              hint: 'Contoh: Sakit, Urusan keluarga, dll',
              maxLines: 3,
              errorText: errorText,
              onChanged: (_) {
                if (errorText != null) {
                  setState(() => errorText = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () => Navigator.pop(context),
                    variant: FButtonVariant.ghost,
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FButton(
                    onPress: () {
                      final reason = controller.text.trim();
                      if (reason.isEmpty) {
                        setState(() => errorText = 'Harap isi alasan');
                        return;
                      }
                      Navigator.pop(context, reason);
                    },
                    variant: FButtonVariant.destructive,
                    child: const Text('Tolak'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Konfirmasi Jadwal Shift',
          style: TextStyle(color: theme.colors.foreground),
        ),
        leading: IconButton(
          icon: Icon(IconMap.close, color: theme.colors.foreground),
          onPressed: () => context.pop(),
        ),
        backgroundColor: theme.colors.background,
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
    final shift = _shift;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info Card
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: shift != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow(IconMap.calendarToday, 'Tanggal', shift.date),
                        const SizedBox(height: AppSpacing.sm),
                        if (shift.areaName != null) _buildRow(IconMap.locationOn, 'Area', shift.areaName!),
                        if (shift.posName != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _buildRow(IconMap.place, 'POS', shift.posName!),
                        ],
                        if (shift.shiftName != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _buildRow(IconMap.schedule, 'Shift', shift.shiftName!),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _buildRow(IconMap.accessTime, 'Jam Mulai', shift.shiftStartTime),
                      ],
                    )
                  : Text(
                      'Loading shift details...',
                      style: TextStyle(color: theme.colors.mutedForeground),
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Warning
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(
              children: [
                Icon(IconMap.infoOutline, color: theme.colors.secondaryForeground),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Jika ditolak, sistem akan mencari backup secara otomatis.',
                    style: TextStyle(color: theme.colors.secondaryForeground, fontSize: 13),
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
}

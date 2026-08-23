import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../providers/leave_provider.dart';

/// Leave form screen for submitting a new leave request
class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _reasonError;

  static const _leaveTypes = ['Cuti Tahunan', 'Sakit', 'Izin'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _selectedType != null &&
        _startDate != null &&
        _endDate != null &&
        _reasonController.text.trim().isNotEmpty;
  }

  String? _validateEndDate() {
    if (_endDate == null || _startDate == null) return null;
    if (_endDate!.isBefore(_startDate!)) {
      return 'Tanggal selesai harus >= tanggal mulai';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates client-side
    if (_startDate == null || _endDate == null) return;
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _reasonError = 'Tanggal selesai harus >= tanggal mulai');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonError = 'Keterangan wajib diisi');
      return;
    }

    final notifier = context.read<LeaveNotifier>();
    final success = await notifier.submitLeave(
      type: _selectedType!,
      startDate: _startDate!,
      endDate: _endDate!,
      reason: reason,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengajuan cuti berhasil'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.state.submitError ?? 'Gagal mengajukan cuti'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Mulai',
      confirmText: 'Pilih',
      cancelText: 'Batal',
    );
    if (date == null) return;
    setState(() {
      _startDate = date;
      _reasonError = null;
    });
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Selesai',
      confirmText: 'Pilih',
      cancelText: 'Batal',
    );
    if (date == null) return;
    setState(() {
      _endDate = date;
      _reasonError = _validateEndDate();
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<LeaveNotifier>();
    final isSubmitting = notifier.state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Ajukan Cuti'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  hint: const Text('Pilih tipe cuti'),
                  isExpanded: true,
                  items: _leaveTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (v) => setState(() {
                            _selectedType = v;
                            _reasonError = null;
                          }),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start date
            _buildDateField(
              label: 'Tanggal Mulai',
              value: _startDate != null ? _formatDate(_startDate!) : null,
              onTap: isSubmitting ? null : _pickStartDate,
            ),
            const SizedBox(height: 16),

            // End date
            _buildDateField(
              label: 'Tanggal Selesai',
              value: _endDate != null ? _formatDate(_endDate!) : null,
              onTap: isSubmitting ? null : _pickEndDate,
              error: _reasonError,
            ),
            const SizedBox(height: 16),

            // Reason text field
            TextFormField(
              controller: _reasonController,
              enabled: !isSubmitting,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Keterangan cuti...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() => _reasonError = null),
              validator: (_) => null,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting || !_canSubmit ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.slate300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ajukan Cuti',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    String? value,
    VoidCallback? onTap,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: error != null ? Border.all(color: AppColors.danger) : null,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.slate400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 16,
                      color: value == null ? AppColors.slate400 : AppColors.slate800,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 24, color: AppColors.slate400),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(fontSize: 12, color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

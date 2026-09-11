import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/inputs/async_select_field.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../providers/fund_request_provider.dart';

/// Fund Request form screen for create/edit
class FundRequestFormScreen extends StatefulWidget {
  final int? editId;

  const FundRequestFormScreen({super.key, this.editId});

  @override
  State<FundRequestFormScreen> createState() => _FundRequestFormScreenState();
}

class _FundRequestFormScreenState extends State<FundRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _requestedAmountController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _paymentTermController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();

  PurchaseOrderOption? _selectedPurchaseOrder;
  String? _formError;
  bool _isInitialized = false;

  bool get _isEditing => widget.editId != null;
  bool get _canSubmit {
    return _selectedPurchaseOrder != null &&
        _requestedAmountController.text.isNotEmpty &&
        double.tryParse(_requestedAmountController.text.replaceAll(',', '')) != null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadForEdit();
      }
    });
  }

  @override
  void dispose() {
    _requestedAmountController.dispose();
    _taxAmountController.dispose();
    _paymentTermController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountNameController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    if (_isInitialized) return;
    setState(() {});

    final notifier = context.read<FundRequestNotifier>();
    await notifier.loadDetail(widget.editId!);

    final item = notifier.state.selectedItem;
    if (item != null && mounted) {
      setState(() {
        _requestedAmountController.text = item.requestedAmount.toStringAsFixed(0);
        _taxAmountController.text = item.taxAmount > 0 ? item.taxAmount.toStringAsFixed(0) : '';
        _paymentTermController.text = item.paymentTerm ?? '';
        _bankNameController.text = item.bankName ?? '';
        _bankAccountNumberController.text = item.bankAccountNumber ?? '';
        _bankAccountNameController.text = item.bankAccountName ?? '';
        _paymentMethodController.text = item.paymentMethod ?? '';
        _notesController.text = item.notes ?? '';
        _isInitialized = true;
      });
    }
  }

  Future<List<AsyncSelectOption>> _loadPurchaseOrders(String query) async {
    try {
      final notifier = context.read<FundRequestNotifier>();
      final options = await notifier.repository.getPurchaseOrderOptions(query: query);
      return options.map((p) => AsyncSelectOption(
        id: p.id.toString(),
        name: '${p.code} - Sisa: ${p.formattedRemaining}',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  void _onPurchaseOrderSelected(PurchaseOrderOption po) {
    setState(() {
      _selectedPurchaseOrder = po;
      _formError = null;
    });
  }

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPurchaseOrder == null) {
      setState(() => _formError = 'Purchase Order wajib dipilih');
      return;
    }

    final requestedAmount = double.tryParse(_requestedAmountController.text.replaceAll(',', ''));
    if (requestedAmount == null || requestedAmount <= 0) {
      setState(() => _formError = 'Jumlah yang diminta wajib diisi');
      return;
    }

    if (requestedAmount > _selectedPurchaseOrder!.remainingAmount) {
      setState(() => _formError = 'Jumlah melebihi sisa. Maksimal: ${_formatCurrency(_selectedPurchaseOrder!.remainingAmount)}');
      return;
    }

    final notifier = context.read<FundRequestNotifier>();

    final taxAmount = double.tryParse(_taxAmountController.text.replaceAll(',', '')) ?? 0;

    bool success;
    if (_isEditing) {
      success = await notifier.updateFundRequest(
        id: widget.editId!,
        requestedAmount: requestedAmount,
        taxAmount: taxAmount,
        paymentTerm: _paymentTermController.text.trim().isEmpty ? null : _paymentTermController.text.trim(),
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim().isEmpty ? null : _bankAccountNumberController.text.trim(),
        bankAccountName: _bankAccountNameController.text.trim().isEmpty ? null : _bankAccountNameController.text.trim(),
        paymentMethod: _paymentMethodController.text.trim().isEmpty ? null : _paymentMethodController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } else {
      success = await notifier.createFundRequest(
        poId: _selectedPurchaseOrder!.id,
        requestedAmount: requestedAmount,
        taxAmount: taxAmount,
        paymentTerm: _paymentTermController.text.trim().isEmpty ? null : _paymentTermController.text.trim(),
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim().isEmpty ? null : _bankAccountNumberController.text.trim(),
        bankAccountName: _bankAccountNameController.text.trim().isEmpty ? null : _bankAccountNameController.text.trim(),
        paymentMethod: _paymentMethodController.text.trim().isEmpty ? null : _paymentMethodController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Fund request berhasil diupdate' : 'Fund request berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.state.submitError ?? 'Gagal menyimpan'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<FundRequestNotifier>();
    final isSubmitting = notifier.state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Fund Request' : 'Buat Fund Request'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Purchase Order selector
                  _buildPurchaseOrderField(),
                  SizedBox(height: 16),

                  // Amount fields
                  _buildAmountFields(),
                  SizedBox(height: 24),

                  // Bank info section
                  _buildSectionHeader('Informasi Bank', IconMap.accountBalance),
                  SizedBox(height: 12),
                  _buildBankFields(),
                  SizedBox(height: 24),

                  // Notes field
                  _buildNotesField(),

                  if (_formError != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(IconMap.errorOutline, color: AppColors.danger, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formError!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: FButton(
              onPress: isSubmitting || !_canSubmit ? null : _submit,
              variant: FButtonVariant.primary,
              child: isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: LoadingIndicator(),
                    )
                  : Text(
                      _isEditing ? 'Update Fund Request' : 'Simpan Fund Request',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.slate600),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.slate800,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseOrderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase Order',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        SizedBox(height: 4),
        AsyncSelectField(
          label: null,
          placeholder: 'Cari purchase order...',
          loadOptions: _loadPurchaseOrders,
          selectedIds: _selectedPurchaseOrder != null
              ? {_selectedPurchaseOrder!.id.toString()}
              : <String>{},
          onSelectionChanged: (ids) async {
            if (ids.isEmpty) {
              setState(() => _selectedPurchaseOrder = null);
              return;
            }
            // Load full PO details
            try {
              final notifier = context.read<FundRequestNotifier>();
              final options = await notifier.repository.getPurchaseOrderOptions(
                query: ids.first,
              );
              final selected = options.where((p) => p.id.toString() == ids.first).firstOrNull;
              if (selected != null) {
                _onPurchaseOrderSelected(selected);
              }
            } catch (e) {
              // ignore
            }
          },
          multiSelect: false,
        ),
        if (_selectedPurchaseOrder != null) ...[
          SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total PO: ${_formatCurrency(_selectedPurchaseOrder!.total)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.slate600),
                ),
                SizedBox(height: 4),
                Text(
                  'Sisa: ${_formatCurrency(_selectedPurchaseOrder!.remainingAmount)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Jumlah', IconMap.accountBalanceWallet),
        SizedBox(height: 12),
        // Requested amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jumlah Diminta *',
              style: TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: _requestedAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Tax amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pajak (opsional)',
              style: TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: _taxAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Payment term
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termin Pembayaran (opsional)',
              style: TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: _paymentTermController,
              decoration: InputDecoration(
                hintText: 'Contoh: 30 hari',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      children: [
        // Bank name
        _buildTextField(_bankNameController, 'Nama Bank'),
        SizedBox(height: 12),
        // Account number
        _buildTextField(_bankAccountNumberController, 'Nomor Rekening', keyboardType: TextInputType.number),
        SizedBox(height: 12),
        // Account name
        _buildTextField(_bankAccountNameController, 'Nama Rekening'),
        SizedBox(height: 12),
        // Payment method
        _buildTextField(_paymentMethodController, 'Metode Pembayaran'),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Keterangan', IconMap.notes),
        SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Masukkan keterangan atau alasan...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

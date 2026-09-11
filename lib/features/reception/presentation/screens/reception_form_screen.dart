import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/inputs/async_select_field.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../data/repositories/reception_repository.dart';
import '../providers/reception_provider.dart';

/// Reception form screen for create/edit
class ReceptionFormScreen extends StatefulWidget {
  final int? editId;

  const ReceptionFormScreen({super.key, this.editId});

  @override
  State<ReceptionFormScreen> createState() => _ReceptionFormScreenState();
}

class _ReceptionFormScreenState extends State<ReceptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  PurchaseOrderForReception? _selectedPurchaseOrder;
  WarehouseOption? _selectedWarehouse;
  List<_LineItem> _lineItems = [_LineItem()];
  String? _formError;
  bool _isInitialized = false;

  bool get _isEditing => widget.editId != null;
  bool get _canSubmit {
    return _selectedDate != null &&
        _selectedPurchaseOrder != null &&
        _lineItems.isNotEmpty &&
        _lineItems.every((item) => item.productId != null && item.qty > 0);
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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    if (_isInitialized) return;
    setState(() {});

    final notifier = context.read<ReceptionNotifier>();
    await notifier.loadDetail(widget.editId!);

    final item = notifier.state.selectedItem;
    if (item != null && mounted) {
      setState(() {
        _selectedDate = DateTime.tryParse(item.date);
        _notesController.text = item.notes ?? '';
        _lineItems = item.details.map((d) => _LineItem(
          productId: d.productId,
          productName: d.productName,
          qty: d.qty,
          unitCost: d.unitCost,
        )).toList();
        if (_lineItems.isEmpty) _lineItems.add(_LineItem());
        _isInitialized = true;
      });
    }
  }

  Future<List<AsyncSelectOption>> _loadPurchaseOrders(String query) async {
    try {
      final notifier = context.read<ReceptionNotifier>();
      final options = await notifier.repository.getPurchaseOrderOptions(query: query);
      return options.map((p) => AsyncSelectOption(
        id: p.id.toString(),
        name: '${p.code} - ${p.supplier ?? 'N/A'}',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AsyncSelectOption>> _loadWarehouses(String query) async {
    try {
      final notifier = context.read<ReceptionNotifier>();
      final options = await notifier.repository.getWarehouseOptions(query: query);
      return options.map((w) => AsyncSelectOption(
        id: w.id.toString(),
        name: w.name,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal',
      confirmText: 'Pilih',
      cancelText: 'Batal',
    );
    if (date == null) return;
    setState(() {
      _selectedDate = date;
      _formError = null;
    });
  }

  void _onPurchaseOrderSelected(PurchaseOrderForReception po) {
    setState(() {
      _selectedPurchaseOrder = po;
      // Auto-fill line items from PO details
      _lineItems = po.details.map((d) => _LineItem(
        productId: d.productId,
        productName: d.productName,
        qty: d.remainingQty,
        unitCost: d.unitCost,
      )).toList();
      if (_lineItems.isEmpty) _lineItems.add(_LineItem());
      _formError = null;
    });
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(_LineItem());
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length <= 1) return;
    setState(() {
      _lineItems.removeAt(index);
      _formError = null;
    });
  }

  void _updateLineItem(int index, _LineItem item) {
    setState(() {
      _lineItems[index] = item;
      _formError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      setState(() => _formError = 'Tanggal wajib diisi');
      return;
    }

    if (_selectedPurchaseOrder == null) {
      setState(() => _formError = 'Purchase Order wajib dipilih');
      return;
    }

    if (_lineItems.isEmpty || !_lineItems.every((item) => item.productId != null && item.qty > 0)) {
      setState(() => _formError = 'Minimal harus ada 1 produk dengan quantity');
      return;
    }

    final notifier = context.read<ReceptionNotifier>();

    final productIds = <int>[];
    final qtys = <double>[];
    final unitCosts = <double>[];

    for (final item in _lineItems) {
      if (item.productId != null && item.qty > 0) {
        productIds.add(item.productId!);
        qtys.add(item.qty);
        unitCosts.add(item.unitCost);
      }
    }

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    bool success;
    if (_isEditing) {
      success = await notifier.updateReception(
        id: widget.editId!,
        warehouseId: _selectedWarehouse?.id,
        date: dateStr,
        productIds: productIds,
        qtys: qtys,
        unitCosts: unitCosts,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } else {
      success = await notifier.createReception(
        purchaseOrderId: _selectedPurchaseOrder!.id,
        warehouseId: _selectedWarehouse?.id,
        date: dateStr,
        productIds: productIds,
        qtys: qtys,
        unitCosts: unitCosts,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Penerimaan berhasil diupdate' : 'Penerimaan berhasil dibuat'),
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

  double get _grandTotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.total);
  }

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReceptionNotifier>();
    final isSubmitting = notifier.state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Penerimaan' : 'Buat Penerimaan'),
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

                  // Date field
                  _buildDateField(),
                  SizedBox(height: 16),

                  // Warehouse selector
                  _buildWarehouseField(),
                  SizedBox(height: 24),

                  // Products section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Produk Diterima',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                      FButton(
                        onPress: _addLineItem,
                        variant: FButtonVariant.ghost,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(IconMap.plus, size: 18),
                            SizedBox(width: 4),
                            Text('Tambah'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Line items
                  ...List.generate(_lineItems.length, (index) {
                    return _buildLineItemCard(index);
                  }),

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

                  // Grand total
                  SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
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
                          _formatCurrency(_grandTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Notes field
                  _buildNotesField(),

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
                      _isEditing ? 'Update Penerimaan' : 'Simpan Penerimaan',
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
              final notifier = context.read<ReceptionNotifier>();
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
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        SizedBox(height: 4),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(IconMap.calendarToday, size: 20, color: AppColors.gray400),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate != null ? _formatDate(_selectedDate!) : 'Pilih tanggal',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? AppColors.gray400 : AppColors.slate800,
                      ),
                    ),
                  ),
                  Icon(IconMap.chevronRight, size: 24, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gudang (opsional)',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        SizedBox(height: 4),
        AsyncSelectField(
          label: null,
          placeholder: 'Pilih gudang...',
          loadOptions: _loadWarehouses,
          selectedIds: _selectedWarehouse != null
              ? {_selectedWarehouse!.id.toString()}
              : <String>{},
          onSelectionChanged: (ids) async {
            if (ids.isEmpty) {
              setState(() => _selectedWarehouse = null);
              return;
            }
            try {
              final notifier = context.read<ReceptionNotifier>();
              final options = await notifier.repository.getWarehouseOptions(
                query: ids.first,
              );
              final selected = options.where((w) => w.id.toString() == ids.first).firstOrNull;
              if (selected != null) {
                setState(() => _selectedWarehouse = selected);
              }
            } catch (e) {
              // ignore
            }
          },
          multiSelect: false,
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keterangan (opsional)',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Masukkan keterangan...',
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

  Widget _buildLineItemCard(int index) {
    final item = _lineItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                  ),
                ),
              ),
              const Spacer(),
              if (_lineItems.length > 1)
                IconButton(
                  icon: Icon(IconMap.deleteOutline, color: AppColors.danger),
                  onPressed: () => _removeLineItem(index),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 12),

          // Product display (from PO selection)
          if (item.productName != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatCurrency(item.unitCost),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],

          // Qty field
          _buildQtyField(index, item),
          SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
              Text(
                _formatCurrency(item.total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyField(int index, _LineItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qty Diterima',
          style: TextStyle(fontSize: 11, color: AppColors.gray400),
        ),
        SizedBox(height: 4),
        TextFormField(
          initialValue: item.qty > 0 ? item.qty.toString() : '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (value) {
            final qty = double.tryParse(value) ?? 0;
            _updateLineItem(index, item.copyWith(qty: qty));
          },
        ),
      ],
    );
  }
}

/// Line item model for the form
class _LineItem {
  final int? productId;
  final String? productName;
  final double qty;
  final double unitCost;

  const _LineItem({
    this.productId,
    this.productName,
    this.qty = 0,
    this.unitCost = 0,
  });

  double get total => qty * unitCost;

  _LineItem copyWith({
    int? productId,
    String? productName,
    double? qty,
    double? unitCost,
  }) {
    return _LineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/inputs/async_select_field.dart';
import '../providers/purchase_request_provider.dart';

/// Purchase Request form screen for create/edit
class PurchaseRequestFormScreen extends StatefulWidget {
  final int? editId;

  const PurchaseRequestFormScreen({super.key, this.editId});

  @override
  State<PurchaseRequestFormScreen> createState() => _PurchaseRequestFormScreenState();
}

class _PurchaseRequestFormScreenState extends State<PurchaseRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  List<_LineItem> _lineItems = [_LineItem()];
  String? _formError;
  bool _isInitialized = false;

  bool get _isEditing => widget.editId != null;
  bool get _canSubmit {
    return _selectedDate != null &&
        _notesController.text.trim().isNotEmpty &&
        _lineItems.isNotEmpty &&
        _lineItems.every((item) => item.productId != null && item.qty > 0 && item.total > 0);
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
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    if (_isInitialized) return;
    setState(() {});

    final notifier = context.read<PurchaseRequestNotifier>();
    await notifier.loadDetail(widget.editId!);

    final item = notifier.state.selectedItem;
    if (item != null && mounted) {
      setState(() {
        _selectedDate = DateTime.tryParse(item.date);
        _supplierController.text = item.supplier ?? '';
        _notesController.text = item.notes ?? '';
        _lineItems = item.details.map((d) => _LineItem(
          productId: d.productId,
          productName: d.productName,
          qty: d.qty,
          price: d.qty > 0 ? d.total / d.qty : 0,
        )).toList();
        if (_lineItems.isEmpty) _lineItems.add(_LineItem());
        _isInitialized = true;
      });
    }
  }

  Future<List<AsyncSelectOption>> _loadProducts(String query) async {
    try {
      final notifier = context.read<PurchaseRequestNotifier>();
      final options = await notifier.repository.getProductOptions(query: query);
      return options.map((p) => AsyncSelectOption(id: p.id, name: p.name)).toList();
    } catch (e) {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
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

    if (_lineItems.isEmpty || !_lineItems.every((item) => item.productId != null && item.qty > 0)) {
      setState(() => _formError = 'Minimal harus ada 1 produk dengan quantity');
      return;
    }

    final notifier = context.read<PurchaseRequestNotifier>();

    final details = _lineItems
        .where((item) => item.productId != null)
        .map((item) => {
              'product_id': item.productId,
              'qty': item.qty,
              'total': item.total,
            })
        .toList();

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    bool success;
    if (_isEditing) {
      success = await notifier.updatePurchaseRequest(
        id: widget.editId!,
        date: dateStr,
        supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
        notes: _notesController.text.trim(),
        details: details,
      );
    } else {
      success = await notifier.createPurchaseRequest(
        date: dateStr,
        supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
        notes: _notesController.text.trim(),
        details: details,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Purchase request berhasil diupdate' : 'Purchase request berhasil dibuat'),
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
    final notifier = context.watch<PurchaseRequestNotifier>();
    final isSubmitting = notifier.state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Purchase Request' : 'Buat Purchase Request'),
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
                  // Date field
                  _buildDateField(),
                  const SizedBox(height: 16),

                  // Supplier field
                  _buildSupplierField(),
                  const SizedBox(height: 16),

                  // Notes field
                  _buildNotesField(),
                  const SizedBox(height: 24),

                  // Products section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Produk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addLineItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Line items
                  ...List.generate(_lineItems.length, (index) {
                    return _buildLineItemCard(index);
                  }),

                  if (_formError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
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
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
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

                  const SizedBox(height: 100),
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
                    child: LoadingIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Update Purchase Request' : 'Simpan Purchase Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.slate400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null ? _formatDate(_selectedDate!) : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate == null ? AppColors.slate400 : AppColors.slate800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 24, color: AppColors.slate400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier (opsional)',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _supplierController,
          decoration: InputDecoration(
            hintText: 'Nama supplier',
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
        const Text(
          'Keterangan',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Masukkan keterangan atau alasan purchase request...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Keterangan wajib diisi';
            }
            return null;
          },
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
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () => _removeLineItem(index),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Product dropdown
          _buildProductDropdown(index, item),
          const SizedBox(height: 12),

          // Qty and Price row
          Row(
            children: [
              Expanded(
                child: _buildQtyField(index, item),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceField(index, item),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
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

  Widget _buildProductDropdown(int index, _LineItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produk',
          style: TextStyle(fontSize: 11, color: AppColors.slate400),
        ),
        const SizedBox(height: 4),
        AsyncSelectField(
          label: null,
          placeholder: 'Cari produk...',
          loadOptions: _loadProducts,
          selectedIds: item.productId != null ? {item.productId!} : {},
          onSelectionChanged: (ids) {
            final selectedId = ids.isNotEmpty ? ids.first : null;
            // Find the selected option name
            final options = _lineItems[index].selectedOptions;
            String? selectedName;
            for (final opt in options) {
              if (opt.id == selectedId) {
                selectedName = opt.name;
                break;
              }
            }
            _updateLineItem(index, _LineItem(
              productId: selectedId,
              productName: selectedName,
              qty: item.qty,
              price: item.price,
              selectedOptions: item.selectedOptions,
            ));
          },
          multiSelect: false,
        ),
      ],
    );
  }

  Widget _buildQtyField(int index, _LineItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qty',
          style: TextStyle(fontSize: 11, color: AppColors.slate400),
        ),
        const SizedBox(height: 4),
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

  Widget _buildPriceField(int index, _LineItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harga',
          style: TextStyle(fontSize: 11, color: AppColors.slate400),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: item.price > 0 ? item.price.toStringAsFixed(0) : '',
          keyboardType: TextInputType.number,
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
            final price = double.tryParse(value) ?? 0;
            _updateLineItem(index, item.copyWith(price: price));
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
  final double price;
  final List<AsyncSelectOption> selectedOptions;

  const _LineItem({
    this.productId,
    this.productName,
    this.qty = 0,
    this.price = 0,
    this.selectedOptions = const [],
  });

  double get total => qty * price;

  _LineItem copyWith({
    int? productId,
    String? productName,
    double? qty,
    double? price,
    List<AsyncSelectOption>? selectedOptions,
  }) {
    return _LineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}

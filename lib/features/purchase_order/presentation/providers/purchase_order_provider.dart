import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/purchase_order_repository.dart';
import '../../domain/models/models.dart';

export '../../data/repositories/purchase_order_repository.dart'
    show PurchaseOrderRepository, ProductOption, PurchaseRequestOption;

// ====================
// Repository Factory
// ====================
PurchaseOrderRepository createPurchaseOrderRepository(Dio dio) {
  return PurchaseOrderRepository(PurchaseOrderApi(dio));
}

// ====================
// State
// ====================
class PurchaseOrderState extends ChangeNotifier {
  final List<PurchaseOrder> items;
  final PurchaseOrder? selectedItem;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final String? submitError;
  final bool isDeleting;
  final String? deleteError;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  PurchaseOrderState({
    this.items = const [],
    this.selectedItem,
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.submitError,
    this.isDeleting = false,
    this.deleteError,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
  });

  PurchaseOrderState copyWith({
    List<PurchaseOrder>? items,
    PurchaseOrder? selectedItem,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? isDeleting,
    String? deleteError,
    bool clearDeleteError = false,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    bool clearSelectedItem = false,
  }) {
    return PurchaseOrderState(
      items: items ?? this.items,
      selectedItem: clearSelectedItem ? null : (selectedItem ?? this.selectedItem),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      isDeleting: isDeleting ?? this.isDeleting,
      deleteError: clearDeleteError ? null : (deleteError ?? this.deleteError),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ====================
// Notifier
// ====================
class PurchaseOrderNotifier extends ChangeNotifier {
  final PurchaseOrderRepository repository;

  PurchaseOrderNotifier(this.repository);

  PurchaseOrderState _state = PurchaseOrderState();
  PurchaseOrderState get state => _state;

  String? _searchQuery;
  String? _statusFilter;

  /// Load initial list of purchase orders
  Future<void> loadPurchaseOrders({bool refresh = false}) async {
    if (refresh) {
      _state = _state.copyWith(
        isLoading: true,
        clearError: true,
        currentPage: 1,
        items: [],
      );
    } else if (_state.isLoading) {
      return;
    } else {
      _state = _state.copyWith(isLoading: true, clearError: true);
    }
    notifyListeners();

    try {
      final result = await repository.getPurchaseOrders(
        search: _searchQuery,
        status: _statusFilter,
        page: 1,
      );

      _state = _state.copyWith(
        items: result.items,
        isLoading: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        hasMore: result.hasMore,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat daftar purchase order',
      );
    }
    notifyListeners();
  }

  /// Load more items (pagination)
  Future<void> loadMore() async {
    if (_state.isLoading || !_state.hasMore) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final nextPage = _state.currentPage + 1;
      final result = await repository.getPurchaseOrders(
        search: _searchQuery,
        status: _statusFilter,
        page: nextPage,
      );

      _state = _state.copyWith(
        items: [..._state.items, ...result.items],
        isLoading: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        hasMore: result.hasMore,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat lebih banyak data',
      );
    }
    notifyListeners();
  }

  /// Set search query
  void setSearch(String? query) {
    _searchQuery = query;
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    _statusFilter = status;
  }

  /// Apply filters and reload
  Future<void> applyFilters({String? search, String? status}) async {
    _searchQuery = search;
    _statusFilter = status;
    await loadPurchaseOrders(refresh: true);
  }

  /// Load detail of a purchase order
  Future<void> loadDetail(int id) async {
    _state = _state.copyWith(isLoading: true, clearError: true, clearSelectedItem: true);
    notifyListeners();

    try {
      final detail = await repository.getPurchaseOrderDetail(id);
      _state = _state.copyWith(
        selectedItem: detail,
        isLoading: false,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat detail purchase order',
      );
    }
    notifyListeners();
  }

  /// Create a new purchase order
  Future<bool> createPurchaseOrder({
    required int purchaseRequestId,
    required String date,
    String? supplier,
    String? notes,
    required List<Map<String, dynamic>> details,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.createPurchaseOrder(
        purchaseRequestId: purchaseRequestId,
        date: date,
        supplier: supplier,
        notes: notes,
        details: details,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        selectedItem: result,
      );

      // Reload list to include the new item
      await loadPurchaseOrders(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal membuat purchase order',
      );
      notifyListeners();
      return false;
    }
  }

  /// Update an existing purchase order
  Future<bool> updatePurchaseOrder({
    required int id,
    required int purchaseRequestId,
    required String date,
    String? supplier,
    String? notes,
    required List<Map<String, dynamic>> details,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.updatePurchaseOrder(
        id: id,
        purchaseRequestId: purchaseRequestId,
        date: date,
        supplier: supplier,
        notes: notes,
        details: details,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        selectedItem: result,
      );

      // Reload list to reflect changes
      await loadPurchaseOrders(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal mengupdate purchase order',
      );
      notifyListeners();
      return false;
    }
  }

  /// Submit purchase order for approval
  Future<bool> submitForApproval(int id) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      await repository.submitPurchaseOrder(id);

      // Reload detail to get updated status
      await loadDetail(id);

      _state = _state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal mengajukan purchase order',
      );
      notifyListeners();
      return false;
    }
  }

  /// Delete a purchase order
  Future<bool> deletePurchaseOrder(int id) async {
    _state = _state.copyWith(isDeleting: true, clearDeleteError: true);
    notifyListeners();

    try {
      await repository.deletePurchaseOrder(id);

      // Remove from list
      _state = _state.copyWith(
        isDeleting: false,
        items: _state.items.where((item) => item.id != id).toList(),
        clearSelectedItem: true,
      );
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isDeleting: false, deleteError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isDeleting: false,
        deleteError: 'Gagal menghapus purchase order',
      );
      notifyListeners();
      return false;
    }
  }

  /// Clear selected item
  void clearSelectedItem() {
    _state = _state.copyWith(clearSelectedItem: true);
    notifyListeners();
  }

  /// Clear all errors
  void clearErrors() {
    _state = _state.copyWith(
      clearError: true,
      clearSubmitError: true,
      clearDeleteError: true,
    );
    notifyListeners();
  }
}

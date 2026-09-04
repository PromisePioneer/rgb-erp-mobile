import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/purchase_request_repository.dart';
import '../../domain/models/models.dart';

export '../../data/repositories/purchase_request_repository.dart'
    show PurchaseRequestRepository, ProductOption;

// ====================
// Repository Factory
// ====================
PurchaseRequestRepository createPurchaseRequestRepository(Dio dio) {
  return PurchaseRequestRepository(PurchaseRequestApi(dio));
}

// ====================
// State
// ====================
class PurchaseRequestState extends ChangeNotifier {
  final List<PurchaseRequest> items;
  final PurchaseRequest? selectedItem;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final String? submitError;
  final bool isDeleting;
  final String? deleteError;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  PurchaseRequestState({
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

  PurchaseRequestState copyWith({
    List<PurchaseRequest>? items,
    PurchaseRequest? selectedItem,
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
    return PurchaseRequestState(
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
class PurchaseRequestNotifier extends ChangeNotifier {
  final PurchaseRequestRepository repository;

  PurchaseRequestNotifier(this.repository);

  PurchaseRequestState _state = PurchaseRequestState();
  PurchaseRequestState get state => _state;

  String? _searchQuery;
  String? _statusFilter;

  /// Load initial list of purchase requests
  Future<void> loadPurchaseRequests({bool refresh = false}) async {
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
      final result = await repository.getPurchaseRequests(
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
        error: 'Gagal memuat daftar purchase request',
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
      final result = await repository.getPurchaseRequests(
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
    await loadPurchaseRequests(refresh: true);
  }

  /// Load detail of a purchase request
  Future<void> loadDetail(int id) async {
    _state = _state.copyWith(isLoading: true, clearError: true, clearSelectedItem: true);
    notifyListeners();

    try {
      final detail = await repository.getPurchaseRequestDetail(id);
      _state = _state.copyWith(
        selectedItem: detail,
        isLoading: false,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat detail purchase request',
      );
    }
    notifyListeners();
  }

  /// Create a new purchase request
  Future<bool> createPurchaseRequest({
    required String date,
    String? supplier,
    required String notes,
    required List<Map<String, dynamic>> details,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.createPurchaseRequest(
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
      await loadPurchaseRequests(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal membuat purchase request',
      );
      notifyListeners();
      return false;
    }
  }

  /// Update an existing purchase request
  Future<bool> updatePurchaseRequest({
    required int id,
    required String date,
    String? supplier,
    required String notes,
    required List<Map<String, dynamic>> details,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.updatePurchaseRequest(
        id: id,
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
      await loadPurchaseRequests(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal mengupdate purchase request',
      );
      notifyListeners();
      return false;
    }
  }

  /// Submit purchase request for approval
  Future<bool> submitForApproval(int id) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      await repository.submitPurchaseRequest(id);

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
        submitError: 'Gagal mengajukan purchase request',
      );
      notifyListeners();
      return false;
    }
  }

  /// Delete a purchase request
  Future<bool> deletePurchaseRequest(int id) async {
    _state = _state.copyWith(isDeleting: true, clearDeleteError: true);
    notifyListeners();

    try {
      await repository.deletePurchaseRequest(id);

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
        deleteError: 'Gagal menghapus purchase request',
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

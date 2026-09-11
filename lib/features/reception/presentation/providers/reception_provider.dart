import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/reception_repository.dart';
import '../../domain/models/models.dart';

export '../../data/repositories/reception_repository.dart'
    show ReceptionRepository, PurchaseOrderForReception, WarehouseOption;

// ====================
// Repository Factory
// ====================
ReceptionRepository createReceptionRepository(Dio dio) {
  return ReceptionRepository(ReceptionApi(dio));
}

// ====================
// State
// ====================
class ReceptionState extends ChangeNotifier {
  final List<Reception> items;
  final Reception? selectedItem;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final String? submitError;
  final bool isDeleting;
  final String? deleteError;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  ReceptionState({
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

  ReceptionState copyWith({
    List<Reception>? items,
    Reception? selectedItem,
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
    return ReceptionState(
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
class ReceptionNotifier extends ChangeNotifier {
  final ReceptionRepository repository;

  ReceptionNotifier(this.repository);

  ReceptionState _state = ReceptionState();
  ReceptionState get state => _state;

  String? _searchQuery;
  String? _statusFilter;

  /// Load initial list of receptions
  Future<void> loadReceptions({bool refresh = false}) async {
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
      final result = await repository.getReceptions(
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
        error: 'Gagal memuat daftar reception',
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
      final result = await repository.getReceptions(
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
    await loadReceptions(refresh: true);
  }

  /// Load detail of a reception
  Future<void> loadDetail(int id) async {
    _state = _state.copyWith(isLoading: true, clearError: true, clearSelectedItem: true);
    notifyListeners();

    try {
      final detail = await repository.getReceptionDetail(id);
      _state = _state.copyWith(
        selectedItem: detail,
        isLoading: false,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat detail reception',
      );
    }
    notifyListeners();
  }

  /// Create a new reception
  Future<bool> createReception({
    required int purchaseOrderId,
    int? warehouseId,
    required String date,
    required List<int> productIds,
    required List<double> qtys,
    required List<double> unitCosts,
    String? notes,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.createReception(
        purchaseOrderId: purchaseOrderId,
        warehouseId: warehouseId,
        date: date,
        productIds: productIds,
        qtys: qtys,
        unitCosts: unitCosts,
        notes: notes,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        selectedItem: result,
      );

      // Reload list to include the new item
      await loadReceptions(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal membuat reception',
      );
      notifyListeners();
      return false;
    }
  }

  /// Update an existing reception
  Future<bool> updateReception({
    required int id,
    int? warehouseId,
    required String date,
    required List<int> productIds,
    required List<double> qtys,
    required List<double> unitCosts,
    String? notes,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.updateReception(
        id: id,
        warehouseId: warehouseId,
        date: date,
        productIds: productIds,
        qtys: qtys,
        unitCosts: unitCosts,
        notes: notes,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        selectedItem: result,
      );

      // Reload list to reflect changes
      await loadReceptions(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal mengupdate reception',
      );
      notifyListeners();
      return false;
    }
  }

  /// Submit reception for approval
  Future<bool> submitForApproval(int id) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      await repository.submitReception(id);

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
        submitError: 'Gagal mengajukan reception',
      );
      notifyListeners();
      return false;
    }
  }

  /// Delete a reception
  Future<bool> deleteReception(int id) async {
    _state = _state.copyWith(isDeleting: true, clearDeleteError: true);
    notifyListeners();

    try {
      await repository.deleteReception(id);

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
        deleteError: 'Gagal menghapus reception',
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

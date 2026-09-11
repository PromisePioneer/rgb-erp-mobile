import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/fund_request_repository.dart';
import '../../domain/models/models.dart';

export '../../data/repositories/fund_request_repository.dart'
    show FundRequestRepository, PurchaseOrderOption;

// ====================
// Repository Factory
// ====================
FundRequestRepository createFundRequestRepository(Dio dio) {
  return FundRequestRepository(FundRequestApi(dio));
}

// ====================
// State
// ====================
class FundRequestState extends ChangeNotifier {
  final List<FundRequest> items;
  final FundRequest? selectedItem;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final String? submitError;
  final bool isDeleting;
  final String? deleteError;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  FundRequestState({
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

  FundRequestState copyWith({
    List<FundRequest>? items,
    FundRequest? selectedItem,
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
    return FundRequestState(
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
class FundRequestNotifier extends ChangeNotifier {
  final FundRequestRepository repository;

  FundRequestNotifier(this.repository);

  FundRequestState _state = FundRequestState();
  FundRequestState get state => _state;

  String? _searchQuery;
  String? _statusFilter;

  /// Load initial list of fund requests
  Future<void> loadFundRequests({bool refresh = false}) async {
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
      final result = await repository.getFundRequests(
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
        error: 'Gagal memuat daftar fund request',
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
      final result = await repository.getFundRequests(
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
    await loadFundRequests(refresh: true);
  }

  /// Load detail of a fund request
  Future<void> loadDetail(int id) async {
    _state = _state.copyWith(isLoading: true, clearError: true, clearSelectedItem: true);
    notifyListeners();

    try {
      final detail = await repository.getFundRequestDetail(id);
      _state = _state.copyWith(
        selectedItem: detail,
        isLoading: false,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat detail fund request',
      );
    }
    notifyListeners();
  }

  /// Create a new fund request
  Future<bool> createFundRequest({
    required int poId,
    required double requestedAmount,
    double? taxAmount,
    String? paymentTerm,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? paymentMethod,
    String? notes,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.createFundRequest(
        poId: poId,
        requestedAmount: requestedAmount,
        taxAmount: taxAmount,
        paymentTerm: paymentTerm,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        selectedItem: result,
      );

      // Reload list to include the new item
      await loadFundRequests(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal membuat fund request',
      );
      notifyListeners();
      return false;
    }
  }

  /// Update an existing fund request
  Future<bool> updateFundRequest({
    required int id,
    required double requestedAmount,
    double? taxAmount,
    String? paymentTerm,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? paymentMethod,
    String? notes,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      final result = await repository.updateFundRequest(
        id: id,
        requestedAmount: requestedAmount,
        taxAmount: taxAmount,
        paymentTerm: paymentTerm,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        selectedItem: result,
      );

      // Reload list to reflect changes
      await loadFundRequests(refresh: true);
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal mengupdate fund request',
      );
      notifyListeners();
      return false;
    }
  }

  /// Submit fund request for approval
  Future<bool> submitForApproval(int id) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      await repository.submitFundRequest(id);

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
        submitError: 'Gagal mengajukan fund request',
      );
      notifyListeners();
      return false;
    }
  }

  /// Delete a fund request
  Future<bool> deleteFundRequest(int id) async {
    _state = _state.copyWith(isDeleting: true, clearDeleteError: true);
    notifyListeners();

    try {
      await repository.deleteFundRequest(id);

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
        deleteError: 'Gagal menghapus fund request',
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

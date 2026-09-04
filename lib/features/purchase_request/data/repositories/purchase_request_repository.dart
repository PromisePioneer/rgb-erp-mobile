import '../../../../core/core.dart';
import '../../domain/models/models.dart';
export '../../../../core/di/injection.dart' show PurchaseRequestApi;

/// Represents a product option for dropdown selection
class ProductOption {
  final int id;
  final String name;

  const ProductOption({required this.id, required this.name});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

/// Paginated response wrapper
class PaginatedPurchaseRequests {
  final List<PurchaseRequest> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PaginatedPurchaseRequests({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for Purchase Request operations
class PurchaseRequestRepository {
  final PurchaseRequestApi _api;

  PurchaseRequestRepository(this._api);

  /// Get paginated list of purchase requests
  Future<PaginatedPurchaseRequests> getPurchaseRequests({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _api.getPurchaseRequests(
        search: search,
        status: status,
        page: page,
        perPage: perPage,
      );

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => PurchaseRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      final meta = response['meta'] as Map<String, dynamic>? ?? {};

      return PaginatedPurchaseRequests(
        items: items,
        currentPage: meta['current_page'] as int? ?? 1,
        perPage: meta['per_page'] as int? ?? perPage,
        total: meta['total'] as int? ?? 0,
        lastPage: meta['last_page'] as int? ?? 1,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar purchase request: $e',
        statusCode: 500,
      );
    }
  }

  /// Get purchase request detail by ID
  Future<PurchaseRequest> getPurchaseRequestDetail(int id) async {
    try {
      final response = await _api.getPurchaseRequestDetail(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal memuat detail purchase request',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return PurchaseRequest.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat detail purchase request: $e',
        statusCode: 500,
      );
    }
  }

  /// Create a new purchase request
  Future<PurchaseRequest> createPurchaseRequest({
    required String date,
    String? supplier,
    required String notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _api.createPurchaseRequest(
        date: date,
        supplier: supplier,
        notes: notes,
        details: details,
      );

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal membuat purchase request',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return PurchaseRequest.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal membuat purchase request: $e',
        statusCode: 500,
      );
    }
  }

  /// Update an existing purchase request
  Future<PurchaseRequest> updatePurchaseRequest({
    required int id,
    required String date,
    String? supplier,
    required String notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _api.updatePurchaseRequest(
        id: id,
        date: date,
        supplier: supplier,
        notes: notes,
        details: details,
      );

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengupdate purchase request',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return PurchaseRequest.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengupdate purchase request: $e',
        statusCode: 500,
      );
    }
  }

  /// Delete a purchase request
  Future<void> deletePurchaseRequest(int id) async {
    try {
      final response = await _api.deletePurchaseRequest(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal menghapus purchase request',
          statusCode: 400,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menghapus purchase request: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit purchase request for approval
  Future<Map<String, dynamic>> submitPurchaseRequest(int id) async {
    try {
      final response = await _api.submitPurchaseRequest(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengajukan purchase request',
          statusCode: 400,
        );
      }

      return response['data'] as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengajukan purchase request untuk persetujuan: $e',
        statusCode: 500,
      );
    }
  }

  /// Get product options for dropdown
  Future<List<ProductOption>> getProductOptions({String? query}) async {
    try {
      final response = await _api.getProductOptions(query: query);

      if (response['success'] != true) {
        throw ApiException(
          message: 'Gagal memuat daftar produk',
          statusCode: 400,
        );
      }

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => ProductOption.fromJson(json as Map<String, dynamic>))
          .toList();

      return items;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar produk: $e',
        statusCode: 500,
      );
    }
  }
}

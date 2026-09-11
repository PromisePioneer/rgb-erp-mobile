import '../../../../core/core.dart';
import '../../domain/models/models.dart';
export '../../../../core/di/injection.dart' show PurchaseOrderApi;

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

/// Represents a purchase request option for PO linking
class PurchaseRequestOption {
  final int id;
  final String code;
  final String? supplier;
  final String date;
  final double total;
  final List<PurchaseRequestDetailOption> details;

  const PurchaseRequestOption({
    required this.id,
    required this.code,
    this.supplier,
    required this.date,
    required this.total,
    this.details = const [],
  });

  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory PurchaseRequestOption.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestOption(
      id: json['id'] as int,
      code: json['code'] as String,
      supplier: json['supplier'] as String?,
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => PurchaseRequestDetailOption.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents a detail option from purchase request
class PurchaseRequestDetailOption {
  final int productId;
  final String? productName;
  final double qty;
  final double total;

  const PurchaseRequestDetailOption({
    required this.productId,
    this.productName,
    required this.qty,
    required this.total,
  });

  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory PurchaseRequestDetailOption.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestDetailOption(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      qty: (json['qty'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

/// Paginated response wrapper
class PaginatedPurchaseOrders {
  final List<PurchaseOrder> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PaginatedPurchaseOrders({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for Purchase Order operations
class PurchaseOrderRepository {
  final PurchaseOrderApi _api;

  PurchaseOrderRepository(this._api);

  /// Get paginated list of purchase orders
  Future<PaginatedPurchaseOrders> getPurchaseOrders({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _api.getPurchaseOrders(
        search: search,
        status: status,
        page: page,
        perPage: perPage,
      );

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>))
          .toList();

      final meta = response['meta'] as Map<String, dynamic>? ?? {};

      return PaginatedPurchaseOrders(
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
        message: 'Gagal memuat daftar purchase order: $e',
        statusCode: 500,
      );
    }
  }

  /// Get purchase order detail by ID
  Future<PurchaseOrder> getPurchaseOrderDetail(int id) async {
    try {
      final response = await _api.getPurchaseOrderDetail(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal memuat detail purchase order',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return PurchaseOrder.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat detail purchase order: $e',
        statusCode: 500,
      );
    }
  }

  /// Create a new purchase order
  Future<PurchaseOrder> createPurchaseOrder({
    required int purchaseRequestId,
    required String date,
    String? supplier,
    String? notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _api.createPurchaseOrder(
        purchaseRequestId: purchaseRequestId,
        date: date,
        supplier: supplier,
        notes: notes,
        details: details,
      );

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal membuat purchase order',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return PurchaseOrder.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal membuat purchase order: $e',
        statusCode: 500,
      );
    }
  }

  /// Update an existing purchase order
  Future<PurchaseOrder> updatePurchaseOrder({
    required int id,
    required int purchaseRequestId,
    required String date,
    String? supplier,
    String? notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _api.updatePurchaseOrder(
        id: id,
        purchaseRequestId: purchaseRequestId,
        date: date,
        supplier: supplier,
        notes: notes,
        details: details,
      );

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengupdate purchase order',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return PurchaseOrder.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengupdate purchase order: $e',
        statusCode: 500,
      );
    }
  }

  /// Delete a purchase order
  Future<void> deletePurchaseOrder(int id) async {
    try {
      final response = await _api.deletePurchaseOrder(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal menghapus purchase order',
          statusCode: 400,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menghapus purchase order: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit purchase order for approval
  Future<Map<String, dynamic>> submitPurchaseOrder(int id) async {
    try {
      final response = await _api.submitPurchaseOrder(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengajukan purchase order',
          statusCode: 400,
        );
      }

      return response['data'] as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengajukan purchase order untuk persetujuan: $e',
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

  /// Get purchase request options for dropdown
  Future<List<PurchaseRequestOption>> getPurchaseRequestOptions({String? query}) async {
    try {
      final response = await _api.getPurchaseRequestOptions(query: query);

      if (response['success'] != true) {
        throw ApiException(
          message: 'Gagal memuat daftar purchase request',
          statusCode: 400,
        );
      }

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => PurchaseRequestOption.fromJson(json as Map<String, dynamic>))
          .toList();

      return items;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar purchase request: $e',
        statusCode: 500,
      );
    }
  }
}

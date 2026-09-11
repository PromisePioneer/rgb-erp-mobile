import '../../../../core/core.dart';
import '../../domain/models/models.dart';
export '../../../../core/di/injection.dart' show ReceptionApi;

/// Represents a purchase order option for Reception linking
class PurchaseOrderForReception {
  final int id;
  final String code;
  final String? supplier;
  final String date;
  final double total;
  final Map<int, double> remaining;
  final List<PurchaseOrderDetailOption> details;

  const PurchaseOrderForReception({
    required this.id,
    required this.code,
    this.supplier,
    required this.date,
    required this.total,
    this.remaining = const {},
    this.details = const [],
  });

  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory PurchaseOrderForReception.fromJson(Map<String, dynamic> json) {
    // Parse remaining as Map<String, dynamic> from JSON
    final remainingJson = json['remaining'] as Map<String, dynamic>? ?? {};
    final remaining = <int, double>{};
    remainingJson.forEach((key, value) {
      remaining[int.tryParse(key) ?? 0] = (value as num).toDouble();
    });

    return PurchaseOrderForReception(
      id: json['id'] as int,
      code: json['code'] as String,
      supplier: json['supplier'] as String?,
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      remaining: remaining,
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => PurchaseOrderDetailOption.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents a detail option from purchase order
class PurchaseOrderDetailOption {
  final int productId;
  final String? productName;
  final double orderedQty;
  final double remainingQty;
  final double unitCost;
  final double total;

  const PurchaseOrderDetailOption({
    required this.productId,
    this.productName,
    required this.orderedQty,
    required this.remainingQty,
    required this.unitCost,
    required this.total,
  });

  String get formattedUnitCost {
    return 'Rp ${unitCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory PurchaseOrderDetailOption.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetailOption(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      orderedQty: (json['ordered_qty'] as num).toDouble(),
      remainingQty: (json['remaining_qty'] as num).toDouble(),
      unitCost: (json['unit_cost'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

/// Represents a warehouse option
class WarehouseOption {
  final int id;
  final String name;

  const WarehouseOption({required this.id, required this.name});

  factory WarehouseOption.fromJson(Map<String, dynamic> json) {
    return WarehouseOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

/// Paginated response wrapper
class PaginatedReceptions {
  final List<Reception> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PaginatedReceptions({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for Reception operations
class ReceptionRepository {
  final ReceptionApi _api;

  ReceptionRepository(this._api);

  /// Get paginated list of receptions
  Future<PaginatedReceptions> getReceptions({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _api.getReceptions(
        search: search,
        status: status,
        page: page,
        perPage: perPage,
      );

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => Reception.fromJson(json as Map<String, dynamic>))
          .toList();

      final meta = response['meta'] as Map<String, dynamic>? ?? {};

      return PaginatedReceptions(
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
        message: 'Gagal memuat daftar reception: $e',
        statusCode: 500,
      );
    }
  }

  /// Get reception detail by ID
  Future<Reception> getReceptionDetail(int id) async {
    try {
      final response = await _api.getReceptionDetail(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal memuat detail reception',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return Reception.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat detail reception: $e',
        statusCode: 500,
      );
    }
  }

  /// Create a new reception
  Future<Reception> createReception({
    required int purchaseOrderId,
    int? warehouseId,
    required String date,
    required List<int> productIds,
    required List<double> qtys,
    required List<double> unitCosts,
    String? notes,
  }) async {
    try {
      final response = await _api.createReception(
        purchaseOrderId: purchaseOrderId,
        warehouseId: warehouseId,
        date: date,
        productIds: productIds,
        qtys: qtys,
        unitCosts: unitCosts,
        notes: notes,
      );

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal membuat reception',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return Reception.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal membuat reception: $e',
        statusCode: 500,
      );
    }
  }

  /// Update an existing reception
  Future<Reception> updateReception({
    required int id,
    int? warehouseId,
    required String date,
    required List<int> productIds,
    required List<double> qtys,
    required List<double> unitCosts,
    String? notes,
  }) async {
    try {
      final response = await _api.updateReception(
        id: id,
        warehouseId: warehouseId,
        date: date,
        productIds: productIds,
        qtys: qtys,
        unitCosts: unitCosts,
        notes: notes,
      );

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengupdate reception',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return Reception.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengupdate reception: $e',
        statusCode: 500,
      );
    }
  }

  /// Delete a reception
  Future<void> deleteReception(int id) async {
    try {
      final response = await _api.deleteReception(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal menghapus reception',
          statusCode: 400,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menghapus reception: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit reception for approval
  Future<Map<String, dynamic>> submitReception(int id) async {
    try {
      final response = await _api.submitReception(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengajukan reception',
          statusCode: 400,
        );
      }

      return response['data'] as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengajukan reception untuk persetujuan: $e',
        statusCode: 500,
      );
    }
  }

  /// Get purchase order options for dropdown
  Future<List<PurchaseOrderForReception>> getPurchaseOrderOptions({String? query}) async {
    try {
      final response = await _api.getPurchaseOrderOptions(query: query);

      if (response['success'] != true) {
        throw ApiException(
          message: 'Gagal memuat daftar purchase order',
          statusCode: 400,
        );
      }

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => PurchaseOrderForReception.fromJson(json as Map<String, dynamic>))
          .toList();

      return items;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar purchase order: $e',
        statusCode: 500,
      );
    }
  }

  /// Get warehouse options for dropdown
  Future<List<WarehouseOption>> getWarehouseOptions({String? query}) async {
    try {
      final response = await _api.getWarehouseOptions(query: query);

      if (response['success'] != true) {
        throw ApiException(
          message: 'Gagal memuat daftar warehouse',
          statusCode: 400,
        );
      }

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => WarehouseOption.fromJson(json as Map<String, dynamic>))
          .toList();

      return items;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar warehouse: $e',
        statusCode: 500,
      );
    }
  }
}

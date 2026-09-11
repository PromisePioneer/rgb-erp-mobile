import '../../../../core/core.dart';
import '../../domain/models/models.dart';
export '../../../../core/di/injection.dart' show FundRequestApi;

/// Represents a purchase order option for Fund Request linking
class PurchaseOrderOption {
  final int id;
  final String code;
  final String? supplier;
  final String date;
  final double total;
  final double remainingAmount;

  const PurchaseOrderOption({
    required this.id,
    required this.code,
    this.supplier,
    required this.date,
    required this.total,
    required this.remainingAmount,
  });

  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String get formattedRemaining {
    return 'Rp ${remainingAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory PurchaseOrderOption.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderOption(
      id: json['id'] as int,
      code: json['code'] as String,
      supplier: json['supplier'] as String?,
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Paginated response wrapper
class PaginatedFundRequests {
  final List<FundRequest> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PaginatedFundRequests({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for Fund Request operations
class FundRequestRepository {
  final FundRequestApi _api;

  FundRequestRepository(this._api);

  /// Get paginated list of fund requests
  Future<PaginatedFundRequests> getFundRequests({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _api.getFundRequests(
        search: search,
        status: status,
        page: page,
        perPage: perPage,
      );

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => FundRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      final meta = response['meta'] as Map<String, dynamic>? ?? {};

      return PaginatedFundRequests(
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
        message: 'Gagal memuat daftar fund request: $e',
        statusCode: 500,
      );
    }
  }

  /// Get fund request detail by ID
  Future<FundRequest> getFundRequestDetail(int id) async {
    try {
      final response = await _api.getFundRequestDetail(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal memuat detail fund request',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return FundRequest.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat detail fund request: $e',
        statusCode: 500,
      );
    }
  }

  /// Create a new fund request
  Future<FundRequest> createFundRequest({
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
    try {
      final response = await _api.createFundRequest(
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

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal membuat fund request',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return FundRequest.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal membuat fund request: $e',
        statusCode: 500,
      );
    }
  }

  /// Update an existing fund request
  Future<FundRequest> updateFundRequest({
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
    try {
      final response = await _api.updateFundRequest(
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

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengupdate fund request',
          statusCode: 400,
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      return FundRequest.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengupdate fund request: $e',
        statusCode: 500,
      );
    }
  }

  /// Delete a fund request
  Future<void> deleteFundRequest(int id) async {
    try {
      final response = await _api.deleteFundRequest(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal menghapus fund request',
          statusCode: 400,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menghapus fund request: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit fund request for approval
  Future<Map<String, dynamic>> submitFundRequest(int id) async {
    try {
      final response = await _api.submitFundRequest(id);

      if (response['success'] != true) {
        throw ApiException(
          message: response['message'] as String? ?? 'Gagal mengajukan fund request',
          statusCode: 400,
        );
      }

      return response['data'] as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengajukan fund request untuk persetujuan: $e',
        statusCode: 500,
      );
    }
  }

  /// Get purchase order options for dropdown
  Future<List<PurchaseOrderOption>> getPurchaseOrderOptions({String? query}) async {
    try {
      final response = await _api.getPurchaseOrderOptions(query: query);

      if (response['success'] != true) {
        throw ApiException(
          message: 'Gagal memuat daftar purchase order',
          statusCode: 400,
        );
      }

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((json) => PurchaseOrderOption.fromJson(json as Map<String, dynamic>))
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
}

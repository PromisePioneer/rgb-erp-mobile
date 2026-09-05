import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/approval.dart';

class ApprovalApi {
  final Dio _dio;

  ApprovalApi(this._dio);

  Future<Map<String, dynamic>> getApprovals({int page = 1, int perPage = 50}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.approvals,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getApprovalDetail(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.approval(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> actApproval(int id, String decision, {String? note}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.approvalAct(id),
        data: {
          'decision': decision,
          if (note != null) 'note': note,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApprovalRepository {
  final ApprovalApi _api;

  ApprovalRepository(this._api);

  Future<List<Approval>> getApprovals({int page = 1, int perPage = 50}) async {
    try {
      final response = await _api.getApprovals(page: page, perPage: perPage);
      if (response['success'] != true) {
        throw ApiException(message: response['message'] ?? 'Gagal memuat approval', statusCode: 400);
      }
      final data = (response['data'] as List<dynamic>?) ?? [];
      return data.map((json) => Approval.fromJson(json as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat approval: $e', statusCode: 500);
    }
  }

  Future<Approval> getApprovalDetail(int id) async {
    try {
      final response = await _api.getApprovalDetail(id);
      if (response['success'] != true) {
        throw ApiException(message: response['message'] ?? 'Gagal memuat detail approval', statusCode: 400);
      }
      return Approval.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat detail approval: $e', statusCode: 500);
    }
  }

  Future<void> actApproval(int id, String decision, {String? note}) async {
    try {
      final response = await _api.actApproval(id, decision, note: note);
      if (response['success'] != true) {
        throw ApiException(message: response['message'] ?? 'Gagal memproses approval', statusCode: 400);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memproses approval: $e', statusCode: 500);
    }
  }
}

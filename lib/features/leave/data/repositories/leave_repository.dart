import '../../../../core/core.dart';
import '../../domain/models/leave_request_item.dart';

// Re-export LeaveApi from injection for convenience
export '../../../../core/di/injection.dart' show LeaveApi;

/// Repository for leave data operations
class LeaveRepository {
  final LeaveApi _api;

  LeaveRepository(this._api);

  /// Get all leave requests
  Future<List<LeaveRequestItem>> getLeaves() async {
    try {
      final response = await _api.getLeaves();
      final leaves = response['leaves'] as List<dynamic>? ?? [];
      return leaves
          .map((json) => LeaveRequestItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar cuti: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit a new leave request
  Future<void> submitLeave({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final start = startDate.toIso8601String().split('T').first;
      final end = endDate.toIso8601String().split('T').first;
      await _api.submitLeave(
        type: type,
        startDate: start,
        endDate: end,
        reason: reason,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengajukan cuti: $e',
        statusCode: 500,
      );
    }
  }
}

import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/shift_response.dart';

/// Factory function to create ShiftResponseRepository
ShiftResponseRepository createShiftResponseRepository(Dio dio) {
  return ShiftResponseRepository(dio);
}

/// Repository for shift response operations
class ShiftResponseRepository {
  final Dio _dio;

  ShiftResponseRepository(this._dio);

  /// Get pending shift responses for the current user
  Future<PendingShiftResponseList> getPendingResponses() async {
    try {
      final response = await _dio.get(ApiEndpoints.shiftPendingResponses);
      return PendingShiftResponseList.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Respond to a shift (accept or reject)
  Future<ShiftRespondResponse> respond({
    required String scheduleId,
    required String action,
    String? reason,
  }) async {
    try {
      final endpoint = ApiEndpoints.shiftRespond.replaceAll('{id}', scheduleId);
      final response = await _dio.post(
        endpoint,
        data: {
          'action': action,
          'reason': ?reason,
        },
      );
      return ShiftRespondResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Accept a shift
  Future<ShiftRespondResponse> acceptShift(String scheduleId) async {
    return respond(scheduleId: scheduleId, action: 'accept');
  }

  /// Reject a shift
  Future<ShiftRespondResponse> rejectShift(String scheduleId, {String? reason}) async {
    return respond(scheduleId: scheduleId, action: 'reject', reason: reason);
  }
}

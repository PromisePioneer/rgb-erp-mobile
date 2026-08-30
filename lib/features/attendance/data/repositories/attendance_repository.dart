import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// Repository for attendance operations
class AttendanceRepository {
  final AttendanceApi _api;

  AttendanceRepository({required AttendanceApi api}) : _api = api;

  /// Get today's attendance data (records, next action, location, shift)
  Future<AttendanceData> getTodayAttendance() async {
    try {
      print('REPO: Calling GET /attendance/today');
      final response = await _api.getTodayAttendance();
      print('REPO: Response received: $response');
      return AttendanceData.fromJson(response);
    } on DioException catch (e) {
      print('REPO: DioException - ${e.message}, type: ${e.type}');
      throw ApiException.fromDioException(e);
    }
  }

  /// Record attendance (check-in or check-out)
  Future<AttendanceRecord> recordAttendance({
    required AttendanceType type,
    required String photoBase64,
    required String capturedAt,
    double? lat,
    double? lng,
    String? notes,
    bool? livenessPassed,
    double? faceMatchScore,
    double? freqRatio,
    double? textureScore,
    String? earlyLeaveNotes,
  }) async {
    print('ATT_REPO: Recording attendance - type: ${type.value}');
    print('ATT_REPO: Photo size: ${photoBase64.length} chars (base64)');
    print('ATT_REPO: Location: lat=$lat, lng=$lng');
    print('ATT_REPO: capturedAt: $capturedAt');
    try {
      final response = await _api.recordAttendance(
        type: type.value,
        photo: photoBase64,
        lat: lat,
        lng: lng,
        notes: notes,
        livenessPassed: livenessPassed,
        faceMatchScore: faceMatchScore,
        freqRatio: freqRatio,
        textureScore: textureScore,
        earlyLeaveNotes: earlyLeaveNotes,
        capturedAt: capturedAt,
      );
      print('ATT_REPO: Response: $response');

      final attendance = response['attendance'] as Map<String, dynamic>?;
      if (attendance != null) {
        return AttendanceRecord.fromJson(attendance);
      }

      throw ApiException(message: 'Invalid attendance response');
    } on DioException catch (e) {
      print('ATT_REPO: DioException: ${e.message}, status: ${e.response?.statusCode}');
      throw ApiException.fromDioException(e);
    } catch (e) {
      print('ATT_REPO: Error: $e');
      rethrow;
    }
  }

  /// Face verify for attendance
  Future<FaceVerifyResult> faceVerify({
    required String photoBase64,
    required String capturedAt,
    double? lat,
    double? lng,
    String? type,
    String? notes,
  }) async {
    print('ATT_REPO: Face verify starting...');
    print('ATT_REPO: Photo size: ${photoBase64.length} chars (base64)');
    try {
      final response = await _api.faceVerify(
        photo: photoBase64,
        capturedAt: capturedAt,
        lat: lat,
        lng: lng,
        type: type,
        notes: notes,
      );
      print('ATT_REPO: Face verify response: $response');
      return FaceVerifyResult.fromJson(response);
    } on DioException catch (e) {
      print('ATT_REPO: Face verify DioException: ${e.message}');
      throw ApiException.fromDioException(e);
    }
  }

  /// Check attendance job status (for polling)
  Future<AttendanceJobStatusResult> checkJobStatus(String jobUuid) async {
    print('POLL_API: Calling GET /attendance/status/$jobUuid');
    try {
      final response = await _api.getAttendanceStatus(jobUuid);
      print('POLL_API: Raw response: $response');
      return AttendanceJobStatusResult.fromJson(response);
    } on DioException catch (e) {
      print('POLL_API: DioException - ${e.message}, type: ${e.type}, statusCode: ${e.response?.statusCode}');
      print('POLL_API: Response data: ${e.response?.data}');
      throw ApiException.fromDioException(e);
    }
  }

  /// Poll job status until completed or failed
  Future<AttendanceJobStatusResult> pollJobStatus(
    String jobUuid, {
    int maxAttempts = 60,  // 60 attempts = 60-120 seconds with exponential backoff
    Duration initialInterval = const Duration(seconds: 2),
    Duration maxInterval = const Duration(seconds: 5),
  }) async {
    print('POLL: Starting poll for job $jobUuid (max $maxAttempts attempts)');
    Duration currentInterval = initialInterval;

    for (int i = 0; i < maxAttempts; i++) {
      print('POLL: Attempt ${i + 1}/$maxAttempts (interval: ${currentInterval.inSeconds}s)');
      try {
        final status = await checkJobStatus(jobUuid);
        print('POLL: Status response - status: ${status.status}, message: ${status.message}, isCompleted: ${status.isCompleted}, isFailed: ${status.isFailed}');

        if (status.isCompleted || status.isFailed) {
          print('POLL: Job finished with status: ${status.status}');
          return status;
        }

        // Show progress to user (update every 5 attempts)
        if (i > 0 && i % 5 == 0) {
          print('POLL: Still processing... (${i * currentInterval.inSeconds}s elapsed)');
        }
      } catch (e, stackTrace) {
        print('POLL: Error on attempt ${i + 1}: $e');
        print('POLL: Stack trace: $stackTrace');
        // Continue polling on error, don't fail immediately
      }

      if (i < maxAttempts - 1) {
        await Future.delayed(currentInterval);
        // Exponential backoff: increase interval but cap at maxInterval
        currentInterval = Duration(
          seconds: (currentInterval.inSeconds * 1.5).clamp(
            initialInterval.inSeconds,
            maxInterval.inSeconds,
          ).toInt(),
        );
      }
    }

    // Timeout - return as failed
    print('POLL: Timeout after $maxAttempts attempts');
    return AttendanceJobStatusResult(
      status: AttendanceJobStatus.failed,
      message: 'Verifikasi wajah timeout, silakan coba lagi',
    );
  }
}

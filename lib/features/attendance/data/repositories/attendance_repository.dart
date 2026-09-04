import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// Repository for attendance operations
class AttendanceRepository {
  final AttendanceApi _api;

  AttendanceRepository({required this._api});

  /// Get today's attendance data (records, next action, location, shift)
  Future<AttendanceData> getTodayAttendance() async {
    try {
      
      final response = await _api.getTodayAttendance();
      
      return AttendanceData.fromJson(response);
    } on DioException catch (e) {
      
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
      

      final attendance = response['attendance'] as Map<String, dynamic>?;
      if (attendance != null) {
        return AttendanceRecord.fromJson(attendance);
      }

      throw ApiException(message: 'Invalid attendance response');
    } on DioException catch (e) {
      
      throw ApiException.fromDioException(e);
    } catch (e) {
      
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
    
    
    try {
      final response = await _api.faceVerify(
        photo: photoBase64,
        capturedAt: capturedAt,
        lat: lat,
        lng: lng,
        type: type,
        notes: notes,
      );
      
      return FaceVerifyResult.fromJson(response);
    } on DioException catch (e) {
      
      throw ApiException.fromDioException(e);
    }
  }

  /// Check attendance job status (for polling)
  Future<AttendanceJobStatusResult> checkJobStatus(String jobUuid) async {
    
    try {
      final response = await _api.getAttendanceStatus(jobUuid);
      
      return AttendanceJobStatusResult.fromJson(response);
    } on DioException catch (e) {
      
      
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
    
    Duration currentInterval = initialInterval;

    for (int i = 0; i < maxAttempts; i++) {
      
      try {
        final status = await checkJobStatus(jobUuid);
        

        if (status.isCompleted || status.isFailed) {
          
          return status;
        }

        // Show progress to user (update every 5 attempts)
        if (i > 0 && i % 5 == 0) {
          
        }
      } catch (e) {
        
        
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
    
    return AttendanceJobStatusResult(
      status: AttendanceJobStatus.failed,
      message: 'Verifikasi wajah timeout, silakan coba lagi',
    );
  }
}

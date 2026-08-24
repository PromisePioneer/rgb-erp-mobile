import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';

// ====================
// API Classes
// ====================

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Map<String, dynamic>> login({
    required String code,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'code': code,
          'password': password,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _dio.post(
        ApiEndpoints.logout,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.data;
    } catch (_) {
      return {};
    }
  }

  /// Biometric login - verify device biometric and get new token
  /// Uses stored credentials after device biometric verification passed
  Future<Map<String, dynamic>> biometricLogin({
    required String code,
    String? biometricToken,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.biometricLogin,
        data: {
          'code': code,
          if (biometricToken != null) 'biometric_token': biometricToken,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    final response = await _dio.get(ApiEndpoints.user);
    return response.data;
  }

  Future<void> storeFcmToken(String fcmToken) async {
    await _dio.post(
      ApiEndpoints.fcmToken,
      data: {'fcm_token': fcmToken},
    );
  }

  Future<void> deleteFcmToken(String fcmToken) async {
    await _dio.delete(
      ApiEndpoints.fcmToken,
      data: {'fcm_token': fcmToken},
    );
  }

  /// POST /change-password - Change password for authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class AttendanceApi {
  final Dio _dio;

  AttendanceApi(this._dio);

  /// GET /attendance/today - Get today's attendance data
  Future<Map<String, dynamic>> getTodayAttendance() async {
    print('API: GET ${ApiEndpoints.attendanceToday}');
    final response = await _dio.get(ApiEndpoints.attendanceToday);
    print('API: Response status: ${response.statusCode}');
    print('API: Response data: ${response.data}');
    return response.data as Map<String, dynamic>;
  }

  /// GET /attendance/today-status - Get today's attendance status
  Future<Map<String, dynamic>> getTodayStatus() async {
    final response = await _dio.get(ApiEndpoints.attendanceTodayStatus);
    return response.data as Map<String, dynamic>;
  }

  /// POST /attendance - Record attendance (check-in/check-out)
  /// Body: {type, photo(base64), lat, lng, notes, liveness_passed, face_match_score, early_leave_notes, captured_at, ...}
  Future<Map<String, dynamic>> recordAttendance({
    required String type,
    required String photo,
    double? lat,
    double? lng,
    String? notes,
    bool? livenessPassed,
    double? faceMatchScore,
    double? freqRatio,
    double? textureScore,
    String? earlyLeaveNotes,
    String? capturedAt,
  }) async {
    print('ATT_API: Recording attendance - type: $type');
    print('ATT_API: Photo length: ${photo.length} chars');
    try {
      final response = await _dio.post(
        ApiEndpoints.attendance,
        data: {
          'type': type,
          'photo': photo,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (notes != null) 'notes': notes,
          if (livenessPassed != null) 'liveness_passed': livenessPassed,
          if (faceMatchScore != null) 'face_match_score': faceMatchScore,
          if (freqRatio != null) 'freq_ratio': freqRatio,
          if (textureScore != null) 'texture_score': textureScore,
          if (earlyLeaveNotes != null) 'early_leave_notes': earlyLeaveNotes,
          if (capturedAt != null) 'captured_at': capturedAt,
        },
      );
      print('ATT_API: Record attendance response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ATT_API: Record attendance error: ${e.message}, status: ${e.response?.statusCode}');
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /attendance/face-verify - Face verify for attendance
  /// Body: {photo(base64), captured_at, lat, lng, type, notes}
  /// Returns: {success, match, score, job_id, status, message}
  Future<Map<String, dynamic>> faceVerify({
    required String photo,
    required String capturedAt,
    double? lat,
    double? lng,
    String? type,
    String? notes,
    String? idempotencyKey,
  }) async {
    print('ATT_API: Face verify - photo length: ${photo.length} chars');
    print('ATT_API: captured_at: $capturedAt');
    try {
      final response = await _dio.post(
        ApiEndpoints.attendanceFaceVerify,
        data: {
          'photo': photo,
          'captured_at': capturedAt,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (type != null) 'type': type,
          if (notes != null) 'notes': notes,
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        },
      );
      print('ATT_API: Face verify response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ATT_API: Face verify error: ${e.message}');
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /attendance/status/{jobUuid} - Check attendance job status
  Future<Map<String, dynamic>> getAttendanceStatus(String jobUuid) async {
    final response = await _dio.get(ApiEndpoints.attendanceStatus(jobUuid));
    return response.data as Map<String, dynamic>;
  }
}

class FaceApi {
  final Dio _dio;

  FaceApi(this._dio);

  /// GET /face-enrollment/status - Get face enrollment status
  Future<Map<String, dynamic>> getEnrollmentStatus() async {
    final response = await _dio.get(ApiEndpoints.faceEnrollmentStatus);
    return response.data as Map<String, dynamic>;
  }

  /// POST /face-enrollment - Enroll face (multipart upload)
  /// Body: photos[] (1-4 files)
  Future<Map<String, dynamic>> enrollFace(List<String> photoPaths) async {
    print('FACE_API: Starting enrollFace with ${photoPaths.length} files');
    try {
      final formData = FormData();
      for (int i = 0; i < photoPaths.length; i++) {
        final path = photoPaths[i];
        print('FACE_API: Adding file $i: $path');
        formData.files.add(MapEntry(
          'photos[]',
          await MultipartFile.fromFile(path, filename: 'face_$i.jpg'),
        ));
      }

      print('FACE_API: Sending request to ${ApiEndpoints.faceEnrollment}');
      final response = await _dio.post(
        ApiEndpoints.faceEnrollment,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      print('FACE_API: Response status: ${response.statusCode}');
      print('FACE_API: Response data: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('FACE_API: DioException: ${e.message}, type: ${e.type}');
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /face-enrollment - Get face enrollment detail with photos
  Future<Map<String, dynamic>> getEnrollmentDetail() async {
    final response = await _dio.get(ApiEndpoints.faceEnrollment);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /face-enrollment - Delete face enrollment
  Future<Map<String, dynamic>> deleteEnrollment() async {
    final response = await _dio.delete(ApiEndpoints.faceEnrollment);
    return response.data as Map<String, dynamic>;
  }

  /// POST /face-enrollment/validate - Validate face photo
  Future<Map<String, dynamic>> validatePhoto(String photoPath) async {
    try {
      final formData = FormData();
      formData.files.add(MapEntry(
        'photo',
        await MultipartFile.fromFile(photoPath),
      ));

      final response = await _dio.post(
        ApiEndpoints.faceValidate,
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /liveness - Check liveness (base64 image)
  Future<Map<String, dynamic>> checkLiveness(String base64Image) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.liveness,
        data: {'image': base64Image},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class DashboardApi {
  final Dio _dio;

  DashboardApi(this._dio);

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get(ApiEndpoints.dashboard);
    return response.data;
  }

  Future<List<dynamic>> getAnnouncements() async {
    final response = await _dio.get(ApiEndpoints.announcements);
    return response.data;
  }

  Future<List<dynamic>> getTeamMembers() async {
    final response = await _dio.get(ApiEndpoints.teamMembers);
    return response.data;
  }
}

class PatrolApi {
  final Dio _dio;

  PatrolApi(this._dio);

  /// POST /patrol/scan - Scan a checkpoint QR code
  Future<Map<String, dynamic>> scan({
    required String qrCode,
    required double latitude,
    required double longitude,
    String? deviceId,
    bool? isMockLocation,
    String? scannedAtLocal,
    String? otpCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.patrolScan,
        data: {
          'qr_code': qrCode,
          'latitude': latitude,
          'longitude': longitude,
          if (deviceId != null) 'device_id': deviceId,
          if (isMockLocation != null) 'is_mock_location': isMockLocation,
          if (scannedAtLocal != null) 'scanned_at_local': scannedAtLocal,
          if (otpCode != null) 'otp_code': otpCode,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /patrol/today-status - Get today's patrol status
  Future<Map<String, dynamic>> getTodayStatus() async {
    try {
      final response = await _dio.get(ApiEndpoints.patrolTodayStatus);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class PanicApi {
  final Dio _dio;

  PanicApi(this._dio);

  Future<Map<String, dynamic>> sendPanicAlert({
    required String type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.panicAlert,
      data: {
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPanicStatus() async {
    final response = await _dio.get(ApiEndpoints.panicAlertStatus);
    return response.data;
  }
}

class NotificationApi {
  final Dio _dio;

  NotificationApi(this._dio);

  /// POST /device-tokens - Register or update device FCM token
  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deviceTokens,
        data: {
          'fcm_token': token,
          'platform': platform,
          'device_id': deviceId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /device-tokens - Unregister device token
  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _dio.delete(
        ApiEndpoints.deviceTokens,
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ScheduleApi {
  final Dio _dio;

  ScheduleApi(this._dio);

  /// GET /schedule - Get all schedules
  Future<Map<String, dynamic>> getSchedules() async {
    try {
      final response = await _dio.get(ApiEndpoints.schedule);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class PayrollApi {
  final Dio _dio;

  PayrollApi(this._dio);

  /// GET /payroll - Get all payslips
  Future<Map<String, dynamic>> getPayslips() async {
    try {
      final response = await _dio.get(ApiEndpoints.payroll);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class LeaveApi {
  final Dio _dio;

  LeaveApi(this._dio);

  /// GET /leave - Get all leave requests
  Future<Map<String, dynamic>> getLeaves() async {
    try {
      final response = await _dio.get(ApiEndpoints.leave);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /leave - Submit a new leave request
  Future<Map<String, dynamic>> submitLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.leave,
        data: {
          'type': type,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ViolationReportApi {
  final Dio _dio;

  ViolationReportApi(this._dio);

  /// GET /patrol-violation/projects - Get projects for violation report
  Future<Map<String, dynamic>> getProjects() async {
    try {
      final response = await _dio.get(ApiEndpoints.violationReportProjects);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /patrol-violation/employees - Get employees by project
  Future<Map<String, dynamic>> getEmployeesByProject(int projectId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.violationReportEmployees,
        queryParameters: {'project_id': projectId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /patrol-violation - Submit violation report (multipart)
  Future<Map<String, dynamic>> submitViolation({
    required int projectId,
    required int employeeId,
    required int violationTypeId,
    required String capturedAt,
    required double latitude,
    required double longitude,
    String? notes,
    String? action,
    List<String>? photoPaths,
  }) async {
    try {
      final formData = FormData();

      formData.fields.add(MapEntry('projects_id', projectId.toString()));
      formData.fields.add(MapEntry('employee_id', employeeId.toString()));
      formData.fields.add(MapEntry('violation_type_id', violationTypeId.toString()));
      formData.fields.add(MapEntry('captured_at', capturedAt));
      formData.fields.add(MapEntry('latitude', latitude.toString()));
      formData.fields.add(MapEntry('longitude', longitude.toString()));

      if (notes != null && notes.isNotEmpty) {
        formData.fields.add(MapEntry('notes', notes));
      }

      if (action != null && action.isNotEmpty) {
        formData.fields.add(MapEntry('action', action));
      }

      if (photoPaths != null && photoPaths.isNotEmpty) {
        for (int i = 0; i < photoPaths.length; i++) {
          final file = File(photoPaths[i]);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final base64 = base64Encode(bytes);
            formData.fields.add(MapEntry(
              'photos[$i]',
              base64,
            ));
          }
        }
      }

      final response = await _dio.post(
        ApiEndpoints.violationReportSubmit,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /violation-types - Get hierarchical violation types
  Future<Map<String, dynamic>> getViolationTypes() async {
    try {
      final response = await _dio.get(ApiEndpoints.violationTypes);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /patrol-violation/history - Get logged in user's violation reports
  Future<Map<String, dynamic>> getUserViolations() async {
    try {
      final response = await _dio.get(ApiEndpoints.violationReportHistory);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ReportApi {
  final Dio _dio;

  ReportApi(this._dio);

  /// GET /report - Get current user's field reports
  Future<Map<String, dynamic>> getReports() async {
    try {
      final response = await _dio.get(ApiEndpoints.reports);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /report/by-area - Get reports grouped by area
  Future<Map<String, dynamic>> getReportsByArea() async {
    try {
      final response = await _dio.get(ApiEndpoints.reportByArea);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /report - Submit a field report
  Future<Map<String, dynamic>> submitReport({
    required String description,
    required double latitude,
    required double longitude,
    String? location,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.reports,
        data: {
          'note': description,
          'lat': latitude,
          'lng': longitude,
          if (location != null) 'location': location,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

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
    print('ATT_API: Calling GET /attendance/status/$jobUuid');
    try {
      final response = await _dio.get(ApiEndpoints.attendanceStatus(jobUuid));
      print('ATT_API: Status response - statusCode: ${response.statusCode}, data: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ATT_API: DioException - message: ${e.message}, type: ${e.type}');
      print('ATT_API: Response statusCode: ${e.response?.statusCode}');
      print('ATT_API: Response data: ${e.response?.data}');
      throw e;
    }
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
    print('PANIC_API: POST ${ApiEndpoints.panicAlert} - type=$type, lat=$latitude, lng=$longitude');
    final response = await _dio.post(
      ApiEndpoints.panicAlert,
      data: {
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
      },
    );
    print('PANIC_API: Response - ${response.data}');
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

  /// GET /patrol-violation/projects - Get areas for violation report
  Future<Map<String, dynamic>> getAreas() async {
    try {
      final response = await _dio.get(ApiEndpoints.violationReportProjects);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /patrol-violation/employees - Get employees by area
  Future<Map<String, dynamic>> getEmployeesByArea(int areaId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.violationReportEmployees,
        queryParameters: {'area_id': areaId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /patrol-violation - Submit violation report (multipart)
  Future<Map<String, dynamic>> submitViolation({
    required int areaId,
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

      formData.fields.add(MapEntry('area_id', areaId.toString()));
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

class BackupOfferApi {
  final Dio _dio;

  BackupOfferApi(this._dio);

  /// GET /backup-offers - Get pending backup offers
  Future<Map<String, dynamic>> getPendingOffers() async {
    try {
      final response = await _dio.get(ApiEndpoints.backupOffers);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /backup-offers/{id}/accept - Accept backup offer
  Future<Map<String, dynamic>> acceptOffer(String offerId) async {
    try {
      final response = await _dio.post(ApiEndpoints.backupOfferAccept(offerId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /backup-offers/{id}/reject - Reject backup offer
  Future<Map<String, dynamic>> rejectOffer(String offerId, {String? reason}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.backupOfferReject(offerId),
        data: reason != null ? {'reason': reason} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

}

class ShiftResponseApi {
  final Dio _dio;

  ShiftResponseApi(this._dio);

  /// GET /shift/pending-responses - Get pending shift responses
  Future<Map<String, dynamic>> getPendingResponses() async {
    try {
      final response = await _dio.get(ApiEndpoints.shiftPendingResponses);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /shift/{id}/respond - Respond to shift (accept/reject)
  Future<Map<String, dynamic>> respond({
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
          if (reason != null) 'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

}

class DailyTaskApi {
 final Dio _dio;

 DailyTaskApi(this._dio);

 /// GET /daily-task/today - Get today's daily tasks for logged in employee
 Future<Map<String, dynamic>> getTodayTasks() async {
 try {
 final response = await _dio.get(ApiEndpoints.dailyTaskToday);
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// GET /daily-task/{id} - Get task detail
 Future<Map<String, dynamic>> getTaskDetail(int taskId) async {
 try {
 final response = await _dio.get('${ApiEndpoints.dailyTask}/$taskId');
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// GET /daily-task/items - Get available task items
 Future<Map<String, dynamic>> getItems() async {
 try {
 final response = await _dio.get(ApiEndpoints.dailyTaskItems);
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// GET /daily-task/tools - Get available tools
 Future<Map<String, dynamic>> getTools() async {
 try {
 final response = await _dio.get(ApiEndpoints.dailyTaskTools);
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// GET /daily-task/chemicals - Get available chemicals
 Future<Map<String, dynamic>> getChemicals() async {
 try {
 final response = await _dio.get(ApiEndpoints.dailyTaskChemicals);
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// GET /daily-task/ppes - Get available PPEs
 Future<Map<String, dynamic>> getPpes() async {
 try {
 final response = await _dio.get(ApiEndpoints.dailyTaskPpes);
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// GET /daily-task/history - Get task history
 Future<Map<String, dynamic>> getHistory({int page = 1, int perPage = 15}) async {
 try {
 final response = await _dio.get(
 ApiEndpoints.dailyTaskHistory,
 queryParameters: {'page': page, 'per_page': perPage},
 );
 return response.data as Map<String, dynamic>;
 } on DioException catch (e) {
 throw ApiException.fromDioException(e);
 }
 }

 /// POST /daily-task/{id}/start - Start a task
 Future<Map<String, dynamic>> startTask({
 required int taskId,
 required List<String> photos,
 List<int>? toolIds,
 List<int>? chemicalIds,
 List<int>? ppeIds,
 }) async {
 try {
 final formData = FormData();

 // Add photos as base64
 if (photos.isNotEmpty) {
 for (int i = 0; i < photos.length; i++) {
 final file = File(photos[i]);
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

 // Add tool IDs
 if (toolIds != null && toolIds.isNotEmpty) {
 for (int i = 0; i < toolIds.length; i++) {
 formData.fields.add(MapEntry('tool_ids[$i]', toolIds[i].toString()));
 }
 }

 // Add chemical IDs
 if (chemicalIds != null && chemicalIds.isNotEmpty) {
 for (int i = 0; i < chemicalIds.length; i++) {
 formData.fields.add(MapEntry('chemical_ids[$i]', chemicalIds[i].toString()));
 }
 }

 // Add PPE IDs
 if (ppeIds != null && ppeIds.isNotEmpty) {
 for (int i = 0; i < ppeIds.length; i++) {
 formData.fields.add(MapEntry('ppe_ids[$i]', ppeIds[i].toString()));
 }
 }

 final response = await _dio.post(
 '${ApiEndpoints.dailyTask}/$taskId/start',
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

  /// POST /daily-task/{id}/finish - Finish a task
  Future<Map<String, dynamic>> finishTask({
    required int taskId,
    required List<String> photos,
    String? notes,
  }) async {
    try {
      final formData = FormData();

      // Add photos as base64
      if (photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final file = File(photos[i]);
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

      // Add notes
      if (notes != null && notes.isNotEmpty) {
        formData.fields.add(MapEntry('notes', notes));
      }

      final response = await _dio.post(
        '${ApiEndpoints.dailyTask}/$taskId/finish',
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

  // ====================
  // Supervisor Assignment APIs
  // ====================

  /// GET /admin/daily-task-assignments - Get assignments list
  Future<Map<String, dynamic>> getAssignments({int page = 1, int perPage = 15, String? status}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.dailyTaskAssignments,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /admin/daily-task-assignments/employees - Get employees for assignment
  Future<Map<String, dynamic>> getAssignmentEmployees() async {
    try {
      final response = await _dio.get(ApiEndpoints.dailyTaskAssignmentEmployees);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /admin/daily-task-assignments - Create new assignment
  Future<Map<String, dynamic>> createAssignment({
    required int employeeId,
    int? targetMinutes,
    String? assignedDate,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.dailyTaskAssignments,
        data: {
          'employee_id': employeeId,
          if (targetMinutes != null) 'target_minutes': targetMinutes,
          if (assignedDate != null) 'assigned_date': assignedDate,
          if (notes != null) 'notes': notes,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /admin/daily-task-assignments/{id} - Delete assignment
  Future<Map<String, dynamic>> deleteAssignment(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.dailyTaskAssignments}/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ====================
  // Mobile Task Assignment APIs (uses daily_task_assign privilege)
  // ====================

  /// GET /daily-task/assign/employees - Get employees that can be assigned tasks
  Future<Map<String, dynamic>> getMobileAssignEmployees() async {
    try {
      final response = await _dio.get(ApiEndpoints.dailyTaskMobileAssignEmployees);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /daily-task/assign - Assign a task to an employee
  Future<Map<String, dynamic>> mobileAssignTask({
    required int employeeId,
    int? itemId,
    int? areaId,
    int? targetMinutes,
    String? targetNote,
    String? notes,
    String? assignedDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.dailyTaskMobileAssign,
        data: {
          'employee_id': employeeId,
          if (itemId != null) 'item_id': itemId,
          if (areaId != null) 'area_id': areaId,
          if (targetMinutes != null) 'target_minutes': targetMinutes,
          if (targetNote != null) 'target_note': targetNote,
          if (notes != null) 'notes': notes,
          if (assignedDate != null) 'assigned_date': assignedDate,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /daily-task/my-assignments - Get tasks assigned by current user (TL)
  Future<Map<String, dynamic>> getMyAssignments() async {
    try {
      final response = await _dio.get(ApiEndpoints.dailyTaskMyAssignments);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /daily-task/review-criteria - Get review criteria
  Future<Map<String, dynamic>> getReviewCriteria() async {
    try {
      final response = await _dio.get(ApiEndpoints.dailyTaskReviewCriteria);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /daily-task/{id}/review - Submit review for a task
  Future<Map<String, dynamic>> submitReview({
    required int taskId,
    required List<Map<String, dynamic>> scores,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.dailyTask}/$taskId/review',
        data: {
          'scores': scores,
          if (notes != null) 'notes': notes,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

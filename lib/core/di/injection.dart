import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
          'email': code, // Backend expects 'email' field, can be NIK or email
          'password': password,
          'fcm_token': ?fcmToken,
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
          'biometric_token': ?biometricToken,
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
    
    final response = await _dio.get(ApiEndpoints.attendanceToday);
    
    
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
    
    
    try {
      final response = await _dio.post(
        ApiEndpoints.attendance,
        data: {
          'type': type,
          'photo': photo,
          'lat': ?lat,
          'lng': ?lng,
          'notes': ?notes,
          'liveness_passed': ?livenessPassed,
          'face_match_score': ?faceMatchScore,
          'freq_ratio': ?freqRatio,
          'texture_score': ?textureScore,
          'early_leave_notes': ?earlyLeaveNotes,
          'captured_at': ?capturedAt,
        },
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      
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
    
    
    try {
      final response = await _dio.post(
        ApiEndpoints.attendanceFaceVerify,
        data: {
          'photo': photo,
          'captured_at': capturedAt,
          'lat': ?lat,
          'lng': ?lng,
          'type': ?type,
          'notes': ?notes,
          'idempotency_key': ?idempotencyKey,
        },
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /attendance/status/{jobUuid} - Check attendance job status
  Future<Map<String, dynamic>> getAttendanceStatus(String jobUuid) async {
    
    try {
      final response = await _dio.get(ApiEndpoints.attendanceStatus(jobUuid));
      
      return response.data as Map<String, dynamic>;
    } on DioException {
      
      
      
      rethrow;
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
    
    try {
      final formData = FormData();
      for (int i = 0; i < photoPaths.length; i++) {
        final path = photoPaths[i];
        
        formData.files.add(MapEntry(
          'photos[]',
          await MultipartFile.fromFile(path, filename: 'face_$i.jpg'),
        ));
      }

      
      final response = await _dio.post(
        ApiEndpoints.faceEnrollment,
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
  /// OTP is validated on backend using checkpoint secret_key
  Future<Map<String, dynamic>> scan({
    required String qrCode,
    required double latitude,
    required double longitude,
    String? otp,
    String? deviceId,
    bool? isMockLocation,
    String? scannedAtLocal,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.patrolScan,
        data: {
          'qr_code': qrCode,
          'latitude': latitude,
          'longitude': longitude,
          'otp': ?otp,
          'device_id': ?deviceId,
          'is_mock_location': ?isMockLocation,
          'scanned_at_local': ?scannedAtLocal,
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

  /// GET /patrol/otp - Get checkpoint TOTP info after QR scan
  Future<Map<String, dynamic>> getOtp({String? qrCode}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.patrolOtp,
        queryParameters: qrCode != null ? {'qr_code': qrCode} : null,
      );
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
        'description': ?description,
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

  /// GET /notifications - Get notifications list
  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /notifications/unread-count - Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data as Map<String, dynamic>;
      return data['unread_count'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /notifications/{id}/read - Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post(ApiEndpoints.notificationRead(notificationId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /notifications/read-all - Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.post(ApiEndpoints.notificationsMarkAllRead);
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int;
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

class PurchaseRequestApi {
  final Dio _dio;

  PurchaseRequestApi(this._dio);

  /// GET /purchase-requests - Get all purchase requests (paginated)
  Future<Map<String, dynamic>> getPurchaseRequests({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.purchaseRequests,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /purchase-requests/{id} - Get purchase request detail
  Future<Map<String, dynamic>> getPurchaseRequestDetail(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.purchaseRequest(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /purchase-requests - Create a new purchase request
  Future<Map<String, dynamic>> createPurchaseRequest({
    required String date,
    String? supplier,
    required String notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.purchaseRequests,
        data: {
          'date': date,
          if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
          'notes': notes,
          'details': details,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /purchase-requests/{id} - Update a purchase request
  Future<Map<String, dynamic>> updatePurchaseRequest({
    required int id,
    required String date,
    String? supplier,
    required String notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.purchaseRequest(id),
        data: {
          'date': date,
          if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
          'notes': notes,
          'details': details,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /purchase-requests/{id} - Delete a purchase request
  Future<Map<String, dynamic>> deletePurchaseRequest(int id) async {
    try {
      final response = await _dio.delete(ApiEndpoints.purchaseRequest(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /purchase-requests/{id}/submit - Submit for approval
  Future<Map<String, dynamic>> submitPurchaseRequest(int id) async {
    try {
      final response = await _dio.post(ApiEndpoints.purchaseRequestSubmit(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /purchase-requests/products-select-options - Get products for dropdown
  Future<Map<String, dynamic>> getProductOptions({String? query}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.purchaseRequestProducts,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
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
          'location': ?location,
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
          'reason': ?reason,
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
 /// Optional: pass q parameter for search, role_ids[] for filtering by roles
 Future<Map<String, dynamic>> getItems({String? query, List<int>? roleIds}) async {
  try {
   // Build query string manually for reliable Laravel array binding
   final queryParts = <String>[];
   if (query != null && query.isNotEmpty) {
    queryParts.add('q=${Uri.encodeComponent(query)}');
   }
   if (roleIds != null && roleIds.isNotEmpty) {
    for (var id in roleIds) {
     queryParts.add('role_ids[]=$id');
    }
   }

   final queryString = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
   final url = '${ApiEndpoints.dailyTaskItems}$queryString';

   // Debug: log the URL being called
   debugPrint('DailyTaskApi.getItems: calling $url');

   final response = await _dio.get(url);

   // Debug: log the response status
   debugPrint('DailyTaskApi.getItems: response status = ${response.statusCode}');

   return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
   debugPrint('DailyTaskApi.getItems: DioException - $e');
   throw ApiException.fromDioException(e);
  }
 }

 /// GET /daily-task/roles - Get available roles for daily task items
 Future<Map<String, dynamic>> getRoles() async {
  try {
   final response = await _dio.get(ApiEndpoints.dailyTaskRoles);
   return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
   throw ApiException.fromDioException(e);
  }
 }

 /// GET /daily-task/tools - Get available tools
 /// Optional: pass q parameter for search
 Future<Map<String, dynamic>> getTools({String? query}) async {
  try {
   final response = await _dio.get(
    ApiEndpoints.dailyTaskTools,
    queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
   );
   return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
   throw ApiException.fromDioException(e);
  }
 }

 /// GET /daily-task/chemicals - Get available chemicals
 /// Optional: pass q parameter for search
 Future<Map<String, dynamic>> getChemicals({String? query}) async {
  try {
   final response = await _dio.get(
    ApiEndpoints.dailyTaskChemicals,
    queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
   );
   return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
   throw ApiException.fromDioException(e);
  }
 }

 /// GET /daily-task/ppes - Get available PPEs
 /// Optional: pass q parameter for search
 Future<Map<String, dynamic>> getPpes({String? query}) async {
  try {
   final response = await _dio.get(
    ApiEndpoints.dailyTaskPpes,
    queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
   );
   return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
   throw ApiException.fromDioException(e);
  }
 }

 /// GET /daily-task/machines - Get available machines
 /// Optional: pass q parameter for search
 Future<Map<String, dynamic>> getMachines({String? query}) async {
  try {
   final response = await _dio.get(
    ApiEndpoints.dailyTaskMachines,
    queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
   );
   return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
   throw ApiException.fromDioException(e);
  }
 }

 /// GET /product-areas/area/{areaId} - Get products from product_areas by area
 /// Used for mobile task assignment to show available tools/chemicals/ppes/machines from area stock
 Future<Map<String, dynamic>> getProductsByArea({
   required int areaId,
   String? query,
   int? categoryType,
 }) async {
   try {
     final queryParts = <String>[];
     if (query != null && query.isNotEmpty) {
       queryParts.add('q=${Uri.encodeComponent(query)}');
     }
     if (categoryType != null) {
       queryParts.add('category_type=$categoryType');
     }

     final queryString = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
     final url = '${ApiEndpoints.productAreasByArea}/$areaId$queryString';

     debugPrint('DailyTaskApi.getProductsByArea: calling $url');

     final response = await _dio.get(url);
     return response.data as Map<String, dynamic>;
   } on DioException catch (e) {
     debugPrint('DailyTaskApi.getProductsByArea: DioException - $e');
     throw ApiException.fromDioException(e);
   }
 }

 // ====================
 // Unified Inventory API Methods
 // These use the new /inventory-items endpoint which combines warehouse + area tracking
 // ====================

 /// GET /inventory-items/by-area/{areaId} - Get inventory items by area (unified)
 /// This is the new unified endpoint for mobile daily task
 Future<Map<String, dynamic>> getInventoryByArea({
   required int areaId,
   String? query,
   String? categoryType,
 }) async {
   try {
     final queryParts = <String>[];
     if (query != null && query.isNotEmpty) {
       queryParts.add('query=${Uri.encodeComponent(query)}');
     }
     if (categoryType != null && categoryType.isNotEmpty) {
       queryParts.add('category_type=$categoryType');
     }

     final queryString = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
     final url = '${ApiEndpoints.inventoryByArea}/$areaId$queryString';

     debugPrint('DailyTaskApi.getInventoryByArea: calling $url');

     final response = await _dio.get(url);
     return response.data as Map<String, dynamic>;
   } on DioException catch (e) {
     debugPrint('DailyTaskApi.getInventoryByArea: DioException - $e');
     throw ApiException.fromDioException(e);
   }
 }

 /// GET /inventory-items/scan/{qrCode} - Scan QR code for quick lookup
 Future<Map<String, dynamic>> scanInventoryItem(String qrCode) async {
   try {
     final url = '${ApiEndpoints.inventoryScan}/${Uri.encodeComponent(qrCode)}';
     debugPrint('DailyTaskApi.scanInventoryItem: calling $url');
     final response = await _dio.get(url);
     return response.data as Map<String, dynamic>;
   } on DioException catch (e) {
     debugPrint('DailyTaskApi.scanInventoryItem: DioException - $e');
     throw ApiException.fromDioException(e);
   }
 }

 /// GET /inventory-items/{qrCode}/movements - Get movement history for an item
 Future<Map<String, dynamic>> getInventoryMovements(String qrCode) async {
   try {
     final url = '${ApiEndpoints.inventoryMovements}/${Uri.encodeComponent(qrCode)}/movements';
     debugPrint('DailyTaskApi.getInventoryMovements: calling $url');
     final response = await _dio.get(url);
     return response.data as Map<String, dynamic>;
   } on DioException catch (e) {
     debugPrint('DailyTaskApi.getInventoryMovements: DioException - $e');
     throw ApiException.fromDioException(e);
   }
 }

 /// POST /inventory-items/condition - Update item condition from daily task
 Future<Map<String, dynamic>> updateInventoryCondition({
   required String qrCode,
   required String condition,
   double? currentStock,
   String? notes,
 }) async {
   try {
     final response = await _dio.post(
       ApiEndpoints.inventoryCondition,
       data: {
         'qr_code': qrCode,
         'condition': condition,
         if (currentStock != null) 'current_stock': currentStock,
         if (notes != null) 'notes': notes,
       },
     );
     return response.data as Map<String, dynamic>;
   } on DioException catch (e) {
     debugPrint('DailyTaskApi.updateInventoryCondition: DioException - $e');
     throw ApiException.fromDioException(e);
   }
 }

 /// POST /inventory-items/transfer - Transfer item between locations
 Future<Map<String, dynamic>> transferInventoryItem({
   required String qrCode,
   required String locationType,
   required int locationId,
   String? condition,
   String? notes,
 }) async {
   try {
     final response = await _dio.post(
       ApiEndpoints.inventoryTransfer,
       data: {
         'qr_code': qrCode,
         'location_type': locationType,
         'location_id': locationId,
         if (condition != null) 'condition': condition,
         if (notes != null) 'notes': notes,
       },
     );
     return response.data as Map<String, dynamic>;
   } on DioException catch (e) {
     debugPrint('DailyTaskApi.transferInventoryItem: DioException - $e');
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
 /// Include initial conditions for tools, ppes, machines, and chemicals
 Future<Map<String, dynamic>> startTask({
 required int taskId,
 required List<String> photos,
 List<Map<String, String>>? toolConditions,
 List<Map<String, String>>? ppeConditions,
 List<Map<String, String>>? machineConditions,
 List<Map<String, String>>? chemicalConditions,
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

 // Add tool conditions
 if (toolConditions != null && toolConditions.isNotEmpty) {
 for (int i = 0; i < toolConditions.length; i++) {
 formData.fields.add(MapEntry(
 'tool_conditions[$i][product_id]',
 toolConditions[i]['product_id']!,
 ));
 formData.fields.add(MapEntry(
 'tool_conditions[$i][condition]',
 toolConditions[i]['condition']!,
 ));
 }
 }

 // Add PPE conditions
 if (ppeConditions != null && ppeConditions.isNotEmpty) {
 for (int i = 0; i < ppeConditions.length; i++) {
 formData.fields.add(MapEntry(
 'ppe_conditions[$i][product_id]',
 ppeConditions[i]['product_id']!,
 ));
 formData.fields.add(MapEntry(
 'ppe_conditions[$i][condition]',
 ppeConditions[i]['condition']!,
 ));
 }
 }

 // Add machine conditions
 if (machineConditions != null && machineConditions.isNotEmpty) {
 for (int i = 0; i < machineConditions.length; i++) {
 formData.fields.add(MapEntry(
 'machine_conditions[$i][product_id]',
 machineConditions[i]['product_id']!,
 ));
 formData.fields.add(MapEntry(
 'machine_conditions[$i][condition]',
 machineConditions[i]['condition']!,
 ));
 }
 }

 // Add chemical conditions
 if (chemicalConditions != null && chemicalConditions.isNotEmpty) {
 for (int i = 0; i < chemicalConditions.length; i++) {
 formData.fields.add(MapEntry(
 'chemical_conditions[$i][product_id]',
 chemicalConditions[i]['product_id']!,
 ));
 formData.fields.add(MapEntry(
 'chemical_conditions[$i][condition]',
 chemicalConditions[i]['condition']!,
 ));
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
  /// Include final conditions for tools, ppes, machines, and chemicals
  Future<Map<String, dynamic>> finishTask({
    required int taskId,
    required List<String> photos,
    String? notes,
    List<Map<String, String>>? toolConditions,
    List<Map<String, String>>? ppeConditions,
    List<Map<String, String>>? machineConditions,
    List<Map<String, String>>? chemicalConditions,
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

      // Add tool conditions
      if (toolConditions != null && toolConditions.isNotEmpty) {
        for (int i = 0; i < toolConditions.length; i++) {
          formData.fields.add(MapEntry(
            'tool_conditions[$i][product_id]',
            toolConditions[i]['product_id']!,
          ));
          formData.fields.add(MapEntry(
            'tool_conditions[$i][condition]',
            toolConditions[i]['condition']!,
          ));
        }
      }

      // Add PPE conditions
      if (ppeConditions != null && ppeConditions.isNotEmpty) {
        for (int i = 0; i < ppeConditions.length; i++) {
          formData.fields.add(MapEntry(
            'ppe_conditions[$i][product_id]',
            ppeConditions[i]['product_id']!,
          ));
          formData.fields.add(MapEntry(
            'ppe_conditions[$i][condition]',
            ppeConditions[i]['condition']!,
          ));
        }
      }

      // Add machine conditions
      if (machineConditions != null && machineConditions.isNotEmpty) {
        for (int i = 0; i < machineConditions.length; i++) {
          formData.fields.add(MapEntry(
            'machine_conditions[$i][product_id]',
            machineConditions[i]['product_id']!,
          ));
          formData.fields.add(MapEntry(
            'machine_conditions[$i][condition]',
            machineConditions[i]['condition']!,
          ));
        }
      }

      // Add chemical conditions
      if (chemicalConditions != null && chemicalConditions.isNotEmpty) {
        for (int i = 0; i < chemicalConditions.length; i++) {
          formData.fields.add(MapEntry(
            'chemical_conditions[$i][product_id]',
            chemicalConditions[i]['product_id']!,
          ));
          formData.fields.add(MapEntry(
            'chemical_conditions[$i][condition]',
            chemicalConditions[i]['condition']!,
          ));
        }
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
          'status': ?status,
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
          'target_minutes': ?targetMinutes,
          'assigned_date': ?assignedDate,
          'notes': ?notes,
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

  /// DELETE /daily-task/{id} - Delete/cancel a task (for TL)
  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.dailyTask}/$taskId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /daily-task/{id} - Update a task (for TL)
  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    List<int>? employeeIds,
    int? itemId,
    String? assignedDate,
    int? targetMinutes,
    String? notes,
    List<int>? toolIds,
    List<int>? chemicalIds,
    List<int>? ppeIds,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (employeeIds != null) data['employee_ids'] = employeeIds;
      if (itemId != null) data['item_id'] = itemId;
      if (assignedDate != null) data['assigned_date'] = assignedDate;
      if (targetMinutes != null) data['target_minutes'] = targetMinutes;
      if (notes != null) data['notes'] = notes;
      if (toolIds != null) data['tool_ids'] = toolIds;
      if (chemicalIds != null) data['chemical_ids'] = chemicalIds;
      if (ppeIds != null) data['ppe_ids'] = ppeIds;

      final response = await _dio.put(
        '${ApiEndpoints.dailyTask}/$taskId',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ====================
  // Mobile Task Assignment APIs (uses daily_task_assign privilege)
  // ====================

  /// GET /daily-task/assign/employees - Get employees that can be assigned tasks
  /// Optional: pass q parameter for search, role_ids[] for filtering by roles
  Future<Map<String, dynamic>> getMobileAssignEmployees({String? query, List<int>? roleIds}) async {
    try {
      // Build query string manually for reliable Laravel array binding
      final queryParts = <String>[];
      if (query != null && query.isNotEmpty) {
        queryParts.add('q=${Uri.encodeComponent(query)}');
      }
      if (roleIds != null && roleIds.isNotEmpty) {
        for (var id in roleIds) {
          queryParts.add('role_ids[]=$id');
        }
      }

      final queryString = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final url = '${ApiEndpoints.dailyTaskMobileAssignEmployees}$queryString';


      final response = await _dio.get(url);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /daily-task/assign - Assign a task to employees (supports multiple)
  Future<Map<String, dynamic>> mobileAssignTask({
    required List<int> employeeIds,
    int? itemId,
    int? areaId,
    int? targetMinutes,
    String? targetNote,
    String? notes,
    String? assignedDate,
    List<int>? toolIds,
    List<int>? chemicalIds,
    List<int>? ppeIds,
    List<int>? machineIds,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.dailyTaskMobileAssign,
        data: {
          'employee_ids': employeeIds,
          'item_id': ?itemId,
          'area_id': ?areaId,
          'target_minutes': ?targetMinutes,
          'target_note': ?targetNote,
          'notes': ?notes,
          'assigned_date': ?assignedDate,
          if (toolIds != null && toolIds.isNotEmpty) 'tool_ids': toolIds,
          if (chemicalIds != null && chemicalIds.isNotEmpty) 'chemical_ids': chemicalIds,
          if (ppeIds != null && ppeIds.isNotEmpty) 'ppe_ids': ppeIds,
          if (machineIds != null && machineIds.isNotEmpty) 'machine_ids': machineIds,
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
          'notes': ?notes,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// Client API for mobile app - authenticated as Client
class ClientApi {
  final Dio _dio;

  ClientApi(this._dio);

  /// GET /client/dashboard - Get client dashboard overview
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.clientDashboard);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/employees - Get employees placed at this client
  Future<Map<String, dynamic>> getEmployees() async {
    try {
      final response = await _dio.get(ApiEndpoints.clientEmployees);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/areas - Get areas for this client
  Future<Map<String, dynamic>> getAreas() async {
    try {
      final response = await _dio.get(ApiEndpoints.clientAreas);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/attendance/today - Get today's attendance
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final response = await _dio.get(ApiEndpoints.clientAttendanceToday);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/attendance - Get attendance history
  Future<Map<String, dynamic>> getAttendanceHistory({
    String? fromDate,
    String? toDate,
    int? employeeId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.clientAttendance,
        queryParameters: {
          'from_date': ?fromDate,
          'to_date': ?toDate,
          'employee_id': ?employeeId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/daily-tasks - Get daily task reports
  Future<Map<String, dynamic>> getDailyTasks({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.clientDailyTasks,
        queryParameters: {
          'from_date': ?fromDate,
          'to_date': ?toDate,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/patrol-reports - Get patrol reports
  Future<Map<String, dynamic>> getPatrolReports({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.clientPatrolReports,
        queryParameters: {
          'from_date': ?fromDate,
          'to_date': ?toDate,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/field-reports - Get field reports
  Future<Map<String, dynamic>> getFieldReports({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.clientFieldReports,
        queryParameters: {
          'from_date': ?fromDate,
          'to_date': ?toDate,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/profile - Get client profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.clientProfile);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /client/password - Change client password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        ApiEndpoints.clientChangePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/schedules/dates - Get schedule dates for calendar
  Future<Map<String, dynamic>> getScheduleDates({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.clientScheduleDates,
        queryParameters: {
          'year': year,
          'month': month,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /client/schedules/employees - Get employees scheduled on a date
  Future<Map<String, dynamic>> getScheduleEmployees({
    required String date,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.clientScheduleEmployees,
        queryParameters: {
          'date': date,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

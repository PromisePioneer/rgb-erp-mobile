import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// Repository for patrol operations
class PatrolRepository {
  final PatrolApi _api;

  PatrolRepository({required this._api});

  /// Get today's patrol status
  Future<PatrolTodayStatus> getTodayStatus() async {
    try {
      final response = await _api.getTodayStatus();
      return PatrolTodayStatus.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Scan a checkpoint QR code
  /// OTP is validated on backend using checkpoint secret_key
  Future<PatrolScanResult> scan({
    required String qrCode,
    required double latitude,
    required double longitude,
    String? otp,
    String? deviceId,
    bool? isMockLocation,
    String? scannedAtLocal,
  }) async {
    try {
      final response = await _api.scan(
        qrCode: qrCode,
        latitude: latitude,
        longitude: longitude,
        otp: otp,
        deviceId: deviceId,
        isMockLocation: isMockLocation,
        scannedAtLocal: scannedAtLocal,
      );
      return PatrolScanResult.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get checkpoint TOTP info after QR scan
  Future<PatrolOtpResponse> getOtp({String? qrCode}) async {
    try {
      final response = await _api.getOtp(qrCode: qrCode);
      return PatrolOtpResponse.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

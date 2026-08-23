import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// Repository for patrol operations
class PatrolRepository {
  final PatrolApi _api;

  PatrolRepository({required PatrolApi api}) : _api = api;

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
  Future<PatrolScanResult> scan({
    required String qrCode,
    required double latitude,
    required double longitude,
    String? deviceId,
    bool? isMockLocation,
    String? scannedAtLocal,
    String? otpCode,
  }) async {
    try {
      final response = await _api.scan(
        qrCode: qrCode,
        latitude: latitude,
        longitude: longitude,
        deviceId: deviceId,
        isMockLocation: isMockLocation,
        scannedAtLocal: scannedAtLocal,
        otpCode: otpCode,
      );
      return PatrolScanResult.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

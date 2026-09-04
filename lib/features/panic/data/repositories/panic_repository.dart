import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/panic_alert_result.dart';

// Re-export PanicApi from injection for convenience
export '../../../../core/di/injection.dart' show PanicApi;

/// Repository for panic alert operations
class PanicRepository {
  final PanicApi _api;

  PanicRepository(this._api);

  /// Send a panic alert
  Future<PanicAlertResult> sendPanicAlert({
    required String type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    
    try {
      final data = await _api.sendPanicAlert(
        type: type,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );
      
      return PanicAlertResult.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      
      throw ApiException(
        message: 'Gagal mengirim panic alert: $e',
        statusCode: 500,
      );
    }
  }

  /// Get current panic alert status
  Future<PanicAlertStatus> getPanicStatus() async {
    try {
      final data = await _api.getPanicStatus();
      return PanicAlertStatus.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal mengambil status panic alert: $e',
        statusCode: 500,
      );
    }
  }
}

/// Factory for creating PanicRepository
PanicRepository createPanicRepository(Dio dio) {
  return PanicRepository(PanicApi(dio));
}

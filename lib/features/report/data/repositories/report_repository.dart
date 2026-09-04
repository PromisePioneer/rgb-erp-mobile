
import '../../../../core/network/api_exception.dart';
import '../../../../core/di/injection.dart';
import '../../domain/domain.dart';

// Re-export Api from injection
export '../../../../core/di/injection.dart' show ReportApi;

/// Repository for field report operations
class ReportRepository {
  final ReportApi _api;

  ReportRepository(this._api);

  /// Get the current user's field reports (personal list)
  Future<List<Report>> getReports() async {
    try {
      final response = await _api.getReports();
      final reportsData = response['reports'];

      if (reportsData == null) return [];

      final List<dynamic> dataList = reportsData is List ? reportsData : [];
      return dataList
          .map((json) => Report.fromJson(_safeToMap(json)!))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar laporan: $e',
        statusCode: 500,
      );
    }
  }

  /// Get reports grouped by area (for supervisors/managers)
  Future<List<ReportArea>> getReportsByArea() async {
    try {
      final response = await _api.getReportsByArea();
      final areasData = response['areas'];

      if (areasData == null) return [];

      final List<dynamic> dataList = areasData is List ? areasData : [];
      return dataList
          .map((json) => ReportArea.fromJson(_safeToMap(json)!))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat laporan per area: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit a new field report
  Future<int> submitReport({
    required String description,
    required double latitude,
    required double longitude,
    String? location,
  }) async {
    try {
      final response = await _api.submitReport(
        description: description,
        latitude: latitude,
        longitude: longitude,
        location: location,
      );

      final id = response['id'];
      if (id == null) {
        throw ApiException(
          message: 'Format response tidak valid',
          statusCode: 500,
        );
      }

      return int.parse(id.toString());
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menyimpan laporan mutasi: $e',
        statusCode: 500,
      );
    }
  }

  Map<String, dynamic>? _safeToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

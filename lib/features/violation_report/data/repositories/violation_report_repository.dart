import '../../../../core/core.dart';
import '../../domain/domain.dart';

// Re-export Api from injection
export '../../../../core/di/injection.dart' show ViolationReportApi;

/// Repository for violation report operations
class ViolationReportRepository {
  final ViolationReportApi _api;

  ViolationReportRepository(this._api);

  /// Get violation types (hierarchical)
  Future<List<ViolationType>> getViolationTypes() async {
    try {
      final response = await _api.getViolationTypes();

      // Handle different response formats safely
      final responseData = response['data'];
      if (responseData == null) {
        return [];
      }

      List<dynamic> dataList;
      if (responseData is List) {
        dataList = responseData;
      } else {
        return [];
      }

      // Check if data is nested (has children) or flat (has parent_id)
      final List<Map<String, dynamic>> typedList = dataList
          .map((json) => _safeToMap(json) ?? {})
          .toList();

      // Check first item to determine format
      if (typedList.isNotEmpty && typedList.first.containsKey('children')) {
        // Nested format
        return typedList
            .map((json) => ViolationType.fromJson(json))
            .toList();
      } else {
        // Flat format with parent_id - build hierarchy
        return ViolationType.buildHierarchyFromJson(typedList);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat jenis pelanggaran: $e',
        statusCode: 500,
      );
    }
  }

  /// Get areas for violation report
  Future<List<ViolationArea>> getAreas() async {
    try {
      final response = await _api.getAreas();

      // Handle different response formats safely
      final responseData = response['data'];
      if (responseData == null) {
        return [];
      }

      List<dynamic> dataList;
      if (responseData is List) {
        dataList = responseData;
      } else {
        return [];
      }

      return dataList
          .map((json) => ViolationArea.fromJson(_safeToMap(json)!))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar area: $e',
        statusCode: 500,
      );
    }
  }

  /// Get employees by area
  Future<List<ViolationEmployee>> getEmployeesByArea(int areaId) async {
    try {
      final response = await _api.getEmployeesByArea(areaId);

      // Handle different response formats safely
      final responseData = response['data'];
      if (responseData == null) {
        return [];
      }

      List<dynamic> dataList;
      if (responseData is List) {
        dataList = responseData;
      } else {
        return [];
      }

      return dataList
          .map((json) => ViolationEmployee.fromJson(_safeToMap(json)!))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar karyawan: $e',
        statusCode: 500,
      );
    }
  }

  /// Submit violation report
  Future<ViolationReportResult> submitViolation({
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
      final response = await _api.submitViolation(
        areaId: areaId,
        employeeId: employeeId,
        violationTypeId: violationTypeId,
        capturedAt: capturedAt,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        action: action,
        photoPaths: photoPaths,
      );

      final dataMap = _safeToMap(response['data']);
      if (dataMap == null) {
        throw ApiException(
          message: 'Format response tidak valid',
          statusCode: 500,
        );
      }

      return ViolationReportResult.fromJson(dataMap);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menyimpan temuan pelanggaran: $e',
        statusCode: 500,
      );
    }
  }

  /// Get logged in user's violation reports
  Future<List<ViolationReportResult>> getUserViolations() async {
    try {
      final response = await _api.getUserViolations();

      // Handle different response formats safely
      final responseData = response['data'];
      if (responseData == null) {
        return [];
      }

      List<dynamic> dataList;
      if (responseData is List) {
        dataList = responseData;
      } else if (responseData is Map && responseData['items'] is List) {
        dataList = responseData['items'] as List;
      } else if (responseData is Map && responseData['data'] is List) {
        dataList = responseData['data'] as List;
      } else {
        // Try to convert single object to list
        return [ViolationReportResult.fromJson(_safeToMap(responseData)!)];
      }

      return dataList
          .map((json) => ViolationReportResult.fromJson(_safeToMap(json)!))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat riwayat laporan: $e',
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

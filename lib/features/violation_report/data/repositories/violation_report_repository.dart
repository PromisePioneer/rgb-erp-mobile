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
      final data = response['data'] as List<dynamic>? ?? [];

      // Check if data is nested (has children) or flat (has parent_id)
      final List<Map<String, dynamic>> typedList = data.map((json) {
        if (json is Map<String, dynamic>) return json;
        return <String, dynamic>{};
      }).toList();

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

  /// Get projects for violation report
  Future<List<ViolationProject>> getProjects() async {
    try {
      final response = await _api.getProjects();
      final data = response['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => ViolationProject.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar project: $e',
        statusCode: 500,
      );
    }
  }

  /// Get employees by project
  Future<List<ViolationEmployee>> getEmployeesByProject(int projectId) async {
    try {
      final response = await _api.getEmployeesByProject(projectId);
      final data = response['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => ViolationEmployee.fromJson(json as Map<String, dynamic>))
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
      final response = await _api.submitViolation(
        projectId: projectId,
        employeeId: employeeId,
        violationTypeId: violationTypeId,
        capturedAt: capturedAt,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        action: action,
        photoPaths: photoPaths,
      );

      return ViolationReportResult.fromJson(
        response['data'] as Map<String, dynamic>,
      );
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
      final data = response['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => ViolationReportResult.fromJson(json as Map<String, dynamic>))
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
}

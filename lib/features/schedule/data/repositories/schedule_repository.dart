import '../../../../core/core.dart';
import '../../domain/models/schedule_item.dart';

// Re-export ScheduleApi from injection for convenience
export '../../../../core/di/injection.dart' show ScheduleApi;

/// Repository for schedule data operations
class ScheduleRepository {
  final ScheduleApi _api;

  ScheduleRepository(this._api);

  /// Get all schedules
  Future<List<ScheduleItem>> getSchedules() async {
    try {
      final response = await _api.getSchedules();
      final schedules = response['schedules'] as List<dynamic>? ?? [];
      return schedules
          .map((json) => ScheduleItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat jadwal: $e',
        statusCode: 500,
      );
    }
  }
}

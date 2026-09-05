import 'package:dio/dio.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../core/network/api_exception.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<NotificationListResult> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final notifications = (data['notifications'] as List)
          .map((json) => NotificationEntity.fromJson(json as Map<String, dynamic>))
          .toList();

      return NotificationListResult(
        notifications: notifications,
        total: data['total'] as int,
        unreadCount: data['unread_count'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      final data = response.data as Map<String, dynamic>;
      return data['unread_count'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.post('/notifications/read-all');
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class NotificationListResult {
  final List<NotificationEntity> notifications;
  final int total;
  final int unreadCount;

  NotificationListResult({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });
}

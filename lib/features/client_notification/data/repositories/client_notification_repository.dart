import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/client_notification_entity.dart';

/// Repository for client notifications
class ClientNotificationRepository {
  final Dio _dio;

  ClientNotificationRepository(this._dio);

  /// Get notifications for the authenticated client
  Future<ClientNotificationListResult> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/client/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final notifications = (data['notifications'] as List? ?? [])
          .map((json) =>
              ClientNotificationEntity.fromJson(json as Map<String, dynamic>))
          .toList();

      return ClientNotificationListResult(
        notifications: notifications,
        total: data['total'] as int? ?? 0,
        unreadCount: data['unread_count'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get unread notification count for the authenticated client
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/client/notifications/unread-count');
      final data = response.data as Map<String, dynamic>;
      return data['unread_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post('/client/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.post('/client/notifications/read-all');
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// Result class for notification list
class ClientNotificationListResult {
  final List<ClientNotificationEntity> notifications;
  final int total;
  final int unreadCount;

  ClientNotificationListResult({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });
}

import 'package:equatable/equatable.dart';

/// Entity representing a notification for client dashboard
class ClientNotificationEntity extends Equatable {
  final int id;
  final int clientId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? referenceType;
  final int? referenceId;
  final DateTime? readAt;
  final DateTime createdAt;

  const ClientNotificationEntity({
    required this.id,
    required this.clientId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.referenceType,
    this.referenceId,
    this.readAt,
    required this.createdAt,
  });

  factory ClientNotificationEntity.fromJson(Map<String, dynamic> json) {
    return ClientNotificationEntity(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] is String
          ? {}
          : (json['data'] as Map<String, dynamic>? ?? {}),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as int?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isRead => readAt != null;

  /// Get icon based on notification type
  String get iconEmoji {
    switch (type) {
      case 'daily_task_assigned':
        return '📋';
      case 'task_started':
        return '▶️';
      case 'task_ended':
        return '✅';
      case 'attendance_recorded':
        return '👤';
      case 'progress_check':
        return '🔍';
      default:
        return '🔔';
    }
  }

  /// Get human-readable type label
  String get typeLabel {
    switch (type) {
      case 'daily_task_assigned':
        return 'Tugas Baru';
      case 'task_started':
        return 'Tugas Dimulai';
      case 'task_ended':
        return 'Tugas Selesai';
      case 'attendance_recorded':
        return 'Absensi';
      case 'progress_check':
        return 'Progress Check';
      default:
        return 'Notifikasi';
    }
  }

  ClientNotificationEntity copyWith({
    int? id,
    int? clientId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? referenceType,
    int? referenceId,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ClientNotificationEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        type,
        title,
        body,
        data,
        referenceType,
        referenceId,
        readAt,
        createdAt,
      ];
}

import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final int id;
  final int employeeId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? referenceType;
  final int? referenceId;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.referenceType,
    this.referenceId,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] is String ? {} : (json['data'] as Map<String, dynamic>? ?? {}),
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
      'employee_id': employeeId,
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

  NotificationEntity copyWith({
    int? id,
    int? employeeId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? referenceType,
    int? referenceId,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
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
        employeeId,
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

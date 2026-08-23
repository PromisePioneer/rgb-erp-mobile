/// Result of a panic alert submission
class PanicAlertResult {
  final int id;
  final String status;
  final DateTime createdAt;

  const PanicAlertResult({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory PanicAlertResult.fromJson(Map<String, dynamic> json) {
    return PanicAlertResult(
      id: json['id'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Status of an active panic alert
class PanicAlertStatus {
  final int? id;
  final String? status;
  final String? type;
  final DateTime? createdAt;

  const PanicAlertStatus({
    this.id,
    this.status,
    this.type,
    this.createdAt,
  });

  factory PanicAlertStatus.fromJson(Map<String, dynamic> json) {
    final s = json['status'];
    if (s == null) {
      return const PanicAlertStatus();
    }
    return PanicAlertStatus(
      id: json['id'] as int?,
      status: s as String?,
      type: json['type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  bool get hasActiveAlert => status == 'active';
}

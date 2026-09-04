import 'package:equatable/equatable.dart';

/// Represents an approval record for a Purchase Request
class PurchaseRequestApproval extends Equatable {
  final int id;
  final int level;
  final String status;
  final String? note;
  final String? actedAt;

  const PurchaseRequestApproval({
    required this.id,
    required this.level,
    required this.status,
    this.note,
    this.actedAt,
  });

  /// Status labels in Indonesian
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  /// Formatted acted date
  String? get formattedActedAt {
    if (actedAt == null) return null;
    try {
      final date = DateTime.parse(actedAt!);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return actedAt;
    }
  }

  /// Check if this approval step is pending
  bool get isPending => status == 'pending';

  /// Check if this approval step is approved
  bool get isApproved => status == 'approved';

  /// Check if this approval step is rejected
  bool get isRejected => status == 'rejected';

  factory PurchaseRequestApproval.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestApproval(
      id: json['id'] as int,
      level: json['level'] as int,
      status: json['status'] as String,
      note: json['note'] as String?,
      actedAt: json['acted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'status': status,
      'note': note,
      'acted_at': actedAt,
    };
  }

  PurchaseRequestApproval copyWith({
    int? id,
    int? level,
    String? status,
    String? note,
    String? actedAt,
  }) {
    return PurchaseRequestApproval(
      id: id ?? this.id,
      level: level ?? this.level,
      status: status ?? this.status,
      note: note ?? this.note,
      actedAt: actedAt ?? this.actedAt,
    );
  }

  @override
  List<Object?> get props => [id, level, status, note, actedAt];
}

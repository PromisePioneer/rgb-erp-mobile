import 'package:equatable/equatable.dart';

/// Approval entity
class Approval extends Equatable {
  final int id;
  final String type;
  final String typeLabel;
  final String approverKind;
  final int level;
  final String status;
  final String? note;
  final int? actedBy;
  final String? actedAt;
  final ApprovalRequest? request;
  final ApprovalRequestDetails? requestDetails;
  final ApprovalRequester? requester;
  final String? requestDate;
  final double? amount;
  final String? reason;
  final int currentLevel;
  final String? createdAt;

  const Approval({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.approverKind,
    required this.level,
    required this.status,
    this.note,
    this.actedBy,
    this.actedAt,
    this.request,
    this.requestDetails,
    this.requester,
    this.requestDate,
    this.amount,
    this.reason,
    this.currentLevel = 1,
    this.createdAt,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'] as int,
      type: json['type'] as String? ?? json['approvable_type'] as String? ?? '',
      typeLabel: json['type_label'] as String? ?? json['type'] as String? ?? '',
      approverKind: json['approver_kind'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      status: json['status'] as String,
      note: json['note'] as String?,
      actedBy: json['acted_by'] as int?,
      actedAt: json['acted_at'] as String?,
      request: json['request'] != null
          ? ApprovalRequest.fromJson(json['request'] as Map<String, dynamic>)
          : null,
      requestDetails: json['request_details'] != null
          ? ApprovalRequestDetails.fromJson(json['request_details'] as Map<String, dynamic>)
          : null,
      requester: json['requester'] != null
          ? ApprovalRequester.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      requestDate: json['request_date'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      currentLevel: json['current_level'] as int? ?? 1,
      createdAt: json['created_at'] as String?,
    );
  }

  /// Check if approval is pending
  bool get isPending => status == 'pending';

  /// Check if approval is approved
  bool get isApproved => status == 'approved';

  /// Check if approval is rejected
  bool get isRejected => status == 'rejected';

  /// Get status label in Indonesian
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

  /// Get formatted acted date
  String? get formattedActedAt {
    if (actedAt == null) return null;
    try {
      final date = DateTime.parse(actedAt!);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return actedAt;
    }
  }

  /// Get formatted request date
  String? get formattedRequestDate {
    if (requestDate == null) return null;
    try {
      final date = DateTime.parse(requestDate!);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return requestDate;
    }
  }

  /// Get formatted amount
  String get formattedAmount {
    if (amount == null) return '-';
    return 'Rp ${amount!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  List<Object?> get props => [id, type, status];
}

/// Requester info
class ApprovalRequester extends Equatable {
  final int id;
  final String name;

  const ApprovalRequester({
    required this.id,
    required this.name,
  });

  factory ApprovalRequester.fromJson(Map<String, dynamic> json) {
    return ApprovalRequester(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// Simplified request info in approval
class ApprovalRequest extends Equatable {
  final int id;
  final String? code;
  final String status;
  final int? currentLevel;
  final double? total;
  final String? createdAt;

  const ApprovalRequest({
    required this.id,
    this.code,
    required this.status,
    this.currentLevel,
    this.total,
    this.createdAt,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'] as int,
      code: json['code'] as String?,
      status: json['status'] as String? ?? '',
      currentLevel: json['current_level'] as int?,
      total: (json['total'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
    );
  }

  String get formattedTotal {
    if (total == null) return '-';
    return 'Rp ${total!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Get formatted date
  String? get formattedDate {
    if (createdAt == null) return null;
    try {
      final date = DateTime.parse(createdAt!);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  List<Object?> get props => [id, status];
}

/// Request details containing actual content of what's being approved
class ApprovalRequestDetails extends Equatable {
  final String type;
  final String? supplier;
  final String? notes;
  final String? purchaseRequestCode;
  final List<ApprovalItem> items;

  const ApprovalRequestDetails({
    required this.type,
    this.supplier,
    this.notes,
    this.purchaseRequestCode,
    this.items = const [],
  });

  factory ApprovalRequestDetails.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestDetails(
      type: json['type'] as String? ?? 'unknown',
      supplier: json['supplier'] as String?,
      notes: json['notes'] as String?,
      purchaseRequestCode: json['purchase_request_code'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ApprovalItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Calculate total amount
  double get total {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// Format total
  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  List<Object?> get props => [type, supplier, items];
}

/// Item in approval request details
class ApprovalItem extends Equatable {
  final String? productName;
  final double qty;
  final double total;

  const ApprovalItem({
    this.productName,
    required this.qty,
    required this.total,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      productName: json['product_name'] as String?,
      qty: (json['qty'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String get formattedQty {
    if (qty == qty.toInt()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  @override
  List<Object?> get props => [productName, qty, total];
}

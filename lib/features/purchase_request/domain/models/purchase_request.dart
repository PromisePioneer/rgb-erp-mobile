import 'package:equatable/equatable.dart';
import 'purchase_request_detail.dart';
import 'purchase_request_approval.dart';

/// Represents a Purchase Request entity
class PurchaseRequest extends Equatable {
  final int id;
  final String date;
  final String code;
  final String? supplier;
  final String? notes;
  final double total;
  final String status;
  final bool canEdit;
  final bool canSubmit;
  final List<PurchaseRequestDetail> details;
  final List<PurchaseRequestApproval> approvals;
  final String? createdAt;
  final String? updatedAt;

  const PurchaseRequest({
    required this.id,
    required this.date,
    required this.code,
    this.supplier,
    this.notes,
    required this.total,
    required this.status,
    required this.canEdit,
    required this.canSubmit,
    this.details = const [],
    this.approvals = const [],
    this.createdAt,
    this.updatedAt,
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
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  /// Formatted total amount
  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted date
  String get formattedDate {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return date;
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final monthStr = parts[1].trim();
      if (monthStr.isEmpty) return date;
      final monthIndex = int.tryParse(monthStr);
      if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return date;
      return '${parts[2].trim()} ${months[monthIndex - 1]} ${parts[0].trim()}';
    } catch (_) {
      return date;
    }
  }

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    return PurchaseRequest(
      id: json['id'] as int,
      date: json['date'] as String,
      code: json['code'] as String,
      supplier: json['supplier'] as String?,
      notes: json['notes'] as String?,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String? ?? 'draft',
      canEdit: json['can_edit'] as bool? ?? false,
      canSubmit: json['can_submit'] as bool? ?? false,
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => PurchaseRequestDetail.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((a) => PurchaseRequestApproval.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'code': code,
      'supplier': supplier,
      'notes': notes,
      'total': total,
      'status': status,
      'can_edit': canEdit,
      'can_submit': canSubmit,
      'details': details.map((d) => d.toJson()).toList(),
      'approvals': approvals.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  PurchaseRequest copyWith({
    int? id,
    String? date,
    String? code,
    String? supplier,
    String? notes,
    double? total,
    String? status,
    bool? canEdit,
    bool? canSubmit,
    List<PurchaseRequestDetail>? details,
    List<PurchaseRequestApproval>? approvals,
    String? createdAt,
    String? updatedAt,
  }) {
    return PurchaseRequest(
      id: id ?? this.id,
      date: date ?? this.date,
      code: code ?? this.code,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      total: total ?? this.total,
      status: status ?? this.status,
      canEdit: canEdit ?? this.canEdit,
      canSubmit: canSubmit ?? this.canSubmit,
      details: details ?? this.details,
      approvals: approvals ?? this.approvals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        code,
        supplier,
        notes,
        total,
        status,
        canEdit,
        canSubmit,
        details,
        approvals,
        createdAt,
        updatedAt,
      ];
}

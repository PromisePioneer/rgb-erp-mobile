import 'package:equatable/equatable.dart';
import 'reception_detail.dart';
import 'reception_approval.dart';

/// Represents a Reception (Goods Receipt) entity
class Reception extends Equatable {
  final int id;
  final String code;
  final String date;
  final int? purchaseOrderId;
  final String? purchaseOrderCode;
  final String? supplier;
  final int? warehouseId;
  final String? warehouseName;
  final double total;
  final String? notes;
  final String status;
  final bool canEdit;
  final bool canSubmit;
  final List<ReceptionDetail> details;
  final List<ReceptionApproval> approvals;
  final String? createdAt;

  const Reception({
    required this.id,
    required this.code,
    required this.date,
    this.purchaseOrderId,
    this.purchaseOrderCode,
    this.supplier,
    this.warehouseId,
    this.warehouseName,
    required this.total,
    this.notes,
    required this.status,
    required this.canEdit,
    required this.canSubmit,
    this.details = const [],
    this.approvals = const [],
    this.createdAt,
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

  factory Reception.fromJson(Map<String, dynamic> json) {
    return Reception(
      id: json['id'] as int,
      code: json['code'] as String,
      date: json['date'] as String,
      purchaseOrderId: json['purchase_order_id'] as int?,
      purchaseOrderCode: json['purchase_order_code'] as String?,
      supplier: json['supplier'] as String?,
      warehouseId: json['warehouse_id'] as int?,
      warehouseName: json['warehouse_name'] as String?,
      total: (json['total'] as num).toDouble(),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'draft',
      canEdit: json['can_edit'] as bool? ?? false,
      canSubmit: json['can_submit'] as bool? ?? false,
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => ReceptionDetail.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((a) => ReceptionApproval.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'date': date,
      'purchase_order_id': purchaseOrderId,
      'purchase_order_code': purchaseOrderCode,
      'supplier': supplier,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'total': total,
      'notes': notes,
      'status': status,
      'can_edit': canEdit,
      'can_submit': canSubmit,
      'details': details.map((d) => d.toJson()).toList(),
      'approvals': approvals.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
    };
  }

  Reception copyWith({
    int? id,
    String? code,
    String? date,
    int? purchaseOrderId,
    String? purchaseOrderCode,
    String? supplier,
    int? warehouseId,
    String? warehouseName,
    double? total,
    String? notes,
    String? status,
    bool? canEdit,
    bool? canSubmit,
    List<ReceptionDetail>? details,
    List<ReceptionApproval>? approvals,
    String? createdAt,
  }) {
    return Reception(
      id: id ?? this.id,
      code: code ?? this.code,
      date: date ?? this.date,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderCode: purchaseOrderCode ?? this.purchaseOrderCode,
      supplier: supplier ?? this.supplier,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      canEdit: canEdit ?? this.canEdit,
      canSubmit: canSubmit ?? this.canSubmit,
      details: details ?? this.details,
      approvals: approvals ?? this.approvals,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        date,
        purchaseOrderId,
        purchaseOrderCode,
        supplier,
        warehouseId,
        warehouseName,
        total,
        notes,
        status,
        canEdit,
        canSubmit,
        details,
        approvals,
        createdAt,
      ];
}

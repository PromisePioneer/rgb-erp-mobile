import 'package:equatable/equatable.dart';

/// Represents a line item in a Reception
class ReceptionDetail extends Equatable {
  final int id;
  final int productId;
  final String? productName;
  final double qty;
  final double unitCost;
  final double total;
  final int status;

  const ReceptionDetail({
    required this.id,
    required this.productId,
    this.productName,
    required this.qty,
    required this.unitCost,
    required this.total,
    required this.status,
  });

  /// Formatted total amount
  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted unit cost
  String get formattedUnitCost {
    return 'Rp ${unitCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted quantity
  String get formattedQty {
    if (qty == qty.toInt()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  factory ReceptionDetail.fromJson(Map<String, dynamic> json) {
    return ReceptionDetail(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      qty: (json['qty'] as num).toDouble(),
      unitCost: (json['unit_cost'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'unit_cost': unitCost,
      'total': total,
      'status': status,
    };
  }

  ReceptionDetail copyWith({
    int? id,
    int? productId,
    String? productName,
    double? qty,
    double? unitCost,
    double? total,
    int? status,
  }) {
    return ReceptionDetail(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      unitCost: unitCost ?? this.unitCost,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, productId, productName, qty, unitCost, total, status];
}

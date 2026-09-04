import 'package:equatable/equatable.dart';

/// Represents a line item in a Purchase Request
class PurchaseRequestDetail extends Equatable {
  final int id;
  final int productId;
  final String? productName;
  final double qty;
  final double total;
  final int status;

  const PurchaseRequestDetail({
    required this.id,
    required this.productId,
    this.productName,
    required this.qty,
    required this.total,
    required this.status,
  });

  /// Formatted total amount
  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted quantity
  String get formattedQty {
    if (qty == qty.toInt()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  factory PurchaseRequestDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestDetail(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      qty: (json['qty'] as num).toDouble(),
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
      'total': total,
      'status': status,
    };
  }

  PurchaseRequestDetail copyWith({
    int? id,
    int? productId,
    String? productName,
    double? qty,
    double? total,
    int? status,
  }) {
    return PurchaseRequestDetail(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, productId, productName, qty, total, status];
}

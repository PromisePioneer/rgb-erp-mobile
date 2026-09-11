import 'package:equatable/equatable.dart';
import 'fund_request_approval.dart';

/// Represents a Fund Request entity
class FundRequest extends Equatable {
  final int id;
  final String code;
  final int? poId;
  final String? poCode;
  final String? poSupplier;
  final double totalPoAmount;
  final double requestedAmount;
  final double remainingAmount;
  final double taxAmount;
  final String? paymentTerm;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? paymentMethod;
  final String? notes;
  final String status;
  final bool canEdit;
  final bool canSubmit;
  final List<FundRequestApproval> approvals;
  final String? createdAt;

  const FundRequest({
    required this.id,
    required this.code,
    this.poId,
    this.poCode,
    this.poSupplier,
    required this.totalPoAmount,
    required this.requestedAmount,
    required this.remainingAmount,
    required this.taxAmount,
    this.paymentTerm,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.paymentMethod,
    this.notes,
    required this.status,
    required this.canEdit,
    required this.canSubmit,
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

  /// Formatted requested amount
  String get formattedRequestedAmount {
    return 'Rp ${requestedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted total PO amount
  String get formattedTotalPoAmount {
    return 'Rp ${totalPoAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted remaining amount
  String get formattedRemainingAmount {
    return 'Rp ${remainingAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Formatted tax amount
  String get formattedTaxAmount {
    return 'Rp ${taxAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory FundRequest.fromJson(Map<String, dynamic> json) {
    return FundRequest(
      id: json['id'] as int,
      code: json['code'] as String,
      poId: json['po_id'] as int?,
      poCode: json['po_code'] as String?,
      poSupplier: json['po_supplier'] as String?,
      totalPoAmount: (json['total_po_amount'] as num).toDouble(),
      requestedAmount: (json['requested_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      paymentTerm: json['payment_term'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'draft',
      canEdit: json['can_edit'] as bool? ?? false,
      canSubmit: json['can_submit'] as bool? ?? false,
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((a) => FundRequestApproval.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'po_id': poId,
      'po_code': poCode,
      'po_supplier': poSupplier,
      'total_po_amount': totalPoAmount,
      'requested_amount': requestedAmount,
      'remaining_amount': remainingAmount,
      'tax_amount': taxAmount,
      'payment_term': paymentTerm,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'payment_method': paymentMethod,
      'notes': notes,
      'status': status,
      'can_edit': canEdit,
      'can_submit': canSubmit,
      'approvals': approvals.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
    };
  }

  FundRequest copyWith({
    int? id,
    String? code,
    int? poId,
    String? poCode,
    String? poSupplier,
    double? totalPoAmount,
    double? requestedAmount,
    double? remainingAmount,
    double? taxAmount,
    String? paymentTerm,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? paymentMethod,
    String? notes,
    String? status,
    bool? canEdit,
    bool? canSubmit,
    List<FundRequestApproval>? approvals,
    String? createdAt,
  }) {
    return FundRequest(
      id: id ?? this.id,
      code: code ?? this.code,
      poId: poId ?? this.poId,
      poCode: poCode ?? this.poCode,
      poSupplier: poSupplier ?? this.poSupplier,
      totalPoAmount: totalPoAmount ?? this.totalPoAmount,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      canEdit: canEdit ?? this.canEdit,
      canSubmit: canSubmit ?? this.canSubmit,
      approvals: approvals ?? this.approvals,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        poId,
        poCode,
        poSupplier,
        totalPoAmount,
        requestedAmount,
        remainingAmount,
        taxAmount,
        paymentTerm,
        bankName,
        bankAccountNumber,
        bankAccountName,
        paymentMethod,
        notes,
        status,
        canEdit,
        canSubmit,
        approvals,
        createdAt,
      ];
}

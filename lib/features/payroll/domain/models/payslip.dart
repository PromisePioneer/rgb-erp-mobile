import 'package:equatable/equatable.dart';

/// Payslip line item (earnings or deductions)
class PayslipLine extends Equatable {
  final String name;
  final double amount;

  const PayslipLine({
    required this.name,
    required this.amount,
  });

  factory PayslipLine.fromJson(Map<String, dynamic> json) {
    return PayslipLine(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  @override
  List<Object?> get props => [name, amount];
}

/// Payslip model representing a payroll slip
class Payslip extends Equatable {
  final String id;
  final int month; // 0-indexed (0 = Januari, 11 = Desember)
  final int year;
  final String status; // "Paid" or "Draft"
  final List<PayslipLine> earnings;
  final List<PayslipLine> deductions;

  const Payslip({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    required this.earnings,
    required this.deductions,
  });

  /// Get month name in Bahasa Indonesia
  String get monthName {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  /// Format period as "Bulan Tahun"
  String get period => '$monthName $year';

  /// Total earnings (sum of all earning items)
  double get totalEarnings {
    return earnings.fold(0, (sum, item) => sum + item.amount);
  }

  /// Total deductions (sum of all deduction items)
  double get totalDeductions {
    return deductions.fold(0, (sum, item) => sum + item.amount);
  }

  /// Net salary (earnings - deductions)
  double get net => totalEarnings - totalDeductions;

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      status: json['status'] as String,
      earnings: (json['earnings'] as List<dynamic>)
          .map((e) => PayslipLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      deductions: (json['deductions'] as List<dynamic>)
          .map((e) => PayslipLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'status': status,
      'earnings': earnings.map((e) => e.toJson()).toList(),
      'deductions': deductions.map((d) => d.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, month, year, status, earnings, deductions];
}

import 'package:equatable/equatable.dart';

/// Leave request item model representing a leave request
class LeaveRequestItem extends Equatable {
  final String id;
  final DateTime requestDate;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final String reason;
  final String status;

  const LeaveRequestItem({
    required this.id,
    required this.requestDate,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reason,
    required this.status,
  });

  /// Number of days (inclusive)
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Format date range as "d MMM - d MMM yyyy" e.g. "25 Agt - 27 Agt 2026"
  String get dateRange {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final startDay = startDate.day;
    final endDay = endDate.day;
    final startMonth = months[startDate.month - 1];
    final endMonth = months[endDate.month - 1];
    final year = endDate.year;

    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '$startDay $startMonth - $endDay $endMonth $year';
    } else if (startDate.year == endDate.year) {
      return '$startDay $startMonth - $endDay $endMonth $year';
    } else {
      return '$startDay $startMonth ${startDate.year} - $endDay $endMonth $year';
    }
  }

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) {
    return LeaveRequestItem(
      id: json['id'].toString(),
      requestDate: DateTime.parse(json['requestDate'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: json['type'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestDate': requestDate.toIso8601String().split('T').first,
      'startDate': startDate.toIso8601String().split('T').first,
      'endDate': endDate.toIso8601String().split('T').first,
      'type': type,
      'reason': reason,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [id, requestDate, startDate, endDate, type, reason, status];
}

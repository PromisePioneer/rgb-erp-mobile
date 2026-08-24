import 'package:equatable/equatable.dart';

/// Parsing helper
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String && value.isNotEmpty) return int.tryParse(value) ?? 0;
  return 0;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value);
  return null;
}

String _parseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

/// A single field report
class Report extends Equatable {
  final String id;
  final String date;
  final String time;
  final String location;
  final String description;
  final String? image;
  final int? employeeId;
  final String? employeeName;

  const Report({
    required this.id,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    this.image,
    this.employeeId,
    this.employeeName,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: _parseString(json['id']),
      date: _parseString(json['date']),
      time: _parseString(json['time']),
      location: _parseString(json['location']),
      description: _parseString(json['description']),
      image: json['image']?.toString(),
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, date, time, location, description, image, employeeId, employeeName];
}

/// A group of reports for one area/site
class ReportArea extends Equatable {
  final String areaName;
  final int count;
  final List<Report> reports;

  const ReportArea({
    required this.areaName,
    required this.count,
    required this.reports,
  });

  factory ReportArea.fromJson(Map<String, dynamic> json) {
    final reportsList = (json['reports'] as List<dynamic>?)
        ?.map((r) => Report.fromJson(r as Map<String, dynamic>))
        .toList() ?? [];

    return ReportArea(
      areaName: _parseString(json['area_name']),
      count: _parseInt(json['count']),
      reports: reportsList,
    );
  }

  @override
  List<Object?> get props => [areaName, count, reports];
}

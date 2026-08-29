import 'package:equatable/equatable.dart';

/// Schedule item model representing a work schedule entry
class ScheduleItem extends Equatable {
  final String id;
  final DateTime date;
  final String title;
  final String areaName;
  final String? clientName;
  final String? time;
  final String location;

  const ScheduleItem({
    required this.id,
    required this.date,
    required this.title,
    required this.areaName,
    this.clientName,
    this.time,
    required this.location,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      areaName: json['description'] as String? ?? '-',
      clientName: json['client_name'] as String?,
      time: json['time'] as String?,
      location: json['location'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T').first,
      'title': title,
      'description': areaName,
      'client_name': clientName,
      'time': time,
      'location': location,
    };
  }

  @override
  List<Object?> get props => [id, date, title, areaName, clientName, time, location];
}

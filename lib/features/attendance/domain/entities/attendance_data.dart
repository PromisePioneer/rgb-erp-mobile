import 'package:equatable/equatable.dart';
import 'attendance_record.dart';

// Helper function to safely convert to double
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// Helper function to safely convert to int
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Today's attendance data from GET /attendance/today
class AttendanceData extends Equatable {
  final List<AttendanceRecord> records;
  final String nextAction; // 'check_in' | 'check_out' | 'done'
  final bool hasSchedule;
  final bool canAttend;
  final String? message;
  final ProjectLocation? project;
  final ClientLocation? client;
  final ShiftInfo? shift;

  const AttendanceData({
    required this.records,
    required this.nextAction,
    required this.hasSchedule,
    required this.canAttend,
    this.message,
    this.project,
    this.client,
    this.shift,
  });

  bool get hasCheckedIn => records.any((r) => r.isCheckIn);
  bool get hasCheckedOut => records.any((r) => r.isCheckOut);
  DateTime? get checkInTime =>
      records.where((r) => r.isCheckIn).firstOrNull?.recordedAt;
  DateTime? get checkOutTime =>
      records.where((r) => r.isCheckOut).firstOrNull?.recordedAt;

  /// Check if user is about to check out early (approaching end time but hasn't passed)
  bool get willCheckOutEarly {
    // Only applies when next action is check_out
    if (nextAction != 'check_out') return false;
    // Check if shift timing info indicates approaching end
    if (shift?.endApproaching == true) return true;
    return false;
  }

  /// Get the remaining minutes until shift end
  int get minutesToShiftEnd => shift?.minutesToEnd ?? 0;

  String get statusText {
    if (!hasSchedule) return 'Tidak ada jadwal';
    if (!hasCheckedIn) return 'Belum Absen';
    if (hasCheckedIn && !hasCheckedOut) return 'Sudah Absen Masuk';
    return 'Selesai';
  }

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    final recordsList = (json['records'] as List?) ?? [];
    return AttendanceData(
      records: recordsList
          .map((r) => AttendanceRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      nextAction: json['next_action']?.toString() ?? 'check_in',
      hasSchedule: json['has_schedule'] as bool? ?? false,
      canAttend: json['can_attend'] as bool? ?? json['has_schedule'] as bool? ?? false,
      message: json['message'] as String?,
      project: json['project'] != null
          ? ProjectLocation.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? ClientLocation.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      shift: json['shift'] != null
          ? ShiftInfo.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        records,
        nextAction,
        hasSchedule,
        canAttend,
        message,
        project,
        client,
        shift,
      ];
}

/// Project location with coordinates
class ProjectLocation extends Equatable {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? address;

  const ProjectLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
  });

  factory ProjectLocation.fromJson(Map<String, dynamic> json) {
    // Handle id as both int and String
    final idValue = json['id'];
    final id = idValue is int ? idValue.toString() : idValue.toString();

    return ProjectLocation(
      id: id,
      name: json['name'] as String? ?? '',
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      address: json['address'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, lat, lng, address];
}

/// Client location with radius
class ClientLocation extends Equatable {
  final String name;
  final double lat;
  final double lng;
  final int radiusMeters;

  const ClientLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  factory ClientLocation.fromJson(Map<String, dynamic> json) {
    return ClientLocation(
      name: json['name'] as String? ?? '',
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      radiusMeters: _toInt(json['radius']),
    );
  }

  @override
  List<Object?> get props => [name, lat, lng, radiusMeters];
}

/// Shift information
class ShiftInfo extends Equatable {
  final String name;
  final String startTime;
  final String endTime;
  final String? endFormatted;
  final bool endPassed;
  final bool endApproaching;
  final int minutesToEnd;

  const ShiftInfo({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.endFormatted,
    this.endPassed = false,
    this.endApproaching = false,
    this.minutesToEnd = 0,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      name: json['name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      endFormatted: json['end_formatted'] as String?,
      endPassed: json['end_passed'] as bool? ?? false,
      endApproaching: json['end_approaching'] as bool? ?? false,
      minutesToEnd: _toInt(json['minutes_to_end']),
    );
  }

  /// Check if current time is before shift end (early leave condition)
  bool get isEarlyLeave => !endPassed && endApproaching;

  /// Get end time as DateTime for comparison
  DateTime? get endDateTime {
    if (endFormatted == null) return null;
    try {
      final now = DateTime.now();
      final parts = endFormatted!.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        name,
        startTime,
        endTime,
        endFormatted,
        endPassed,
        endApproaching,
        minutesToEnd,
      ];
}

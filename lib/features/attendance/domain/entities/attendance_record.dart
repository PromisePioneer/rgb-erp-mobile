import 'package:equatable/equatable.dart';

/// Parse server datetime string (handles both with and without Z suffix)
DateTime _parseServerDateTime(String value) {
  // If already has Z suffix, parse directly
  if (value.endsWith('Z')) {
    return DateTime.parse(value);
  }
  // Otherwise add Z to indicate UTC
  return DateTime.parse(value + 'Z');
}

/// Attendance type enum - matches backend 'check_in' | 'check_out'
enum AttendanceType {
  checkIn('check_in'),
  checkOut('check_out');

  final String value;
  const AttendanceType(this.value);

  String get displayName {
    switch (this) {
      case AttendanceType.checkIn:
        return 'Absen Masuk';
      case AttendanceType.checkOut:
        return 'Absen Pulang';
    }
  }

  static AttendanceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'check_in':
        return AttendanceType.checkIn;
      case 'check_out':
        return AttendanceType.checkOut;
      default:
        return AttendanceType.checkIn;
    }
  }
}

/// Attendance record from GET /attendance/today
class AttendanceRecord extends Equatable {
  final int id;
  final String type;
  final DateTime? recordedAt;
  final String? queueStatus;
  final double? lat;
  final double? lng;
  final String? notes;
  final String? distanceMeters;
  final bool? livenessPassed;
  final double? faceMatchScore;

  const AttendanceRecord({
    required this.id,
    required this.type,
    this.recordedAt,
    this.queueStatus,
    this.lat,
    this.lng,
    this.notes,
    this.distanceMeters,
    this.livenessPassed,
    this.faceMatchScore,
  });

  AttendanceType get attendanceType => AttendanceType.fromString(type);
  bool get isCheckIn => attendanceType == AttendanceType.checkIn;
  bool get isCheckOut => attendanceType == AttendanceType.checkOut;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Handle type as both String and int
    String typeValue;
    final typeRaw = json['type'];
    if (typeRaw is int) {
      typeValue = typeRaw == 1 ? 'check_in' : 'check_out';
    } else {
      typeValue = typeRaw?.toString() ?? 'check_in';
    }

    // Handle lat/lng - can be String or num
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Handle bool-like values
    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      return null;
    }

    return AttendanceRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: typeValue,
      recordedAt: json['recorded_at'] != null
          ? _parseServerDateTime(json['recorded_at'].toString())
          : null,
      queueStatus: json['queue_status']?.toString(),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      notes: json['notes']?.toString(),
      distanceMeters: json['distance_meters']?.toString(),
      livenessPassed: parseBool(json['liveness_passed']),
      faceMatchScore: parseDouble(json['face_match_score']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        recordedAt,
        queueStatus,
        lat,
        lng,
        notes,
        distanceMeters,
        livenessPassed,
        faceMatchScore,
      ];
}

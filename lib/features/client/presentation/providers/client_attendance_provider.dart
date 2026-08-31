import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// Attendance data model
class AttendanceRecord {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? areaName;
  final String type;
  final String? capturedAt;
  final String? photoUrl;
  final double? lat;
  final double? lng;
  final String? shiftName;
  final String? shiftStart;
  final String? shiftEnd;
  final CheckInOutData? checkIn;
  final CheckInOutData? checkOut;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.areaName,
    required this.type,
    this.capturedAt,
    this.photoUrl,
    this.lat,
    this.lng,
    this.shiftName,
    this.shiftStart,
    this.shiftEnd,
    this.checkIn,
    this.checkOut,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      areaName: json['area_name'],
      type: json['type'] ?? 'check_in',
      capturedAt: json['captured_at'],
      photoUrl: json['photo_url'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      shiftName: json['shift_name'],
      shiftStart: json['shift_start'],
      shiftEnd: json['shift_end'],
      checkIn: json['check_in'] != null
          ? CheckInOutData.fromJson(json['check_in'])
          : null,
      checkOut: json['check_out'] != null
          ? CheckInOutData.fromJson(json['check_out'])
          : null,
    );
  }

  // For history records (flat structure)
  factory AttendanceRecord.fromHistoryJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      areaName: json['area_name'],
      type: json['type'] ?? 'check_in',
      capturedAt: json['captured_at'],
      shiftName: json['shift_name'],
    );
  }
}

class CheckInOutData {
  final String time;
  final String? photoUrl;
  final double? lat;
  final double? lng;

  CheckInOutData({
    required this.time,
    this.photoUrl,
    this.lat,
    this.lng,
  });

  factory CheckInOutData.fromJson(Map<String, dynamic> json) {
    return CheckInOutData(
      time: json['time'] ?? '',
      photoUrl: json['photo_url'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
    );
  }
}

/// State for client attendance
class ClientAttendanceState {
  final List<AttendanceRecord> attendanceData;
  final bool isLoading;
  final String? error;
  final String? date;

  const ClientAttendanceState({
    this.attendanceData = const [],
    this.isLoading = false,
    this.error,
    this.date,
  });

  ClientAttendanceState copyWith({
    List<AttendanceRecord>? attendanceData,
    bool? isLoading,
    String? error,
    String? date,
    bool clearError = false,
  }) {
    return ClientAttendanceState(
      attendanceData: attendanceData ?? this.attendanceData,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      date: date ?? this.date,
    );
  }
}

/// Notifier for client attendance
class ClientAttendanceNotifier extends ChangeNotifier {
  final ClientApi _api;

  ClientAttendanceNotifier(this._api);

  ClientAttendanceState _state = const ClientAttendanceState();
  ClientAttendanceState get state => _state;

  /// Fetch today's attendance
  Future<void> fetchTodayAttendance() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final response = await _api.getTodayAttendance();
      final data = (response['data'] as List? ?? [])
          .map((e) => AttendanceRecord.fromJson(e))
          .toList();

      _state = ClientAttendanceState(
        attendanceData: data,
        isLoading: false,
        date: response['date'],
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Fetch attendance with date filter
  Future<void> fetchAttendance({
    String? fromDate,
    String? toDate,
    int? employeeId,
  }) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final response = await _api.getAttendanceHistory(
        fromDate: fromDate,
        toDate: toDate,
        employeeId: employeeId,
      );
      final data = (response['data'] as List? ?? [])
          .map((e) => AttendanceRecord.fromHistoryJson(e))
          .toList();

      _state = ClientAttendanceState(
        attendanceData: data,
        isLoading: false,
        date: fromDate,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Refresh
  Future<void> refresh() async {
    await fetchAttendance();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }
}

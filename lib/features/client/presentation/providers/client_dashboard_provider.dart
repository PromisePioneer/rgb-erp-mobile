import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../core/di/injection.dart';

/// Dashboard data models
class ClientDashboardData {
  final int totalEmployees;
  final int totalAreas;
  final AttendanceSummary attendanceToday;
  final TaskSummary tasksSummary;
  final PatrolSummary patrolSummary;
  final int fieldReportsToday;

  const ClientDashboardData({
    required this.totalEmployees,
    required this.totalAreas,
    required this.attendanceToday,
    required this.tasksSummary,
    required this.patrolSummary,
    required this.fieldReportsToday,
  });

  factory ClientDashboardData.fromJson(Map<String, dynamic> json) {
    return ClientDashboardData(
      totalEmployees: json['total_employees'] ?? 0,
      totalAreas: json['total_areas'] ?? 0,
      attendanceToday: AttendanceSummary.fromJson(json['attendance_today'] ?? {}),
      tasksSummary: TaskSummary.fromJson(json['tasks_summary'] ?? {}),
      patrolSummary: PatrolSummary.fromJson(json['patrol_summary'] ?? {}),
      fieldReportsToday: json['field_reports_today'] ?? 0,
    );
  }
}

class AttendanceSummary {
  final int total;
  final int checkedIn;
  final int checkedOut;
  final int pending;

  const AttendanceSummary({
    required this.total,
    required this.checkedIn,
    required this.checkedOut,
    required this.pending,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: json['total'] ?? 0,
      checkedIn: json['checked_in'] ?? 0,
      checkedOut: json['checked_out'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}

class TaskSummary {
  final int total;
  final int completed;
  final int pending;

  const TaskSummary({
    required this.total,
    required this.completed,
    required this.pending,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}

class PatrolSummary {
  final int total;
  final int completed;
  final int pending;

  const PatrolSummary({
    required this.total,
    required this.completed,
    required this.pending,
  });

  factory PatrolSummary.fromJson(Map<String, dynamic> json) {
    return PatrolSummary(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}

/// State for client dashboard
class ClientDashboardState {
  final ClientDashboardData? data;
  final bool isLoading;
  final String? error;

  const ClientDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  ClientDashboardState copyWith({
    ClientDashboardData? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClientDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for client dashboard
class ClientDashboardNotifier extends ChangeNotifier {
  final ClientApi _api;

  ClientDashboardNotifier(this._api);

  ClientDashboardState _state = const ClientDashboardState();
  ClientDashboardState get state => _state;

  /// Fetch dashboard data
  Future<void> fetchDashboard() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final response = await _api.getDashboard();
      final data = ClientDashboardData.fromJson(response);
      _state = ClientDashboardState(data: data, isLoading: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  // ====================
  // Employee List
  // ====================

  List<ClientEmployee> _employees = [];
  bool _isLoadingEmployees = false;
  String? _employeesError;

  List<ClientEmployee> get employees => _employees;
  bool get isLoadingEmployees => _isLoadingEmployees;
  String? get employeesError => _employeesError;

  Future<void> fetchEmployees() async {
    _isLoadingEmployees = true;
    _employeesError = null;
    notifyListeners();

    try {
      final response = await _api.getEmployees();
      _employees = (response['data'] as List? ?? [])
          .map((e) => ClientEmployee.fromJson(e))
          .toList();
      _isLoadingEmployees = false;
      notifyListeners();
    } catch (e) {
      _employeesError = e.toString();
      _isLoadingEmployees = false;
      notifyListeners();
    }
  }

  // ====================
  // Area List
  // ====================

  List<ClientArea> _areas = [];
  bool _isLoadingAreas = false;
  String? _areasError;

  List<ClientArea> get areas => _areas;
  bool get isLoadingAreas => _isLoadingAreas;
  String? get areasError => _areasError;

  Future<void> fetchAreas() async {
    _isLoadingAreas = true;
    _areasError = null;
    notifyListeners();

    try {
      final response = await _api.getAreas();
      _areas = (response['data'] as List? ?? [])
          .map((e) => ClientArea.fromJson(e))
          .toList();
      _isLoadingAreas = false;
      notifyListeners();
    } catch (e) {
      _areasError = e.toString();
      _isLoadingAreas = false;
      notifyListeners();
    }
  }
}

/// Model for client employee
class ClientEmployee {
  final int id;
  final String code;
  final String name;
  final String? photoUrl;
  final String? position;

  const ClientEmployee({
    required this.id,
    required this.code,
    required this.name,
    this.photoUrl,
    this.position,
  });

  factory ClientEmployee.fromJson(Map<String, dynamic> json) {
    return ClientEmployee(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photo'],
      position: json['position'],
    );
  }
}

/// Model for client area
class ClientArea {
  final int id;
  final String name;
  final double? lat;
  final double? lng;

  const ClientArea({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
  });

  factory ClientArea.fromJson(Map<String, dynamic> json) {
    return ClientArea(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }
}

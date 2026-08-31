import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// Daily Task record model
class DailyTaskRecord {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? itemName;
  final String status;
  final String? statusLabel;
  final String? assignedDate;
  final int? targetMinutes;
  final String? startAt;
  final String? endAt;
  final String? notes;
  final bool hasReview;

  DailyTaskRecord({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.itemName,
    required this.status,
    this.statusLabel,
    this.assignedDate,
    this.targetMinutes,
    this.startAt,
    this.endAt,
    this.notes,
    this.hasReview = false,
  });

  factory DailyTaskRecord.fromJson(Map<String, dynamic> json) {
    return DailyTaskRecord(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      itemName: json['item_name'],
      status: json['status'] ?? 'assigned',
      statusLabel: json['status_label'],
      assignedDate: json['assigned_date'],
      targetMinutes: json['target_minutes'],
      startAt: json['start_at'],
      endAt: json['end_at'],
      notes: json['notes'],
      hasReview: json['has_review'] ?? false,
    );
  }
}

/// Patrol Report record model
class PatrolReportRecord {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? areaName;
  final String? patrolDate;
  final String? status;
  final String? completedAt;
  final String? patrolRoundName;
  final int totalScans;

  PatrolReportRecord({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.areaName,
    this.patrolDate,
    this.status,
    this.completedAt,
    this.patrolRoundName,
    this.totalScans = 0,
  });

  factory PatrolReportRecord.fromJson(Map<String, dynamic> json) {
    return PatrolReportRecord(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      areaName: json['area_name'],
      patrolDate: json['patrol_date'] != null
          ? DateTime.tryParse(json['patrol_date'].toString())?.toIso8601String().substring(0, 10)
          : null,
      status: json['status'],
      completedAt: json['completed_at'],
      patrolRoundName: json['patrol_round_name'],
      totalScans: json['total_scans'] ?? 0,
    );
  }
}

/// Field Report record model
class FieldReportRecord {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? location;
  final String? reportDate;
  final String? note;
  final String? photoUrl;
  final double? lat;
  final double? lng;

  FieldReportRecord({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.location,
    this.reportDate,
    this.note,
    this.photoUrl,
    this.lat,
    this.lng,
  });

  factory FieldReportRecord.fromJson(Map<String, dynamic> json) {
    return FieldReportRecord(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      location: json['location'],
      reportDate: json['report_date'],
      note: json['note'],
      photoUrl: json['photo_url'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
    );
  }
}

/// State for client reports
class ClientReportsState {
  final List<DailyTaskRecord> tasks;
  final List<PatrolReportRecord> patrolReports;
  final List<FieldReportRecord> fieldReports;
  final bool isLoadingTasks;
  final bool isLoadingPatrol;
  final bool isLoadingField;
  final String? tasksError;
  final String? patrolError;
  final String? fieldError;

  const ClientReportsState({
    this.tasks = const [],
    this.patrolReports = const [],
    this.fieldReports = const [],
    this.isLoadingTasks = false,
    this.isLoadingPatrol = false,
    this.isLoadingField = false,
    this.tasksError,
    this.patrolError,
    this.fieldError,
  });

  ClientReportsState copyWith({
    List<DailyTaskRecord>? tasks,
    List<PatrolReportRecord>? patrolReports,
    List<FieldReportRecord>? fieldReports,
    bool? isLoadingTasks,
    bool? isLoadingPatrol,
    bool? isLoadingField,
    String? tasksError,
    String? patrolError,
    String? fieldError,
    bool clearTasksError = false,
    bool clearPatrolError = false,
    bool clearFieldError = false,
  }) {
    return ClientReportsState(
      tasks: tasks ?? this.tasks,
      patrolReports: patrolReports ?? this.patrolReports,
      fieldReports: fieldReports ?? this.fieldReports,
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      isLoadingPatrol: isLoadingPatrol ?? this.isLoadingPatrol,
      isLoadingField: isLoadingField ?? this.isLoadingField,
      tasksError: clearTasksError ? null : (tasksError ?? this.tasksError),
      patrolError: clearPatrolError ? null : (patrolError ?? this.patrolError),
      fieldError: clearFieldError ? null : (fieldError ?? this.fieldError),
    );
  }
}

/// Notifier for client reports
class ClientReportsNotifier extends ChangeNotifier {
  final ClientApi _api;

  ClientReportsNotifier(this._api);

  ClientReportsState _state = const ClientReportsState();
  ClientReportsState get state => _state;

  /// Fetch daily tasks
  Future<void> fetchDailyTasks({String? fromDate, String? toDate}) async {
    _state = _state.copyWith(isLoadingTasks: true, clearTasksError: true);
    notifyListeners();

    try {
      final response = await _api.getDailyTasks(
        fromDate: fromDate,
        toDate: toDate,
      );
      final data = (response['data'] as List? ?? [])
          .map((e) => DailyTaskRecord.fromJson(e))
          .toList();

      _state = _state.copyWith(tasks: data, isLoadingTasks: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingTasks: false,
        tasksError: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Fetch patrol reports
  Future<void> fetchPatrolReports({String? fromDate, String? toDate}) async {
    _state = _state.copyWith(isLoadingPatrol: true, clearPatrolError: true);
    notifyListeners();

    try {
      final response = await _api.getPatrolReports(
        fromDate: fromDate,
        toDate: toDate,
      );
      final data = (response['data'] as List? ?? [])
          .map((e) => PatrolReportRecord.fromJson(e))
          .toList();

      _state = _state.copyWith(patrolReports: data, isLoadingPatrol: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingPatrol: false,
        patrolError: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Fetch field reports
  Future<void> fetchFieldReports({String? fromDate, String? toDate}) async {
    _state = _state.copyWith(isLoadingField: true, clearFieldError: true);
    notifyListeners();

    try {
      final response = await _api.getFieldReports(
        fromDate: fromDate,
        toDate: toDate,
      );
      final data = (response['data'] as List? ?? [])
          .map((e) => FieldReportRecord.fromJson(e))
          .toList();

      _state = _state.copyWith(fieldReports: data, isLoadingField: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingField: false,
        fieldError: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Refresh all
  Future<void> refreshAll({String? fromDate, String? toDate}) async {
    await Future.wait([
      fetchDailyTasks(fromDate: fromDate, toDate: toDate),
      fetchPatrolReports(fromDate: fromDate, toDate: toDate),
      fetchFieldReports(fromDate: fromDate, toDate: toDate),
    ]);
  }
}

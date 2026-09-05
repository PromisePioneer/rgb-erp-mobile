import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';

/// State for schedule dates
class ScheduleDateState {
  final List<ScheduleDate> dates;
  final bool isLoading;
  final String? error;

  const ScheduleDateState({
    this.dates = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleDateState copyWith({
    List<ScheduleDate>? dates,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ScheduleDateState(
      dates: dates ?? this.dates,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Model for schedule date
class ScheduleDate {
  final DateTime date;
  final int count;

  const ScheduleDate({
    required this.date,
    required this.count,
  });

  factory ScheduleDate.fromJson(Map<String, dynamic> json) {
    return ScheduleDate(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}

/// State for employees by date
class EmployeesByDateState {
  final List<ScheduledEmployee> employees;
  final bool isLoading;
  final String? error;

  const EmployeesByDateState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  EmployeesByDateState copyWith({
    List<ScheduledEmployee>? employees,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EmployeesByDateState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Model for scheduled employee
class ScheduledEmployee {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String? role;
  final String shiftName;
  final String shiftStart;
  final String shiftEnd;
  final String areaName;
  final String posName;
  final String status;

  const ScheduledEmployee({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.role,
    required this.shiftName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.areaName,
    required this.posName,
    required this.status,
  });

  factory ScheduledEmployee.fromJson(Map<String, dynamic> json) {
    return ScheduledEmployee(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '-',
      employeeCode: json['employee_code'] ?? '-',
      role: json['role'],
      shiftName: json['shift_name'] ?? '-',
      shiftStart: json['shift_start'] ?? '',
      shiftEnd: json['shift_end'] ?? '',
      areaName: json['area_name'] ?? '-',
      posName: json['pos_name'] ?? '-',
      status: json['status'] ?? 'pending',
    );
  }
}

/// Notifier for client schedules
class ClientScheduleNotifier extends ChangeNotifier {
  final ClientApi _api;

  ClientScheduleNotifier(this._api);

  ScheduleDateState _dateState = const ScheduleDateState();
  ScheduleDateState get dateState => _dateState;

  EmployeesByDateState _employeeState = const EmployeesByDateState();
  EmployeesByDateState get employeeState => _employeeState;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  /// Fetch schedule dates for calendar
  Future<void> fetchScheduleDates({int? year, int? month}) async {
    _dateState = _dateState.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final y = year ?? _selectedYear;
      final m = month ?? _selectedMonth;
      final response = await _api.getScheduleDates(year: y, month: m);
      final dates = (response['data'] as List)
          .map((e) => ScheduleDate.fromJson(e))
          .toList();
      _dateState = ScheduleDateState(dates: dates, isLoading: false);
      notifyListeners();
    } catch (e) {
      _dateState = _dateState.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Fetch employees scheduled on a date
  Future<void> fetchEmployeesByDate(DateTime date) async {
    _selectedDate = date;
    _employeeState = _employeeState.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _api.getScheduleEmployees(date: dateStr);
      final employees = (response['data'] as List)
          .map((e) => ScheduledEmployee.fromJson(e))
          .toList();
      _employeeState = EmployeesByDateState(employees: employees, isLoading: false);
      notifyListeners();
    } catch (e) {
      _employeeState = _employeeState.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Change month and refetch
  void changeMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    fetchScheduleDates(year: year, month: month);
  }

  /// Select date
  void selectDate(DateTime date) {
    fetchEmployeesByDate(date);
  }
}

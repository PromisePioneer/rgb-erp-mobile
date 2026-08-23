import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/schedule_item.dart';
import '../../data/repositories/schedule_repository.dart';

// ====================
// Repository Factory
// ====================

ScheduleRepository createScheduleRepository(Dio dio) {
  return ScheduleRepository(ScheduleApi(dio));
}

// ====================
// State
// ====================

/// Schedule state
class ScheduleState extends ChangeNotifier {
  final List<ScheduleItem> schedules;
  final DateTime selectedDate;
  final bool isLoading;
  final String? error;

  ScheduleState({
    this.schedules = const [],
    DateTime? selectedDate,
    this.isLoading = false,
    this.error,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// Get schedules for the selected date
  List<ScheduleItem> get schedulesForSelectedDate {
    return schedules.where((item) {
      return item.date.year == selectedDate.year &&
          item.date.month == selectedDate.month &&
          item.date.day == selectedDate.day;
    }).toList();
  }

  /// Check if a specific date has schedules
  bool hasScheduleForDate(DateTime date) {
    return schedules.any((item) {
      return item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day;
    });
  }

  ScheduleState copyWith({
    List<ScheduleItem>? schedules,
    DateTime? selectedDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ====================
// Notifier
// ====================

class ScheduleNotifier extends ChangeNotifier {
  final ScheduleRepository _repository;

  ScheduleNotifier(this._repository);

  ScheduleState _state = ScheduleState();
  ScheduleState get state => _state;

  /// Load all schedules
  Future<void> loadSchedules() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final schedules = await _repository.getSchedules();
      _state = _state.copyWith(
        schedules: schedules,
        isLoading: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat jadwal',
      );
      notifyListeners();
    }
  }

  /// Select a date
  void selectDate(DateTime date) {
    _state = _state.copyWith(selectedDate: date);
    notifyListeners();
  }
}

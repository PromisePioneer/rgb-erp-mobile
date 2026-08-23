import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/leave_request_item.dart';
import '../../data/repositories/leave_repository.dart';

// ====================
// Repository Factory
// ====================

LeaveRepository createLeaveRepository(Dio dio) {
  return LeaveRepository(LeaveApi(dio));
}

// ====================
// State
// ====================

/// Leave state
class LeaveState extends ChangeNotifier {
  final List<LeaveRequestItem> leaves;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final String? submitError;

  LeaveState({
    this.leaves = const [],
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.submitError,
  });

  LeaveState copyWith({
    List<LeaveRequestItem>? leaves,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
    String? submitError,
    bool clearError = false,
    bool clearSubmitError = false,
  }) {
    return LeaveState(
      leaves: leaves ?? this.leaves,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

// ====================
// Notifier
// ====================

class LeaveNotifier extends ChangeNotifier {
  final LeaveRepository _repository;

  LeaveNotifier(this._repository);

  LeaveState _state = LeaveState();
  LeaveState get state => _state;

  /// Load all leave requests
  Future<void> loadLeaves() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final leaves = await _repository.getLeaves();
      _state = _state.copyWith(leaves: leaves, isLoading: false);
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: 'Gagal memuat daftar cuti');
      notifyListeners();
    }
  }

  /// Submit a new leave request
  /// Returns true if successful, false on failure
  Future<bool> submitLeave({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    _state = _state.copyWith(isSubmitting: true, clearSubmitError: true);
    notifyListeners();

    try {
      await _repository.submitLeave(
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      _state = _state.copyWith(isSubmitting: false);
      notifyListeners();
      // Reload leaves so new request appears in list
      await loadLeaves();
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(isSubmitting: false, submitError: 'Gagal mengajukan cuti');
      notifyListeners();
      return false;
    }
  }
}

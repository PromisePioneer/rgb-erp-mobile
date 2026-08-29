import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/shift_response_repository.dart';
import '../../domain/models/shift_response.dart';

/// Shift response state
class ShiftResponseState {
  final List<PendingShiftResponse> pendingShifts;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final ShiftRespondResponse? lastResponse;

  ShiftResponseState({
    this.pendingShifts = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.lastResponse,
  });

  ShiftResponseState copyWith({
    List<PendingShiftResponse>? pendingShifts,
    bool? isLoading,
    String? error,
    String? successMessage,
    ShiftRespondResponse? lastResponse,
  }) {
    return ShiftResponseState(
      pendingShifts: pendingShifts ?? this.pendingShifts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      lastResponse: lastResponse ?? this.lastResponse,
    );
  }

  int get pendingCount => pendingShifts.length;
}

/// Shift response notifier
class ShiftResponseNotifier extends ChangeNotifier {
  final ShiftResponseRepository _repository;

  ShiftResponseState _state = ShiftResponseState();
  ShiftResponseState get state => _state;

  ShiftResponseNotifier(this._repository);

  /// Load pending shift responses
  Future<void> loadPendingResponses() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _repository.getPendingResponses();
      _state = _state.copyWith(
        pendingShifts: response.pending,
        isLoading: false,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat jadwal yang perlu konfirmasi',
      );
    }

    notifyListeners();
  }

  /// Accept a shift
  Future<ShiftRespondResponse?> acceptShift(String scheduleId) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _repository.acceptShift(scheduleId);

      if (response.success) {
        _state = _state.copyWith(
          pendingShifts:
              _state.pendingShifts.where((s) => s.id != scheduleId).toList(),
          isLoading: false,
          successMessage: response.message,
          lastResponse: response,
        );
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: response.message,
          lastResponse: response,
        );
      }

      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      return null;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal menerima shift',
      );
      notifyListeners();
      return null;
    }
  }

  /// Reject a shift
  Future<ShiftRespondResponse?> rejectShift(String scheduleId, {String? reason}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _repository.rejectShift(scheduleId, reason: reason);

      if (response.success) {
        _state = _state.copyWith(
          pendingShifts:
              _state.pendingShifts.where((s) => s.id != scheduleId).toList(),
          isLoading: false,
          successMessage: response.message,
          lastResponse: response,
        );
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: response.message,
          lastResponse: response,
        );
      }

      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      return null;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal menolak shift',
      );
      notifyListeners();
      return null;
    }
  }

  /// Clear messages
  void clearMessages() {
    _state = _state.copyWith(successMessage: null, error: null);
    notifyListeners();
  }

  /// Add pending shift (from notification)
  void addPendingShift(PendingShiftResponse shift) {
    if (!_state.pendingShifts.any((s) => s.id == shift.id)) {
      _state = _state.copyWith(
        pendingShifts: [shift, ..._state.pendingShifts],
      );
      notifyListeners();
    }
  }
}

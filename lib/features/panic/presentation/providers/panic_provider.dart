import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/panic_alert_result.dart';
import '../../data/repositories/panic_repository.dart';

// ====================
// Repository Factory
// ====================

PanicRepository createPanicRepository(Dio dio) {
  return PanicRepository(PanicApi(dio));
}

// ====================
// State
// ====================

class PanicState extends ChangeNotifier {
  final bool isSending;
  final String? sendError;
  final PanicAlertResult? lastResult;

  PanicState({
    this.isSending = false,
    this.sendError,
    this.lastResult,
  });

  PanicState copyWith({
    bool? isSending,
    String? sendError,
    PanicAlertResult? lastResult,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PanicState(
      isSending: isSending ?? this.isSending,
      sendError: clearError ? null : (sendError ?? this.sendError),
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
    );
  }
}

// ====================
// Notifier
// ====================

class PanicNotifier extends ChangeNotifier {
  final PanicRepository _repository;

  PanicNotifier(this._repository);

  PanicState _state = PanicState();
  PanicState get state => _state;

  /// Send a panic alert
  /// Returns true if successful, false on failure
  Future<bool> sendPanicAlert({
    required String type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    print('PANIC_PROVIDER: Starting sendPanicAlert - type=$type, lat=$latitude, lng=$longitude');
    _state = _state.copyWith(isSending: true, clearError: true);
    notifyListeners();

    try {
      print('PANIC_PROVIDER: Calling repository...');
      final result = await _repository.sendPanicAlert(
        type: type,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );
      print('PANIC_PROVIDER: Success - result=$result');
      _state = _state.copyWith(isSending: false, lastResult: result);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      print('PANIC_PROVIDER: ApiException - ${e.message}');
      _state = _state.copyWith(isSending: false, sendError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      print('PANIC_PROVIDER: Exception - $e');
      _state = _state.copyWith(isSending: false, sendError: 'Gagal mengirim panic alert: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }
}

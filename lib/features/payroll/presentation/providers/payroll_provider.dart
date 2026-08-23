import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/payslip.dart';
import '../../data/repositories/payroll_repository.dart';

// ====================
// Repository Factory
// ====================

PayrollRepository createPayrollRepository(Dio dio) {
  return PayrollRepository(PayrollApi(dio));
}

// ====================
// State
// ====================

/// Payroll state
class PayrollState extends ChangeNotifier {
  final List<Payslip> payslips;
  final bool isLoading;
  final String? error;

  PayrollState({
    this.payslips = const [],
    this.isLoading = false,
    this.error,
  });

  PayrollState copyWith({
    List<Payslip>? payslips,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PayrollState(
      payslips: payslips ?? this.payslips,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ====================
// Notifier
// ====================

class PayrollNotifier extends ChangeNotifier {
  final PayrollRepository _repository;

  PayrollNotifier(this._repository);

  PayrollState _state = PayrollState();
  PayrollState get state => _state;

  /// Load all payslips
  Future<void> loadPayslips() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final payslips = await _repository.getPayslips();
      _state = _state.copyWith(
        payslips: payslips,
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
        error: 'Gagal memuat data payroll',
      );
      notifyListeners();
    }
  }
}

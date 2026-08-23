import '../../../../core/core.dart';
import '../../domain/models/payslip.dart';

// Re-export PayrollApi from injection for convenience
export '../../../../core/di/injection.dart' show PayrollApi;

/// Repository for payroll data operations
class PayrollRepository {
  final PayrollApi _api;

  PayrollRepository(this._api);

  /// Get all payslips
  Future<List<Payslip>> getPayslips() async {
    try {
      final response = await _api.getPayslips();
      final payslips = response['payslips'] as List<dynamic>? ?? [];
      return payslips
          .map((json) => Payslip.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat data payroll: $e',
        statusCode: 500,
      );
    }
  }
}

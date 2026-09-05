import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../data/repositories/approval_repository.dart';
import '../../domain/models/approval.dart';

ApprovalRepository createApprovalRepository(Dio dio) {
  return ApprovalRepository(ApprovalApi(dio));
}

class ApprovalState extends ChangeNotifier {
  final List<Approval> approvals;
  final bool isLoading;
  final String? error;
  final bool isActing;
  final String? actError;
  final bool actSuccess;

  ApprovalState({
    this.approvals = const [],
    this.isLoading = false,
    this.error,
    this.isActing = false,
    this.actError,
    this.actSuccess = false,
  });

  ApprovalState copyWith({
    List<Approval>? approvals,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isActing,
    String? actError,
    bool clearActError = false,
    bool? actSuccess,
  }) {
    return ApprovalState(
      approvals: approvals ?? this.approvals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isActing: isActing ?? this.isActing,
      actError: clearActError ? null : (actError ?? this.actError),
      actSuccess: actSuccess ?? this.actSuccess,
    );
  }
}

class ApprovalNotifier extends ChangeNotifier {
  final ApprovalRepository _repository;

  ApprovalNotifier(this._repository);

  ApprovalState _state = ApprovalState();
  ApprovalState get state => _state;

  Future<void> loadApprovals() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final approvals = await _repository.getApprovals();
      _state = _state.copyWith(approvals: approvals, isLoading: false);
    } on ApiException catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat persetujuan',
      );
    }
    notifyListeners();
  }

  Future<bool> approve(int approvalId, {String? note}) async {
    _state = _state.copyWith(isActing: true, clearActError: true, actSuccess: false);
    notifyListeners();

    try {
      await _repository.actApproval(approvalId, 'approve', note: note);
      _state = _state.copyWith(isActing: false, actSuccess: true);
      // Reload list
      await loadApprovals();
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isActing: false, actError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isActing: false,
        actError: 'Gagal menyetujui',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> reject(int approvalId, {String? note}) async {
    _state = _state.copyWith(isActing: true, clearActError: true, actSuccess: false);
    notifyListeners();

    try {
      await _repository.actApproval(approvalId, 'reject', note: note);
      _state = _state.copyWith(isActing: false, actSuccess: true);
      // Reload list
      await loadApprovals();
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(isActing: false, actError: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isActing: false,
        actError: 'Gagal menolak',
      );
      notifyListeners();
      return false;
    }
  }

  void clearActState() {
    _state = _state.copyWith(clearActError: true, actSuccess: false);
    notifyListeners();
  }
}

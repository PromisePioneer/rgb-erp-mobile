import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/backup_offer_repository.dart';
import '../../domain/models/backup_offer.dart';

/// Backup offer state
class BackupOfferState {
  final List<BackupOffer> offers;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  BackupOfferState({
    this.offers = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  BackupOfferState copyWith({
    List<BackupOffer>? offers,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return BackupOfferState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  int get pendingCount => offers.where((o) => o.isPending).length;
}

/// Backup offer notifier
class BackupOfferNotifier extends ChangeNotifier {
  final BackupOfferRepository _repository;

  BackupOfferState _state = BackupOfferState();
  BackupOfferState get state => _state;

  BackupOfferNotifier(this._repository);

  /// Load pending backup offers
  Future<void> loadPendingOffers() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _repository.getPendingOffers();
      _state = _state.copyWith(
        offers: response.offers,
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
        error: 'Gagal memuat tawaran backup',
      );
    }

    notifyListeners();
  }

  /// Accept a backup offer
  Future<bool> acceptOffer(String offerId) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _repository.acceptOffer(offerId);

      if (response.success) {
        _state = _state.copyWith(
          offers: _state.offers.where((o) => o.id != offerId).toList(),
          isLoading: false,
          successMessage: response.message,
        );
        notifyListeners();
        return true;
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: response.message,
        );
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal menerima tawaran backup',
      );
      notifyListeners();
      return false;
    }
  }

  /// Reject a backup offer
  Future<bool> rejectOffer(String offerId, {String? reason}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _repository.rejectOffer(offerId, reason: reason);

      _state = _state.copyWith(
        offers: _state.offers.where((o) => o.id != offerId).toList(),
        isLoading: false,
        successMessage: 'Tawaran backup ditolak',
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal menolak tawaran backup',
      );
      notifyListeners();
      return false;
    }
  }

  /// Clear success message
  void clearMessages() {
    _state = _state.copyWith(successMessage: null, error: null);
    notifyListeners();
  }
}

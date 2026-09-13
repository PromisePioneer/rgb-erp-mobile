import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../data/repositories/korwil_visit_repository.dart';
import '../../domain/entities/korwil_visit_entity.dart';

/// State class for Korwil Visit
class KorwilVisitState extends ChangeNotifier {
  List<KorwilVisitEntity> _visits = [];
  List<KorwilVisitEntity> _todayVisits = [];
  KorwilVisitEntity? _selectedVisit;
  List<ClientOption> _clientOptions = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<KorwilVisitEntity> get visits => _visits;
  List<KorwilVisitEntity> get todayVisits => _todayVisits;
  KorwilVisitEntity? get selectedVisit => _selectedVisit;
  List<ClientOption> get clientOptions => _clientOptions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;

  void reset() {
    _visits = [];
    _todayVisits = [];
    _selectedVisit = null;
    _clientOptions = [];
    _isLoading = false;
    _isLoadingMore = false;
    _isSubmitting = false;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Notifier for Korwil Visit operations
class KorwilVisitNotifier extends ChangeNotifier {
  final KorwilVisitRepository _repository;
  final KorwilVisitState _state = KorwilVisitState();

  KorwilVisitNotifier(this._repository) {
    // Forward state changes to notifier listeners
    _state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  KorwilVisitState get state => _state;

  /// Load visits with pagination
  Future<void> loadVisits({bool refresh = false, String? search}) async {
    if (_state.isLoading) return;

    // Only reset if refreshing (not on load more)
    if (refresh) {
      _state._visits = [];
      _state._currentPage = 1;
      _state._hasMore = true;
      _state._error = null;
    }

    _state.setLoading(true);

    try {
      final visits = await _repository.getVisits(page: 1, search: search);
      _state._visits = visits;
      _state._currentPage = 1;
      _state._hasMore = visits.length >= 15;
    } on ApiException catch (e) {
      _state.setError(e.message);
    } catch (e) {
      _state.setError('Gagal memuat data: $e');
    } finally {
      _state.setLoading(false);
    }
  }

  /// Load more visits (pagination)
  Future<void> loadMoreVisits() async {
    if (_state.isLoadingMore || !_state.hasMore) return;

    _state.setLoadingMore(true);
    _state.clearError();

    try {
      final nextPage = _state._currentPage + 1;
      final visits = await _repository.getVisits(page: nextPage);

      if (visits.isEmpty) {
        _state._hasMore = false;
      } else {
        _state._visits = [..._state._visits, ...visits];
        _state._currentPage = nextPage;
        _state._hasMore = visits.length >= 15;
      }
    } on ApiException catch (e) {
      _state.setError(e.message);
    } catch (e) {
      _state.setError('Gagal memuat data: $e');
    } finally {
      _state.setLoadingMore(false);
    }
  }

  /// Load today's visits
  Future<void> loadTodayVisits() async {
    _state.setLoading(true);
    _state.clearError();

    try {
      _state._todayVisits = await _repository.getTodayVisits();
    } on ApiException catch (e) {
      _state.setError(e.message);
    } catch (e) {
      _state.setError('Gagal memuat data: $e');
    } finally {
      _state.setLoading(false);
    }
  }

  /// Load visit detail
  Future<void> loadVisitDetail(int id) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      _state._selectedVisit = await _repository.getVisitDetail(id);
    } on ApiException catch (e) {
      _state.setError(e.message);
    } catch (e) {
      _state.setError('Gagal memuat detail: $e');
    } finally {
      _state.setLoading(false);
    }
  }

  /// Create a new visit
  Future<KorwilVisitEntity?> createVisit({
    required int clientId,
    required DateTime inTime,
    DateTime? outTime,
    required String areaName,
    String? position,
    String? clientNote,
    String? fieldFindings,
    String? fieldAction,
    String? solution,
    double? latitude,
    double? longitude,
    List<String>? photos,
    List<File>? videos,
  }) async {
    _state.setSubmitting(true);
    _state.clearError();

    try {
      final visit = await _repository.createVisit(
        clientId: clientId,
        inTime: inTime,
        outTime: outTime,
        areaName: areaName,
        position: position,
        clientNote: clientNote,
        fieldFindings: fieldFindings,
        fieldAction: fieldAction,
        solution: solution,
        latitude: latitude,
        longitude: longitude,
        photosBase64: photos,
        videos: videos,
      );

      // Add to visits list
      _state._visits = [visit, ..._state._visits];
      _state._selectedVisit = visit;

      return visit;
    } on ApiException catch (e) {
      _state.setError(e.message);
      return null;
    } catch (e) {
      _state.setError('Gagal menyimpan: $e');
      return null;
    } finally {
      _state.setSubmitting(false);
    }
  }

  /// Update an existing visit
  Future<KorwilVisitEntity?> updateVisit({
    required int id,
    int? clientId,
    DateTime? inTime,
    DateTime? outTime,
    String? areaName,
    String? position,
    String? clientNote,
    String? fieldFindings,
    String? fieldAction,
    String? solution,
    double? latitude,
    double? longitude,
    int? status,
    List<String>? photos,
    List<File>? newVideos,
    List<int>? deletePhotoIds,
    List<int>? deleteVideoIds,
  }) async {
    _state.setSubmitting(true);
    _state.clearError();

    try {
      final visit = await _repository.updateVisit(
        id: id,
        clientId: clientId,
        inTime: inTime,
        outTime: outTime,
        areaName: areaName,
        position: position,
        clientNote: clientNote,
        fieldFindings: fieldFindings,
        fieldAction: fieldAction,
        solution: solution,
        latitude: latitude,
        longitude: longitude,
        status: status,
        photos: photos,
        newVideos: newVideos,
        deletePhotoIds: deletePhotoIds,
        deleteVideoIds: deleteVideoIds,
      );

      // Update in visits list
      final index = _state._visits.indexWhere((v) => v.id == id);
      if (index >= 0) {
        _state._visits[index] = visit;
      }
      _state._selectedVisit = visit;

      return visit;
    } on ApiException catch (e) {
      _state.setError(e.message);
      return null;
    } catch (e) {
      _state.setError('Gagal menyimpan: $e');
      return null;
    } finally {
      _state.setSubmitting(false);
    }
  }

  /// Delete a visit
  Future<bool> deleteVisit(int id) async {
    _state.setSubmitting(true);
    _state.clearError();

    try {
      await _repository.deleteVisit(id);

      // Remove from visits list
      _state._visits.removeWhere((v) => v.id == id);
      _state._selectedVisit = null;

      return true;
    } on ApiException catch (e) {
      _state.setError(e.message);
      return false;
    } catch (e) {
      _state.setError('Gagal menghapus: $e');
      return false;
    } finally {
      _state.setSubmitting(false);
    }
  }

  /// Load client options
  Future<void> loadClientOptions({String? search}) async {
    try {
      _state._clientOptions = await _repository.getClientOptions(search: search);
      notifyListeners();
    } on ApiException catch (e) {
      _state.setError(e.message);
    } catch (e) {
      _state.setError('Gagal memuat klien: $e');
    }
  }

  /// Submit a visit
  Future<bool> submitVisit(int id) async {
    _state.setSubmitting(true);
    _state.clearError();

    try {
      final visit = await _repository.submitVisit(id);

      // Update in visits list
      final index = _state._visits.indexWhere((v) => v.id == id);
      if (index >= 0) {
        _state._visits[index] = visit;
      }
      _state._selectedVisit = visit;

      return true;
    } on ApiException catch (e) {
      _state.setError(e.message);
      return false;
    } catch (e) {
      _state.setError('Gagal submit: $e');
      return false;
    } finally {
      _state.setSubmitting(false);
    }
  }
}

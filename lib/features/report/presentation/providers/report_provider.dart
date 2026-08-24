import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';
import '../../data/repositories/report_repository.dart';

// ====================
// Repository Factory
// ====================

ReportRepository createReportRepository(Dio dio) {
  return ReportRepository(ReportApi(dio));
}

// ====================
// State
// ====================

/// Field report form + list state
class ReportState extends ChangeNotifier {
  // Personal reports list
  final List<Report> reports;
  final bool isLoadingReports;
  final String? reportsError;

  // Reports grouped by area
  final List<ReportArea> areas;
  final bool isLoadingAreas;
  final String? areasError;

  // Form state
  final String description;
  final LocationData? location;
  final String? locationError;

  // Time validation
  final bool isTimeValid;

  // Submit
  final bool isSubmitting;
  final String? submitError;

  // Success
  final bool isSuccess;

  ReportState({
    this.reports = const [],
    this.isLoadingReports = false,
    this.reportsError,
    this.areas = const [],
    this.isLoadingAreas = false,
    this.areasError,
    this.description = '',
    this.location,
    this.locationError,
    this.isTimeValid = false,
    this.isSubmitting = false,
    this.submitError,
    this.isSuccess = false,
  });

  bool get canSubmit {
    return description.trim().isNotEmpty &&
        location != null &&
        isTimeValid &&
        !isSubmitting;
  }

  ReportState copyWith({
    List<Report>? reports,
    bool? isLoadingReports,
    String? reportsError,
    List<ReportArea>? areas,
    bool? isLoadingAreas,
    String? areasError,
    String? description,
    LocationData? location,
    String? locationError,
    bool? isTimeValid,
    bool? isSubmitting,
    String? submitError,
    bool? isSuccess,
    bool clearReportsError = false,
    bool clearAreasError = false,
    bool clearLocation = false,
    bool clearTimeError = false,
    bool clearSubmitError = false,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      isLoadingReports: isLoadingReports ?? this.isLoadingReports,
      reportsError: clearReportsError ? null : (reportsError ?? this.reportsError),
      areas: areas ?? this.areas,
      isLoadingAreas: isLoadingAreas ?? this.isLoadingAreas,
      areasError: clearAreasError ? null : (areasError ?? this.areasError),
      description: description ?? this.description,
      location: clearLocation ? null : (location ?? this.location),
      locationError: locationError ?? this.locationError,
      isTimeValid: isTimeValid ?? this.isTimeValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ====================
// Notifier
// ====================

class ReportNotifier extends ChangeNotifier {
  final ReportRepository _repository;
  final LocationService _locationService;

  ReportNotifier(this._repository, this._locationService);

  ReportState _state = ReportState();
  ReportState get state => _state;

  /// Load personal reports
  Future<void> loadReports() async {
    _state = _state.copyWith(isLoadingReports: true, clearReportsError: true);
    notifyListeners();

    try {
      final reports = await _repository.getReports();
      _state = _state.copyWith(
        reports: reports,
        isLoadingReports: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoadingReports: false,
        reportsError: e.message,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingReports: false,
        reportsError: 'Gagal memuat daftar laporan',
      );
      notifyListeners();
    }
  }

  /// Load reports grouped by area
  Future<void> loadReportsByArea() async {
    _state = _state.copyWith(isLoadingAreas: true, clearAreasError: true);
    notifyListeners();

    try {
      final areas = await _repository.getReportsByArea();
      _state = _state.copyWith(
        areas: areas,
        isLoadingAreas: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoadingAreas: false,
        areasError: e.message,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingAreas: false,
        areasError: 'Gagal memuat laporan per area',
      );
      notifyListeners();
    }
  }

  /// Update description
  void updateDescription(String description) {
    _state = _state.copyWith(description: description);
    notifyListeners();
  }

  /// Get current location (called on form init)
  Future<void> getLocation() async {
    _state = _state.copyWith(clearLocation: true);
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      _state = _state.copyWith(location: location);
      notifyListeners();
    } on LocationException catch (e) {
      _state = _state.copyWith(locationError: e.message);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(locationError: 'Gagal mendapatkan lokasi');
      notifyListeners();
    }
  }

  /// Validate device time
  Future<void> validateTime() async {
    _state = _state.copyWith(
      isTimeValid: true,
      clearTimeError: true,
    );
    notifyListeners();
  }

  /// Submit field report
  Future<bool> submit() async {
    if (!_state.canSubmit) return false;

    _state = _state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );
    notifyListeners();

    try {
      final location = _state.location!;

      await _repository.submitReport(
        description: _state.description,
        latitude: location.latitude,
        longitude: location.longitude,
        location: location.coordinatesString,
      );

      _state = _state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: e.message,
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal menyimpan laporan mutasi',
      );
      notifyListeners();
      return false;
    }
  }

  /// Reset form
  void reset() {
    _state = ReportState();
    notifyListeners();
    // Get location and validate time on reset
    getLocation();
    validateTime();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(
      clearSubmitError: true,
      clearReportsError: true,
      clearAreasError: true,
      clearTimeError: true,
    );
    notifyListeners();
  }
}

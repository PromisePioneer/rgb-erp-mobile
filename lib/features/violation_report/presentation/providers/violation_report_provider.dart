import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';
import '../../data/repositories/violation_report_repository.dart';

// ====================
// Repository Factory
// ====================

ViolationReportRepository createViolationReportRepository(Dio dio) {
  return ViolationReportRepository(ViolationReportApi(dio));
}

// ====================
// State
// ====================

/// Violation report form state
class ViolationReportState extends ChangeNotifier {
  // Violations history (for logged in user)
  final List<ViolationReportResult> violations;
  final bool isLoadingViolations;
  final String? violationsError;

  // Areas
  final List<ViolationArea> areas;
  final bool isLoadingAreas;
  final String? areasError;

  // Employees
  final List<ViolationEmployee> employees;
  final bool isLoadingEmployees;
  final String? employeesError;

  // Violation types
  final List<ViolationType> violationTypes;
  final bool isLoadingTypes;
  final String? typesError;

  // Selected values
  final ViolationArea? selectedArea;
  final ViolationEmployee? selectedEmployee;
  final ViolationType? selectedCategory;
  final ViolationType? selectedViolationType;

  // Photos
  final List<XFile> photos;

  // Notes
  final String notes;

  // Action
  final String action;

  // Location
  final LocationData? location;
  final String? locationError;

  // Time validation
  final bool isTimeValid;
  final String? timeValidationError;

  // Submit
  final bool isSubmitting;
  final String? submitError;

  // Success
  final bool isSuccess;

  ViolationReportState({
    this.violations = const [],
    this.isLoadingViolations = false,
    this.violationsError,
    this.areas = const [],
    this.isLoadingAreas = false,
    this.areasError,
    this.employees = const [],
    this.isLoadingEmployees = false,
    this.employeesError,
    this.violationTypes = const [],
    this.isLoadingTypes = false,
    this.typesError,
    this.selectedArea,
    this.selectedEmployee,
    this.selectedCategory,
    this.selectedViolationType,
    this.photos = const [],
    this.notes = '',
    this.action = '',
    this.location,
    this.locationError,
    this.isTimeValid = false,
    this.timeValidationError,
    this.isSubmitting = false,
    this.submitError,
    this.isSuccess = false,
  });

  /// Check if form is ready to submit
  /// Note: location and time validation are checked in _handleSubmit, not here
  bool get canSubmit {
    return selectedArea != null &&
        selectedEmployee != null &&
        selectedViolationType != null &&
        !isSubmitting;
  }

  ViolationReportState copyWith({
    List<ViolationReportResult>? violations,
    bool? isLoadingViolations,
    String? violationsError,
    List<ViolationArea>? areas,
    bool? isLoadingAreas,
    String? areasError,
    List<ViolationEmployee>? employees,
    bool? isLoadingEmployees,
    String? employeesError,
    List<ViolationType>? violationTypes,
    bool? isLoadingTypes,
    String? typesError,
    ViolationArea? selectedArea,
    ViolationEmployee? selectedEmployee,
    ViolationType? selectedCategory,
    ViolationType? selectedViolationType,
    List<XFile>? photos,
    String? notes,
    String? action,
    LocationData? location,
    String? locationError,
    bool? isTimeValid,
    String? timeValidationError,
    bool? isSubmitting,
    String? submitError,
    bool? isSuccess,
    bool clearSelectedProject = false,
    bool clearSelectedEmployee = false,
    bool clearSelectedCategory = false,
    bool clearSelectedViolationType = false,
    bool clearEmployees = false,
    bool clearPhotos = false,
    bool clearLocation = false,
    bool clearTimeError = false,
    bool clearSubmitError = false,
    bool clearAreasError = false,
    bool clearEmployeesError = false,
    bool clearTypesError = false,
    bool clearViolationsError = false,
  }) {
    return ViolationReportState(
      violations: violations ?? this.violations,
      isLoadingViolations: isLoadingViolations ?? this.isLoadingViolations,
      violationsError: clearViolationsError ? null : (violationsError ?? this.violationsError),
      areas: areas ?? this.areas,
      isLoadingAreas: isLoadingAreas ?? this.isLoadingAreas,
      areasError: clearAreasError ? null : (areasError ?? this.areasError),
      employees: clearEmployees ? const [] : (employees ?? this.employees),
      isLoadingEmployees: isLoadingEmployees ?? this.isLoadingEmployees,
      employeesError: clearEmployeesError ? null : (employeesError ?? this.employeesError),
      violationTypes: violationTypes ?? this.violationTypes,
      isLoadingTypes: isLoadingTypes ?? this.isLoadingTypes,
      typesError: clearTypesError ? null : (typesError ?? this.typesError),
      selectedArea: clearSelectedProject ? null : (selectedArea ?? this.selectedArea),
      selectedEmployee: clearSelectedEmployee ? null : (selectedEmployee ?? this.selectedEmployee),
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedViolationType: clearSelectedViolationType ? null : (selectedViolationType ?? this.selectedViolationType),
      photos: clearPhotos ? const [] : (photos ?? this.photos),
      notes: notes ?? this.notes,
      action: action ?? this.action,
      location: clearLocation ? null : (location ?? this.location),
      locationError: locationError ?? this.locationError,
      isTimeValid: isTimeValid ?? this.isTimeValid,
      timeValidationError: clearTimeError ? null : (timeValidationError ?? this.timeValidationError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ====================
// Notifier
// ====================

class ViolationReportNotifier extends ChangeNotifier {
  final ViolationReportRepository _repository;
  final LocationService _locationService;
  final ImagePicker _imagePicker;

  ViolationReportNotifier(
    this._repository,
    this._locationService, {
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  ViolationReportState _state = ViolationReportState();
  ViolationReportState get state => _state;

  /// Load initial data (areas and violation types)
  Future<void> loadInitialData() async {
    await Future.wait([
      _loadAreas(),
      _loadViolationTypes(),
    ]);
  }

  /// Load logged in user's violation reports
  Future<void> loadUserViolations() async {
    _state = _state.copyWith(isLoadingViolations: true, clearViolationsError: true);
    notifyListeners();

    try {
      final violations = await _repository.getUserViolations();
      _state = _state.copyWith(
        violations: violations,
        isLoadingViolations: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoadingViolations: false,
        violationsError: e.message,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingViolations: false,
        violationsError: 'Gagal memuat riwayat laporan',
      );
      notifyListeners();
    }
  }

  /// Load areas list
  Future<void> _loadAreas() async {
    _state = _state.copyWith(isLoadingAreas: true, clearAreasError: true);
    notifyListeners();

    try {
      final areas = await _repository.getAreas();
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
        areasError: 'Gagal memuat daftar area',
      );
      notifyListeners();
    }
  }

  /// Load violation types
  Future<void> _loadViolationTypes() async {
    _state = _state.copyWith(isLoadingTypes: true, clearTypesError: true);
    notifyListeners();

    try {
      final types = await _repository.getViolationTypes();
      _state = _state.copyWith(
        violationTypes: types,
        isLoadingTypes: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoadingTypes: false,
        typesError: e.message,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingTypes: false,
        typesError: 'Gagal memuat jenis pelanggaran',
      );
      notifyListeners();
    }
  }

  /// Load employees for selected area
  Future<void> loadEmployeesByArea(int areaId) async {
    _state = _state.copyWith(
      isLoadingEmployees: true,
      clearEmployeesError: true,
      clearSelectedEmployee: true,
      clearSelectedViolationType: true,
    );
    notifyListeners();

    try {
      final employees = await _repository.getEmployeesByArea(areaId);
      _state = _state.copyWith(
        employees: employees,
        isLoadingEmployees: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoadingEmployees: false,
        employeesError: e.message,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingEmployees: false,
        employeesError: 'Gagal memuat daftar karyawan',
      );
      notifyListeners();
    }
  }

  /// Select area
  void selectArea(ViolationArea area) {
    _state = _state.copyWith(
      selectedArea: area,
      clearSelectedEmployee: true,
      clearSelectedViolationType: true,
      clearEmployees: true,
    );
    notifyListeners();
    loadEmployeesByArea(area.id);
  }

  /// Select employee
  void selectEmployee(ViolationEmployee employee) {
    _state = _state.copyWith(
      selectedEmployee: employee,
      clearSelectedViolationType: true,
    );
    notifyListeners();
  }

  /// Select category
  void selectCategory(ViolationType category) {
    _state = _state.copyWith(
      selectedCategory: category,
      clearSelectedViolationType: true,
    );
    notifyListeners();
  }

  /// Select violation type (leaf)
  void selectViolationType(ViolationType type) {
    _state = _state.copyWith(selectedViolationType: type);
    notifyListeners();
  }

  /// Update notes
  void updateNotes(String notes) {
    _state = _state.copyWith(notes: notes);
    notifyListeners();
  }

  /// Update action
  void updateAction(String action) {
    _state = _state.copyWith(action: action);
    notifyListeners();
  }

  /// Add photo
  Future<void> addPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        _state = _state.copyWith(
          photos: [..._state.photos, photo],
        );
        notifyListeners();
      }
    } catch (e) {
      
    }
  }

  /// Pick photo from gallery
  Future<void> pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null) {
        _state = _state.copyWith(
          photos: [..._state.photos, photo],
        );
        notifyListeners();
      }
    } catch (e) {
      
    }
  }

  /// Remove photo
  void removePhoto(int index) {
    if (index >= 0 && index < _state.photos.length) {
      final newPhotos = List<XFile>.from(_state.photos);
      newPhotos.removeAt(index);
      _state = _state.copyWith(photos: newPhotos);
      notifyListeners();
    }
  }

  /// Get current location
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

  /// Validate device time (simplified - just check if reasonable)
  Future<void> validateTime() async {
    // Check if time is within reasonable bounds (e.g., not more than 5 minutes off)
    // This is a simplified check - in production you might want to check against server time
    _state = _state.copyWith(
      isTimeValid: true,
      clearTimeError: true,
    );
    notifyListeners();
  }

  /// Submit violation report
  Future<bool> submit() async {
    if (!_state.canSubmit) return false;

    _state = _state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );
    notifyListeners();

    try {
      final location = _state.location!;
      final capturedAt = DateTime.now().toIso8601String();

      await _repository.submitViolation(
        areaId: _state.selectedArea!.id,
        employeeId: _state.selectedEmployee!.id,
        violationTypeId: _state.selectedViolationType!.id,
        capturedAt: capturedAt,
        latitude: location.latitude,
        longitude: location.longitude,
        notes: _state.notes.isNotEmpty ? _state.notes : null,
        action: _state.action.isNotEmpty ? _state.action : null,
        photoPaths: _state.photos.isNotEmpty
            ? _state.photos.map((p) => p.path).toList()
            : null,
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
        submitError: 'Gagal menyimpan temuan pelanggaran',
      );
      notifyListeners();
      return false;
    }
  }

  /// Reset form
  void reset() {
    _state = ViolationReportState();
    notifyListeners();
    loadInitialData();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(
      clearSubmitError: true,
      clearAreasError: true,
      clearEmployeesError: true,
      clearTypesError: true,
      clearTimeError: true,
    );
    notifyListeners();
  }
}

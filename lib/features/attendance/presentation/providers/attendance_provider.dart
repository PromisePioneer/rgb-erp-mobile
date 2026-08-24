import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/core.dart';
import '../../domain/domain.dart';
import '../../data/repositories/attendance_repository.dart';

// ====================
// Repository Factory
// ====================

AttendanceRepository createAttendanceRepository(Dio dio) {
  return AttendanceRepository(api: AttendanceApi(dio));
}

// ====================
// State
// ====================

/// Attendance state
class AttendanceState extends ChangeNotifier {
  final AttendanceData? todayData;
  final bool isLoading;
  final String? error;
  final bool isVerifying;
  final bool isRecording;
  final FaceVerifyResult? verifyResult;
  final AttendanceJobStatusResult? jobStatus;
  final String? capturedPhotoPath;

  AttendanceState({
    this.todayData,
    this.isLoading = false,
    this.error,
    this.isVerifying = false,
    this.isRecording = false,
    this.verifyResult,
    this.jobStatus,
    this.capturedPhotoPath,
  });

  bool get hasSchedule => todayData?.hasSchedule ?? false;
  bool get canAttend => todayData?.canAttend ?? false;
  bool get hasCheckedIn => todayData?.hasCheckedIn ?? false;
  bool get hasCheckedOut => todayData?.hasCheckedOut ?? false;
  String get nextAction => todayData?.nextAction ?? 'check_in';
  String get statusText => todayData?.statusText ?? 'Memuat...';

  AttendanceState copyWith({
    AttendanceData? todayData,
    bool? isLoading,
    String? error,
    bool? isVerifying,
    bool? isRecording,
    FaceVerifyResult? verifyResult,
    AttendanceJobStatusResult? jobStatus,
    String? capturedPhotoPath,
    bool clearError = false,
    bool clearVerifyResult = false,
    bool clearJobStatus = false,
    bool clearPhoto = false,
  }) {
    return AttendanceState(
      todayData: todayData ?? this.todayData,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isVerifying: isVerifying ?? this.isVerifying,
      isRecording: isRecording ?? this.isRecording,
      verifyResult: clearVerifyResult ? null : (verifyResult ?? this.verifyResult),
      jobStatus: clearJobStatus ? null : (jobStatus ?? this.jobStatus),
      capturedPhotoPath: clearPhoto ? null : (capturedPhotoPath ?? this.capturedPhotoPath),
    );
  }
}

// ====================
// Notifier
// ====================

class AttendanceNotifier extends ChangeNotifier {
  final AttendanceRepository _repository;
  final LocationService _locationService;
  final ImagePicker _imagePicker = ImagePicker();

  AttendanceNotifier(this._repository, this._locationService) : super();

  AttendanceState _state = AttendanceState();
  AttendanceState get state => _state;

  /// Load today's attendance data
  Future<void> loadTodayAttendance() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      print('ATTENDANCE: Loading today attendance...');
      final data = await _repository.getTodayAttendance();
      print('ATTENDANCE: Success! Records: ${data.records.length}');
      _state = _state.copyWith(
        todayData: data,
        isLoading: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      print('ATTENDANCE: ApiException - ${e.message} (status: ${e.statusCode})');
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
    } catch (e) {
      print('ATTENDANCE: Unknown error - $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data absensi: $e',
      );
      notifyListeners();
    }
  }

  /// Capture photo for attendance
  Future<String?> capturePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (photo != null) {
        _state = _state.copyWith(capturedPhotoPath: photo.path);
        notifyListeners();
        return photo.path;
      }
      return null;
    } catch (e) {
      _state = _state.copyWith(error: 'Gagal mengambil foto');
      notifyListeners();
      return null;
    }
  }

  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } on LocationException catch (e) {
      _state = _state.copyWith(error: e.message);
      notifyListeners();
      return null;
    }
  }

  /// Face verify before attendance
  Future<FaceVerifyResult?> faceVerify({
    required String photoPath,
    required String capturedAt,
    double? lat,
    double? lng,
    String? type,
  }) async {
    _state = _state.copyWith(isVerifying: true, clearError: true);
    notifyListeners();

    try {
      print('ATT_PROVIDER: Starting faceVerify...');
      print('ATT_PROVIDER: Photo path: $photoPath');
      print('ATT_PROVIDER: Location: lat=$lat, lng=$lng');
      print('ATT_PROVIDER: Type: $type');
      print('ATT_PROVIDER: capturedAt: $capturedAt');

      // Convert photo to base64
      final file = File(photoPath);
      final bytes = await file.readAsBytes();
      final base64Photo = base64Encode(bytes);
      print('ATT_PROVIDER: Photo base64 length: ${base64Photo.length}');

      print('ATT_PROVIDER: Calling repository.faceVerify()...');
      final result = await _repository.faceVerify(
        photoBase64: base64Photo,
        capturedAt: capturedAt,
        lat: lat,
        lng: lng,
        type: type,
      );

      print('ATT_PROVIDER: faceVerify result - success: ${result.success}, match: ${result.match}, message: ${result.message}');
      print('ATT_PROVIDER: jobId: ${result.jobId}, score: ${result.score}');

      _state = _state.copyWith(
        isVerifying: false,
        verifyResult: result,
      );
      notifyListeners();

      return result;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isVerifying: false,
        error: e.message,
      );
      notifyListeners();
      return null;
    } catch (e) {
      _state = _state.copyWith(
        isVerifying: false,
        error: 'Verifikasi wajah gagal',
      );
      notifyListeners();
      return null;
    }
  }

  /// Poll job status until completed
  Future<AttendanceJobStatusResult?> pollJobStatus(String jobUuid) async {
    _state = _state.copyWith(isVerifying: true);
    notifyListeners();

    try {
      final status = await _repository.pollJobStatus(jobUuid);

      _state = _state.copyWith(
        isVerifying: false,
        jobStatus: status,
      );
      notifyListeners();

      return status;
    } catch (e) {
      _state = _state.copyWith(
        isVerifying: false,
        error: 'Gagal memeriksa status',
      );
      notifyListeners();
      return null;
    }
  }

  /// Record attendance (after face verify success)
  Future<AttendanceRecord?> recordAttendance({
    required String photoPath,
    required String capturedAt,
    double? lat,
    double? lng,
    String? notes,
    double? livenessScore,
    double? faceMatchScore,
    String? earlyLeaveNotes,
  }) async {
    _state = _state.copyWith(isRecording: true, clearError: true);
    notifyListeners();

    try {
      print('ATT_PROVIDER: Starting recordAttendance...');
      print('ATT_PROVIDER: Photo path: $photoPath');
      print('ATT_PROVIDER: Location: lat=$lat, lng=$lng');
      print('ATT_PROVIDER: hasCheckedIn: ${_state.hasCheckedIn}');
      print('ATT_PROVIDER: earlyLeaveNotes: ${earlyLeaveNotes != null ? "provided" : "null"}');
      print('ATT_PROVIDER: capturedAt: $capturedAt');

      // Convert photo to base64
      final file = File(photoPath);
      final bytes = await file.readAsBytes();
      final base64Photo = base64Encode(bytes);
      print('ATT_PROVIDER: Photo base64 length: ${base64Photo.length}');

      final type = _state.hasCheckedIn
          ? AttendanceType.checkOut
          : AttendanceType.checkIn;
      print('ATT_PROVIDER: Attendance type: ${type.value}');

      print('ATT_PROVIDER: Calling repository.recordAttendance()...');
      final record = await _repository.recordAttendance(
        type: type,
        photoBase64: base64Photo,
        lat: lat,
        lng: lng,
        notes: notes,
        faceMatchScore: faceMatchScore,
        earlyLeaveNotes: earlyLeaveNotes,
        capturedAt: capturedAt,
      );
      print('ATT_PROVIDER: recordAttendance success! ID: ${record.id}');

      // Refresh today's data
      await loadTodayAttendance();

      _state = _state.copyWith(
        isRecording: false,
        clearPhoto: true,
        clearVerifyResult: true,
        clearJobStatus: true,
      );
      notifyListeners();

      return record;
    } on ApiException catch (e) {
      print('ATT_PROVIDER: ApiException - ${e.message}');
      _state = _state.copyWith(
        isRecording: false,
        error: e.message,
      );
      notifyListeners();
      return null;
    } catch (e) {
      print('ATT_PROVIDER: Unknown error - $e');
      _state = _state.copyWith(
        isRecording: false,
        error: 'Gagal mencatat absensi',
      );
      notifyListeners();
      return null;
    }
  }

  /// Full attendance flow: capture -> verify -> poll -> record
  Future<AttendanceRecord?> performAttendance() async {
    // 1. Get location
    final location = await getCurrentLocation();
    if (location == null) {
      return null;
    }

    // 2. Capture photo
    final photoPath = await capturePhoto();
    if (photoPath == null) {
      return null;
    }

    // Generate capturedAt timestamp once for idempotency
    final capturedAt = DateTime.now().toIso8601String();

    // 3. Face verify
    final type = _state.hasCheckedIn ? 'check_out' : 'check_in';
    final verifyResult = await faceVerify(
      photoPath: photoPath,
      capturedAt: capturedAt,
      lat: location.latitude,
      lng: location.longitude,
      type: type,
    );

    if (verifyResult == null) {
      return null;
    }

    if (!verifyResult.match) {
      _state = _state.copyWith(
        error: verifyResult.message,
      );
      notifyListeners();
      return null;
    }

    // 4. If job_id exists, poll for status
    String? jobUuid = verifyResult.jobId;
    if (jobUuid != null) {
      final status = await pollJobStatus(jobUuid);
      if (status == null || status.isFailed) {
        _state = _state.copyWith(
          error: status?.message ?? 'Verifikasi gagal',
        );
        notifyListeners();
        return null;
      }
    }

    // 5. Record attendance (same capturedAt for idempotency)
    return await recordAttendance(
      photoPath: photoPath,
      capturedAt: capturedAt,
      lat: location.latitude,
      lng: location.longitude,
      faceMatchScore: verifyResult.score,
    );
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  /// Clear captured photo
  void clearCapturedPhoto() {
    _state = _state.copyWith(clearPhoto: true);
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _state = AttendanceState();
    notifyListeners();
  }
}

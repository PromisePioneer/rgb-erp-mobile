import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';
import '../../data/repositories/face_enrollment_repository.dart';

// ====================
// Repository Factory
// ====================

FaceEnrollmentRepository createFaceEnrollmentRepository(Dio dio) {
  return FaceEnrollmentRepository(api: FaceApi(dio));
}

// ====================
// State
// ====================

/// Face enrollment state
class FaceEnrollmentState extends ChangeNotifier {
  final FaceEnrollmentStatus? status;
  final FaceEnrollmentDetail? detail;
  final bool isLoading;
  final String? error;
  final bool isCapturing;
  final bool isEnrolling;
  final String? capturedPhotoPath;
  final FaceEnrollmentResult? enrollmentResult;

  FaceEnrollmentState({
    this.status,
    this.detail,
    this.isLoading = false,
    this.error,
    this.isCapturing = false,
    this.isEnrolling = false,
    this.capturedPhotoPath,
    this.enrollmentResult,
  });

  bool get isEnrolled => status?.enrolled ?? false;
  FaceInfo? get faceInfo => status?.face;

  FaceEnrollmentState copyWith({
    FaceEnrollmentStatus? status,
    FaceEnrollmentDetail? detail,
    bool? isLoading,
    String? error,
    bool? isCapturing,
    bool? isEnrolling,
    String? capturedPhotoPath,
    FaceEnrollmentResult? enrollmentResult,
    bool clearError = false,
    bool clearPhoto = false,
    bool clearResult = false,
  }) {
    return FaceEnrollmentState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCapturing: isCapturing ?? this.isCapturing,
      isEnrolling: isEnrolling ?? this.isEnrolling,
      capturedPhotoPath: clearPhoto ? null : (capturedPhotoPath ?? this.capturedPhotoPath),
      enrollmentResult: clearResult ? null : (enrollmentResult ?? this.enrollmentResult),
    );
  }
}

// ====================
// Notifier
// ====================

class FaceEnrollmentNotifier extends ChangeNotifier {
  final FaceEnrollmentRepository _repository;
  final ImagePicker _imagePicker = ImagePicker();

  FaceEnrollmentNotifier(this._repository) : super();

  FaceEnrollmentState _state = FaceEnrollmentState();
  FaceEnrollmentState get state => _state;

  /// Load face enrollment status
  Future<void> loadEnrollmentStatus() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final status = await _repository.getEnrollmentStatus();
      _state = _state.copyWith(
        status: status,
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
        error: 'Gagal memuat status wajah',
      );
      notifyListeners();
    }
  }

  /// Load face enrollment detail with photos
  Future<void> loadEnrollmentDetail() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final detail = await _repository.getEnrollmentDetail();
      _state = _state.copyWith(
        detail: detail,
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
        error: 'Gagal memuat detail wajah',
      );
      notifyListeners();
    }
  }

  /// Capture face photo
  Future<String?> capturePhoto() async {
    _state = _state.copyWith(isCapturing: true, clearError: true);
    notifyListeners();

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (photo != null) {
        _state = _state.copyWith(
          isCapturing: false,
          capturedPhotoPath: photo.path,
        );
      } else {
        _state = _state.copyWith(isCapturing: false);
      }
      notifyListeners();
      return photo?.path;
    } catch (e) {
      _state = _state.copyWith(
        isCapturing: false,
        error: 'Gagal mengambil foto',
      );
      notifyListeners();
      return null;
    }
  }

  /// Enroll face with captured photo
  Future<FaceEnrollmentResult?> enrollFace({String? photoPath}) async {
    final path = photoPath ?? _state.capturedPhotoPath;

    if (path == null) {
      print('FACE_PROVIDER: No photo path provided');
      _state = _state.copyWith(error: 'Ambil foto terlebih dahulu');
      notifyListeners();
      return null;
    }

    print('FACE_PROVIDER: Starting enrollment with path: $path');
    _state = _state.copyWith(isEnrolling: true, clearError: true, clearResult: true);
    notifyListeners();

    try {
      print('FACE_PROVIDER: Calling repository.enrollFace...');
      final result = await _repository.enrollFace([path]);
      print('FACE_PROVIDER: Result - success: ${result.success}, message: ${result.message}');

      _state = _state.copyWith(
        isEnrolling: false,
        enrollmentResult: result,
      );
      notifyListeners();

      // Refresh status
      if (result.success) {
        await loadEnrollmentStatus();
      }

      return result;
    } on ApiException catch (e) {
      print('FACE_PROVIDER: ApiException - ${e.message}, status: ${e.statusCode}');
      _state = _state.copyWith(
        isEnrolling: false,
        error: e.message,
      );
      notifyListeners();
      return null;
    } catch (e) {
      print('FACE_PROVIDER: Exception - $e');
      _state = _state.copyWith(
        isEnrolling: false,
        error: 'Gagal mendaftarkan wajah: $e',
      );
      notifyListeners();
      return null;
    }
  }

  /// Delete face enrollment
  Future<bool> deleteEnrollment() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await _repository.deleteEnrollment();
      await loadEnrollmentStatus();
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
        error: 'Gagal menghapus data wajah',
      );
      notifyListeners();
      return false;
    }
  }

  /// Check liveness
  Future<LivenessResult?> checkLiveness(String photoPath) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final base64 = await _repository.fileToBase64(photoPath);
      final result = await _repository.checkLiveness(base64);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();

      return result;
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
        error: 'Gagal memeriksa liveness',
      );
      notifyListeners();
      return null;
    }
  }

  /// Clear captured photo
  void clearCapturedPhoto() {
    _state = _state.copyWith(clearPhoto: true);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _state = FaceEnrollmentState();
    notifyListeners();
  }
}

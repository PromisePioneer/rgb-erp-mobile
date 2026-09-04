import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// Repository for face enrollment operations
class FaceEnrollmentRepository {
  final FaceApi _api;

  FaceEnrollmentRepository({required this._api});

  /// Get face enrollment status
  Future<FaceEnrollmentStatus> getEnrollmentStatus() async {
    try {
      final response = await _api.getEnrollmentStatus();
      return FaceEnrollmentStatus.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Enroll face with photos (multipart upload)
  Future<FaceEnrollmentResult> enrollFace(List<String> photoPaths) async {
    
    try {
      
      final response = await _api.enrollFace(photoPaths);
      
      return FaceEnrollmentResult.fromJson(response);
    } on DioException catch (e) {
      
      throw ApiException.fromDioException(e);
    } catch (e) {
      
      rethrow;
    }
  }

  /// Get face enrollment detail with photos
  Future<FaceEnrollmentDetail> getEnrollmentDetail() async {
    try {
      final response = await _api.getEnrollmentDetail();
      return FaceEnrollmentDetail.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Delete face enrollment
  Future<void> deleteEnrollment() async {
    try {
      await _api.deleteEnrollment();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Validate face photo
  Future<bool> validatePhoto(String photoPath) async {
    try {
      final response = await _api.validatePhoto(photoPath);
      return response['valid'] == true;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Check liveness with base64 image
  Future<LivenessResult> checkLiveness(String base64Image) async {
    try {
      final response = await _api.checkLiveness(base64Image);
      return LivenessResult.fromJson(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Read file and convert to base64
  Future<String> fileToBase64(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Check if user is enrolled
  Future<bool> isEnrolled() async {
    try {
      final status = await getEnrollmentStatus();
      return status.enrolled;
    } catch (_) {
      return false;
    }
  }
}

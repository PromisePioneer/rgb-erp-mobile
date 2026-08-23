import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_erp_mobile/features/face_enrollment/presentation/providers/face_enrollment_provider.dart';
import 'package:rgb_erp_mobile/features/face_enrollment/domain/domain.dart';

void main() {
  group('FaceEnrollmentState', () {
    test('initial state should have default values', () {
      final state = FaceEnrollmentState();

      expect(state.status, isNull);
      expect(state.detail, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isCapturing, false);
      expect(state.isEnrolling, false);
      expect(state.capturedPhotoPath, isNull);
      expect(state.enrollmentResult, isNull);
    });

    test('copyWith preserves values correctly', () {
      final state = FaceEnrollmentState();
      const status = FaceEnrollmentStatus(enrolled: true);
      final newState = state.copyWith(
        status: status,
        isLoading: true,
      );

      expect(newState.status, status);
      expect(newState.isLoading, true);
    });

    test('copyWith clears error when clearError is true', () {
      final state = FaceEnrollmentState(error: 'test error');
      final cleared = state.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });

    test('copyWith clears photo when clearPhoto is true', () {
      final state = FaceEnrollmentState(capturedPhotoPath: '/path/to/photo.jpg');
      final cleared = state.copyWith(clearPhoto: true);

      expect(cleared.capturedPhotoPath, isNull);
    });

    test('copyWith clears result when clearResult is true', () {
      const result = FaceEnrollmentResult(
        success: true,
        enrolled: true,
        message: 'OK',
        photoCount: 1,
      );
      final state = FaceEnrollmentState(enrollmentResult: result);
      final cleared = state.copyWith(clearResult: true);

      expect(cleared.enrollmentResult, isNull);
    });

    test('isEnrolled returns false when status is null', () {
      final state = FaceEnrollmentState();
      expect(state.isEnrolled, false);
    });

    test('faceInfo returns null when status is null', () {
      final state = FaceEnrollmentState();
      expect(state.faceInfo, isNull);
    });
  });

  group('FaceEnrollmentStatus', () {
    test('fromJson parses enrolled status correctly', () {
      final json = {
        'enrolled': true,
        'face': {
          'id': 1,
          'userId': 123,
          'provider': 'biznet',
          'createdAt': '2024-01-15T08:00:00Z',
          'enrolledAt': '2024-01-15T08:00:00Z',
          'isActive': true,
          'photoCount': 2,
          'embeddingId': 'emb_123',
        },
      };

      final status = FaceEnrollmentStatus.fromJson(json);

      expect(status.enrolled, true);
      expect(status.face, isNotNull);
      expect(status.face?.id, 1);
      expect(status.face?.provider, 'biznet');
      expect(status.face?.photoCount, 2);
    });

    test('fromJson parses not enrolled correctly', () {
      final json = {'enrolled': false};

      final status = FaceEnrollmentStatus.fromJson(json);

      expect(status.enrolled, false);
      expect(status.face, isNull);
    });

    test('notEnrolled factory creates correct state', () {
      final status = FaceEnrollmentStatus.notEnrolled();

      expect(status.enrolled, false);
      expect(status.face, isNull);
    });
  });

  group('FaceEnrollmentResult', () {
    test('fromJson parses correctly', () {
      final json = {
        'success': true,
        'enrolled': true,
        'message': 'Wajah berhasil didaftarkan',
        'photoCount': 1,
        'embeddingId': 'emb_123',
      };

      final result = FaceEnrollmentResult.fromJson(json);

      expect(result.success, true);
      expect(result.enrolled, true);
      expect(result.message, 'Wajah berhasil didaftarkan');
      expect(result.photoCount, 1);
    });
  });

  group('LivenessResult', () {
    test('fromJson parses correctly', () {
      final json = {
        'success': true,
        'is_live': true,
        'freq_ratio': 0.85,
        'texture_score': 0.92,
        'message': 'Live face detected',
      };

      final result = LivenessResult.fromJson(json);

      expect(result.success, true);
      expect(result.isLive, true);
      expect(result.freqRatio, 0.85);
      expect(result.textureScore, 0.92);
    });

    test('fromJson handles false liveness', () {
      final json = {
        'success': true,
        'is_live': false,
        'message': 'Spoof detected',
      };

      final result = LivenessResult.fromJson(json);

      expect(result.success, true);
      expect(result.isLive, false);
    });
  });

  group('FaceInfo', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'userId': 123,
        'provider': 'biznet',
        'createdAt': '2024-01-15T08:00:00Z',
        'enrolledAt': '2024-01-15T08:00:00Z',
        'isActive': true,
        'photoCount': 2,
        'embeddingId': 'emb_123',
      };

      final face = FaceInfo.fromJson(json);

      expect(face.id, 1);
      expect(face.userId, 123);
      expect(face.provider, 'biznet');
      expect(face.isActive, true);
      expect(face.photoCount, 2);
    });
  });

  group('FacePhoto', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'url': 'https://example.com/photo.jpg',
        'quality': 0.85,
        'faceDetected': true,
        'faceCount': 1,
        'capturedAt': '2024-01-15T08:00:00Z',
      };

      final photo = FacePhoto.fromJson(json);

      expect(photo.id, 1);
      expect(photo.url, 'https://example.com/photo.jpg');
      expect(photo.quality, 0.85);
      expect(photo.faceDetected, true);
      expect(photo.faceCount, 1);
    });
  });
}

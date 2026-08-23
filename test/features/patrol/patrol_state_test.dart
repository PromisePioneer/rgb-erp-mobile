import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_86/features/patrol/domain/domain.dart';
import 'package:rgb_86/features/patrol/presentation/providers/patrol_provider.dart';

void main() {
  group('QRScanResult', () {
    test('parses plain code (legacy format)', () {
      final result = QRScanResult.fromQRContent('CP-PROJ-01');

      expect(result.code, 'CP-PROJ-01');
      expect(result.secretKey, isNull);
      expect(result.hasSecretKey, false);
      expect(result.isLegacyQR, true);
    });

    test('parses JSON format with secret_key', () {
      final result = QRScanResult.fromQRContent(
        '{"code": "CP-PROJ-01", "secret_key": "JBSWY3DPEHPK3PXP"}',
      );

      expect(result.code, 'CP-PROJ-01');
      expect(result.secretKey, 'JBSWY3DPEHPK3PXP');
      expect(result.hasSecretKey, true);
      expect(result.isLegacyQR, false);
    });

    test('parses JSON format without secret_key', () {
      final result = QRScanResult.fromQRContent(
        '{"code": "CP-PROJ-02"}',
      );

      expect(result.code, 'CP-PROJ-02');
      expect(result.secretKey, isNull);
      expect(result.hasSecretKey, false);
    });

    test('throws FormatException for empty content', () {
      expect(
        () => QRScanResult.fromQRContent(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('falls back to plain code when JSON is invalid', () {
      final result = QRScanResult.fromQRContent('{invalid json}');

      expect(result.code, '{invalid json}');
      expect(result.secretKey, isNull);
    });

    test('throws FormatException when JSON code is missing', () {
      expect(
        () => QRScanResult.fromQRContent('{"secret_key": "xxx"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when JSON code is empty', () {
      expect(
        () => QRScanResult.fromQRContent('{"code": "", "secret_key": "xxx"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles secret_key with spaces', () {
      final result = QRScanResult.fromQRContent(
        '{"code": "CP-01", "secret_key": "JBSWY3DP EHPK3PXP "}',
      );

      // The actual trimming/normalization happens in the TOTP generator
      expect(result.code, 'CP-01');
      expect(result.hasSecretKey, true);
    });

    test('equals comparison works correctly', () {
      final result1 = QRScanResult(
        code: 'CP-01',
        secretKey: 'SECRET',
      );
      final result2 = QRScanResult(
        code: 'CP-01',
        secretKey: 'SECRET',
      );
      final result3 = QRScanResult(
        code: 'CP-02',
        secretKey: 'SECRET',
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('toString returns readable format', () {
      final result = QRScanResult(
        code: 'CP-01',
        secretKey: 'SECRET',
      );

      expect(
        result.toString(),
        'QRScanResult(code: CP-01, hasSecretKey: true)',
      );
    });
  });

  group('PatrolState', () {
    test('initial state should have default values', () {
      final state = PatrolState();

      expect(state.todayStatus, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isScanning, false);
      expect(state.lastScanResult, isNull);
      expect(state.isCountingDown, false);
      expect(state.countdownSeconds, 0);
      expect(state.showAlarmAlert, false);
      expect(state.alarmMessage, isNull);
    });

    test('hasSchedule returns false when todayStatus is null', () {
      final state = PatrolState();
      expect(state.hasSchedule, false);
    });

    test('nextExpectedSequence returns 1 when todayStatus is null', () {
      final state = PatrolState();
      expect(state.nextExpectedSequence, 1);
    });

    test('totalCheckpoints returns 0 when todayStatus is null', () {
      final state = PatrolState();
      expect(state.totalCheckpoints, 0);
    });

    test('isRoundCompleted returns false when lastScanResult is null', () {
      final state = PatrolState();
      expect(state.isRoundCompleted, false);
    });

    test('copyWith preserves values correctly', () {
      final state = PatrolState();
      final newState = state.copyWith(
        isScanning: true,
        error: 'Test error',
      );

      expect(newState.isScanning, true);
      expect(newState.error, 'Test error');
    });

    test('copyWith clears error when clearError is true', () {
      final state = PatrolState(error: 'test error');
      final cleared = state.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });

    test('copyWith clears lastScanResult when clearLastScanResult is true', () {
      final state = PatrolState(lastScanResult: const PatrolScanResult(success: true));
      final cleared = state.copyWith(clearLastScanResult: true);

      expect(cleared.lastScanResult, isNull);
    });
  });

  group('PatrolScanResult', () {
    test('fromJson parses success response', () {
      final json = {
        'success': true,
        'valid': true,
        'scan_id': 123,
        'checkpoint': {
          'id': 1,
          'name': 'Pos Utama',
          'sequence_order': 1,
        },
        'progress': {
          'current': 1,
          'total': 5,
          'label': 'Checkpoint 1/5',
        },
        'validation': {
          'location_valid': true,
          'location_message': null,
          'distance_meters': 25.5,
        },
        'min_gap_seconds': 30,
        'round_status': 'in_progress',
        'processing_time_ms': 150,
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.success, true);
      expect(result.valid, true);
      expect(result.scanId, 123);
      expect(result.checkpoint?.name, 'Pos Utama');
      expect(result.progress?.current, 1);
      expect(result.progress?.total, 5);
      expect(result.validation?.locationValid, true);
      expect(result.validation?.distanceMeters, 25.5);
      expect(result.roundStatus, 'in_progress');
      expect(result.processingTimeMs, 150);
    });

    test('fromJson parses error response with INVALID_TOTP', () {
      final json = {
        'success': false,
        'code': 'INVALID_TOTP',
        'message': 'Kode OTP tidak valid atau sudah kadaluarsa.',
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.success, false);
      expect(result.errorCode, 'INVALID_TOTP');
      expect(result.errorMessage, 'Kode OTP tidak valid atau sudah kadaluarsa.');
    });

    test('fromJson parses error response with TIME_DRIFT', () {
      final json = {
        'success': false,
        'code': 'TIME_DRIFT',
        'message': 'Waktu perangkat tidak sinkron.',
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.success, false);
      expect(result.errorCode, 'TIME_DRIFT');
      expect(result.errorMessage, 'Waktu perangkat tidak sinkron.');
    });

    test('fromJson parses error response with MOCK_LOCATION', () {
      final json = {
        'success': false,
        'code': 'MOCK_LOCATION',
        'message': 'GPS palsu terdeteksi.',
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.success, false);
      expect(result.errorCode, 'MOCK_LOCATION');
      expect(result.errorMessage, 'GPS palsu terdeteksi.');
    });

    test('isValidWarning returns true when success but valid is false', () {
      final json = {
        'success': true,
        'valid': false,
        'validation': {
          'location_valid': false,
          'location_message': 'Di luar radius',
        },
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.isValidWarning, true);
    });

    test('isRoundCompleted returns true when roundStatus is completed', () {
      final json = {
        'success': true,
        'valid': true,
        'round_status': 'completed',
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.isRoundCompleted, true);
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'success': true,
        'valid': true,
      };

      final result = PatrolScanResult.fromJson(json);

      expect(result.success, true);
      expect(result.valid, true);
      expect(result.scanId, isNull);
      expect(result.checkpoint, isNull);
      expect(result.progress, isNull);
      expect(result.validation, isNull);
      expect(result.errorCode, isNull);
      expect(result.errorMessage, isNull);
    });
  });
}

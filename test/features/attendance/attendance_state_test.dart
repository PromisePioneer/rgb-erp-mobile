import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_86/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:rgb_86/features/attendance/domain/domain.dart';

void main() {
  group('AttendanceState', () {
    test('initial state should have default values', () {
      final state = AttendanceState();

      expect(state.todayData, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isVerifying, false);
      expect(state.isRecording, false);
      expect(state.verifyResult, isNull);
      expect(state.jobStatus, isNull);
      expect(state.capturedPhotoPath, isNull);
    });

    test('copyWith preserves values correctly', () {
      final state = AttendanceState();
      final newState = state.copyWith(
        isLoading: true,
        error: 'Test error',
      );

      expect(newState.isLoading, true);
      expect(newState.error, 'Test error');
    });

    test('copyWith clears error when clearError is true', () {
      final state = AttendanceState(error: 'test error');
      final cleared = state.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });

    test('copyWith clears photo when clearPhoto is true', () {
      final state = AttendanceState(capturedPhotoPath: '/path/to/photo.jpg');
      final cleared = state.copyWith(clearPhoto: true);

      expect(cleared.capturedPhotoPath, isNull);
    });

    test('copyWith clears verifyResult when clearVerifyResult is true', () {
      const result = FaceVerifyResult(
        success: true,
        match: true,
        message: 'OK',
      );
      final state = AttendanceState(verifyResult: result);
      final cleared = state.copyWith(clearVerifyResult: true);

      expect(cleared.verifyResult, isNull);
    });

    test('hasSchedule returns false when todayData is null', () {
      final state = AttendanceState();
      expect(state.hasSchedule, false);
    });

    test('hasCheckedIn returns false when todayData is null', () {
      final state = AttendanceState();
      expect(state.hasCheckedIn, false);
    });

    test('hasCheckedOut returns false when todayData is null', () {
      final state = AttendanceState();
      expect(state.hasCheckedOut, false);
    });
  });

  group('AttendanceData', () {
    test('fromJson parses correctly', () {
      final json = {
        'records': [
          {
            'id': 1,
            'type': 'check_in',
            'recorded_at': '2024-01-15T08:00:00Z',
          },
        ],
        'next_action': 'check_out',
        'has_schedule': true,
        'can_attend': true,
        'shift': {
          'name': 'Pagi',
          'start_time': '08:00:00',
          'end_time': '16:00:00',
        },
      };

      final data = AttendanceData.fromJson(json);

      expect(data.records.length, 1);
      expect(data.records.first.type, 'check_in');
      expect(data.nextAction, 'check_out');
      expect(data.hasSchedule, true);
      expect(data.canAttend, true);
      expect(data.shift?.name, 'Pagi');
    });

    test('hasCheckedIn returns true when check_in record exists', () {
      final json = {
        'records': [
          {'id': 1, 'type': 'check_in', 'recorded_at': '2024-01-15T08:00:00Z'},
        ],
        'next_action': 'check_out',
        'has_schedule': true,
        'can_attend': true,
      };

      final data = AttendanceData.fromJson(json);
      expect(data.hasCheckedIn, true);
    });

    test('willCheckOutEarly returns true when shift is approaching end', () {
      final json = {
        'records': [
          {'id': 1, 'type': 'check_in', 'recorded_at': '2024-01-15T08:00:00Z'},
        ],
        'next_action': 'check_out',
        'has_schedule': true,
        'can_attend': true,
        'shift': {
          'name': 'Pagi',
          'start_time': '08:00:00',
          'end_time': '17:00:00',
          'end_formatted': '17:00',
          'end_passed': false,
          'end_approaching': true,
          'minutes_to_end': 25,
        },
      };

      final data = AttendanceData.fromJson(json);
      expect(data.willCheckOutEarly, true);
      expect(data.minutesToShiftEnd, 25);
    });

    test('willCheckOutEarly returns false when shift has passed', () {
      final json = {
        'records': [
          {'id': 1, 'type': 'check_in', 'recorded_at': '2024-01-15T08:00:00Z'},
        ],
        'next_action': 'check_out',
        'has_schedule': true,
        'can_attend': true,
        'shift': {
          'name': 'Pagi',
          'start_time': '08:00:00',
          'end_time': '17:00:00',
          'end_formatted': '17:00',
          'end_passed': true,
          'end_approaching': false,
          'minutes_to_end': 0,
        },
      };

      final data = AttendanceData.fromJson(json);
      expect(data.willCheckOutEarly, false);
      expect(data.minutesToShiftEnd, 0);
    });

    test('willCheckOutEarly returns false when next action is check_in', () {
      final json = {
        'records': [],
        'next_action': 'check_in',
        'has_schedule': true,
        'can_attend': true,
        'shift': {
          'name': 'Pagi',
          'start_time': '08:00:00',
          'end_time': '17:00:00',
          'end_formatted': '17:00',
          'end_passed': false,
          'end_approaching': true,
          'minutes_to_end': 25,
        },
      };

      final data = AttendanceData.fromJson(json);
      expect(data.willCheckOutEarly, false);
    });
  });

  group('ShiftInfo', () {
    test('fromJson parses shift timing fields correctly', () {
      final json = {
        'name': 'Pagi',
        'start_time': '08:00:00',
        'end_time': '17:00:00',
        'end_formatted': '17:00',
        'end_passed': false,
        'end_approaching': true,
        'minutes_to_end': 30,
      };

      final shift = ShiftInfo.fromJson(json);

      expect(shift.name, 'Pagi');
      expect(shift.startTime, '08:00:00');
      expect(shift.endTime, '17:00:00');
      expect(shift.endFormatted, '17:00');
      expect(shift.endPassed, false);
      expect(shift.endApproaching, true);
      expect(shift.minutesToEnd, 30);
    });

    test('isEarlyLeave returns true when approaching but not passed', () {
      const shift = ShiftInfo(
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '17:00:00',
        endFormatted: '17:00',
        endPassed: false,
        endApproaching: true,
        minutesToEnd: 25,
      );

      expect(shift.isEarlyLeave, true);
    });

    test('isEarlyLeave returns false when already passed', () {
      const shift = ShiftInfo(
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '17:00:00',
        endFormatted: '17:00',
        endPassed: true,
        endApproaching: false,
        minutesToEnd: 0,
      );

      expect(shift.isEarlyLeave, false);
    });

    test('handles null values gracefully', () {
      final json = {
        'name': 'Pagi',
        'start_time': '08:00:00',
        'end_time': '17:00:00',
      };

      final shift = ShiftInfo.fromJson(json);

      expect(shift.name, 'Pagi');
      expect(shift.endFormatted, isNull);
      expect(shift.endPassed, false);
      expect(shift.endApproaching, false);
      expect(shift.minutesToEnd, 0);
    });
  });

  group('FaceVerifyResult', () {
    test('fromJson parses correctly', () {
      final json = {
        'success': true,
        'match': true,
        'score': 0.95,
        'job_id': 'uuid-123',
        'status': 'queued',
        'message': 'OK',
      };

      final result = FaceVerifyResult.fromJson(json);

      expect(result.success, true);
      expect(result.match, true);
      expect(result.score, 0.95);
      expect(result.jobId, 'uuid-123');
      expect(result.isQueued, true);
    });

    test('isAlreadyProcessed returns true when status is already_processed', () {
      const result = FaceVerifyResult(
        success: true,
        match: true,
        status: 'already_processed',
        message: 'OK',
      );

      expect(result.isAlreadyProcessed, true);
    });
  });

  group('AttendanceJobStatus', () {
    test('fromString returns correct status', () {
      expect(
        AttendanceJobStatus.fromString('completed'),
        AttendanceJobStatus.completed,
      );
      expect(
        AttendanceJobStatus.fromString('failed'),
        AttendanceJobStatus.failed,
      );
      expect(
        AttendanceJobStatus.fromString('processing'),
        AttendanceJobStatus.processing,
      );
      expect(
        AttendanceJobStatus.fromString('unknown'),
        AttendanceJobStatus.processing,
      );
    });
  });
}

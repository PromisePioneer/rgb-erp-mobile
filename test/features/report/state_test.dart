import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_86/core/core.dart';
import 'package:rgb_86/features/report/domain/domain.dart';
import 'package:rgb_86/features/report/presentation/providers/report_provider.dart';

void main() {
  group('ReportState', () {
    test('initial state has empty values', () {
      final state = ReportState();

      expect(state.reports, isEmpty);
      expect(state.isLoadingReports, false);
      expect(state.reportsError, isNull);
      expect(state.areas, isEmpty);
      expect(state.isLoadingAreas, false);
      expect(state.areasError, isNull);
      expect(state.description, '');
      expect(state.location, isNull);
      expect(state.locationError, isNull);
      expect(state.isTimeValid, false);
      expect(state.isSubmitting, false);
      expect(state.submitError, isNull);
      expect(state.isSuccess, false);
      expect(state.canSubmit, false);
    });

    test('canSubmit returns true when all required fields are filled', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final state = ReportState(
        description: 'Test report description',
        location: location,
        isTimeValid: true,
      );

      expect(state.canSubmit, true);
    });

    test('canSubmit returns false when description is empty', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final state = ReportState(
        description: '',
        location: location,
        isTimeValid: true,
      );

      expect(state.canSubmit, false);
    });

    test('canSubmit returns false when description is whitespace only', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final state = ReportState(
        description: '   ',
        location: location,
        isTimeValid: true,
      );

      expect(state.canSubmit, false);
    });

    test('canSubmit returns false when location is missing', () {
      final state = ReportState(
        description: 'Test report',
        isTimeValid: true,
      );

      expect(state.canSubmit, false);
    });

    test('canSubmit returns false when time is not valid', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final state = ReportState(
        description: 'Test report',
        location: location,
        isTimeValid: false,
      );

      expect(state.canSubmit, false);
    });

    test('canSubmit returns false when submitting', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final state = ReportState(
        description: 'Test report',
        location: location,
        isTimeValid: true,
        isSubmitting: true,
      );

      expect(state.canSubmit, false);
    });

    test('copyWith preserves values correctly', () {
      final original = ReportState(
        reports: [
          Report(
            id: '1',
            date: '2024-01-15',
            time: '10:30',
            location: 'Area A',
            description: 'Test report',
          ),
        ],
      );

      final updated = original.copyWith(
        isLoadingReports: true,
      );

      expect(updated.reports.length, 1);
      expect(updated.reports[0].id, '1');
      expect(updated.isLoadingReports, true);
    });

    test('copyWith updates description', () {
      final original = ReportState(description: 'Original');

      final updated = original.copyWith(description: 'Updated');

      expect(updated.description, 'Updated');
      expect(original.description, 'Original'); // Original unchanged
    });

    test('copyWith updates location', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final original = ReportState();
      final updated = original.copyWith(location: location);

      expect(updated.location, isNotNull);
      expect(updated.location?.latitude, -6.1754);
    });

    test('copyWith clears location', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final original = ReportState(location: location);
      final cleared = original.copyWith(clearLocation: true);

      expect(cleared.location, isNull);
    });

    test('copyWith updates areas', () {
      final area = ReportArea(
        areaName: 'Area A',
        count: 5,
        reports: [],
      );

      final original = ReportState();
      final updated = original.copyWith(areas: [area]);

      expect(updated.areas.length, 1);
      expect(updated.areas[0].areaName, 'Area A');
    });

    test('copyWith clears reports error', () {
      final original = ReportState(reportsError: 'Error loading reports');

      final cleared = original.copyWith(clearReportsError: true);

      expect(cleared.reportsError, isNull);
    });

    test('copyWith clears areas error', () {
      final original = ReportState(areasError: 'Error loading areas');

      final cleared = original.copyWith(clearAreasError: true);

      expect(cleared.areasError, isNull);
    });

    test('copyWith clears submit error', () {
      final original = ReportState(submitError: 'Submit error');

      final cleared = original.copyWith(clearSubmitError: true);

      expect(cleared.submitError, isNull);
    });

    test('copyWith clears time error', () {
      final original = ReportState(isTimeValid: false);

      final cleared = original.copyWith(clearTimeError: true);

      expect(cleared.isTimeValid, false);
    });

    test('copyWith updates isLoadingReports', () {
      final original = ReportState(isLoadingReports: false);

      final updated = original.copyWith(isLoadingReports: true);

      expect(updated.isLoadingReports, true);
    });

    test('copyWith updates isLoadingAreas', () {
      final original = ReportState(isLoadingAreas: false);

      final updated = original.copyWith(isLoadingAreas: true);

      expect(updated.isLoadingAreas, true);
    });

    test('copyWith updates isSubmitting', () {
      final original = ReportState(isSubmitting: false);

      final updated = original.copyWith(isSubmitting: true);

      expect(updated.isSubmitting, true);
    });

    test('copyWith updates isSuccess', () {
      final original = ReportState(isSuccess: false);

      final updated = original.copyWith(isSuccess: true);

      expect(updated.isSuccess, true);
    });
  });
}

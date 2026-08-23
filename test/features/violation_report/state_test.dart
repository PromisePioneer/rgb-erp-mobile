import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rgb_86/core/core.dart';
import 'package:rgb_86/features/violation_report/domain/domain.dart';
import 'package:rgb_86/features/violation_report/presentation/providers/violation_report_provider.dart';

void main() {
  group('ViolationReportState', () {
    test('initial state has empty values', () {
      final state = ViolationReportState();

      expect(state.projects, isEmpty);
      expect(state.isLoadingProjects, false);
      expect(state.projectsError, isNull);
      expect(state.employees, isEmpty);
      expect(state.isLoadingEmployees, false);
      expect(state.employeesError, isNull);
      expect(state.violationTypes, isEmpty);
      expect(state.isLoadingTypes, false);
      expect(state.typesError, isNull);
      expect(state.selectedProject, isNull);
      expect(state.selectedEmployee, isNull);
      expect(state.selectedCategory, isNull);
      expect(state.selectedViolationType, isNull);
      expect(state.photos, isEmpty);
      expect(state.notes, isEmpty);
      expect(state.location, isNull);
      expect(state.locationError, isNull);
      expect(state.isTimeValid, false);
      expect(state.timeValidationError, isNull);
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

      final state = ViolationReportState(
        selectedProject: ViolationProject(id: 1, name: 'Project A'),
        selectedEmployee: ViolationEmployee(id: 1, name: 'John', code: 'EMP001'),
        selectedViolationType: ViolationType(id: 5, name: 'Test', severityLevel: 'low'),
        location: location,
        isTimeValid: true,
      );

      expect(state.canSubmit, true);
    });

    test('canSubmit returns false when project is missing', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final state = ViolationReportState(
        selectedEmployee: ViolationEmployee(id: 1, name: 'John', code: 'EMP001'),
        selectedViolationType: ViolationType(id: 5, name: 'Test', severityLevel: 'low'),
        location: location,
        isTimeValid: true,
      );

      expect(state.canSubmit, false);
    });

    test('canSubmit returns false when location is missing', () {
      final state = ViolationReportState(
        selectedProject: ViolationProject(id: 1, name: 'Project A'),
        selectedEmployee: ViolationEmployee(id: 1, name: 'John', code: 'EMP001'),
        selectedViolationType: ViolationType(id: 5, name: 'Test', severityLevel: 'low'),
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

      final state = ViolationReportState(
        selectedProject: ViolationProject(id: 1, name: 'Project A'),
        selectedEmployee: ViolationEmployee(id: 1, name: 'John', code: 'EMP001'),
        selectedViolationType: ViolationType(id: 5, name: 'Test', severityLevel: 'low'),
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

      final state = ViolationReportState(
        selectedProject: ViolationProject(id: 1, name: 'Project A'),
        selectedEmployee: ViolationEmployee(id: 1, name: 'John', code: 'EMP001'),
        selectedViolationType: ViolationType(id: 5, name: 'Test', severityLevel: 'low'),
        location: location,
        isTimeValid: true,
        isSubmitting: true,
      );

      expect(state.canSubmit, false);
    });

    test('copyWith preserves values correctly', () {
      final original = ViolationReportState(
        projects: [ViolationProject(id: 1, name: 'Project A')],
        selectedProject: ViolationProject(id: 1, name: 'Project A'),
      );

      final updated = original.copyWith(
        isLoadingProjects: true,
      );

      expect(updated.projects.length, 1);
      expect(updated.projects[0].id, 1);
      expect(updated.selectedProject?.id, 1);
      expect(updated.isLoadingProjects, true);
    });

    test('copyWith clears selectedProject', () {
      final original = ViolationReportState(
        selectedProject: ViolationProject(id: 1, name: 'Project A'),
      );

      final cleared = original.copyWith(clearSelectedProject: true);

      expect(cleared.selectedProject, isNull);
    });

    test('copyWith clears employees when clearEmployees is true', () {
      final original = ViolationReportState(
        employees: [ViolationEmployee(id: 1, name: 'John', code: 'EMP001')],
      );

      final cleared = original.copyWith(clearEmployees: true);

      expect(cleared.employees, isEmpty);
    });

    test('copyWith preserves projects when clearEmployees is true', () {
      final original = ViolationReportState(
        projects: [ViolationProject(id: 1, name: 'Project A')],
        employees: [ViolationEmployee(id: 1, name: 'John', code: 'EMP001')],
      );

      final updated = original.copyWith(clearEmployees: true);

      expect(updated.projects.length, 1);
      expect(updated.employees, isEmpty);
    });

    test('copyWith clears errors correctly', () {
      final withError = ViolationReportState(
        projectsError: 'Error loading projects',
        employeesError: 'Error loading employees',
        typesError: 'Error loading types',
        submitError: 'Submit error',
        timeValidationError: 'Time error',
      );

      final cleared = withError.copyWith(
        clearProjectsError: true,
        clearEmployeesError: true,
        clearTypesError: true,
        clearSubmitError: true,
        clearTimeError: true,
      );

      expect(cleared.projectsError, isNull);
      expect(cleared.employeesError, isNull);
      expect(cleared.typesError, isNull);
      expect(cleared.submitError, isNull);
      expect(cleared.timeValidationError, isNull);
    });

    test('copyWith clears photos', () {
      final original = ViolationReportState(
        photos: [XFile('/path/to/photo.jpg')],
      );

      final cleared = original.copyWith(clearPhotos: true);

      expect(cleared.photos, isEmpty);
    });

    test('copyWith clears location', () {
      final location = LocationData(
        latitude: -6.1754,
        longitude: 106.8650,
        timestamp: DateTime.now(),
      );

      final original = ViolationReportState(location: location);
      final cleared = original.copyWith(clearLocation: true);

      expect(cleared.location, isNull);
    });
  });
}

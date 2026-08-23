import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_86/features/violation_report/domain/domain.dart';

void main() {
  group('ViolationType', () {
    test('fromJson parses category with children', () {
      final json = {
        'id': 1,
        'name': 'Performance',
        'severity_level': 'medium',
        'children': [
          {'id': 2, 'name': 'Seragam', 'severity_level': 'low', 'children': []},
        {'id': 3, 'name': 'Rambut', 'severity_level': 'low', 'children': []},
        ],
      };

      final type = ViolationType.fromJson(json);

      expect(type.id, 1);
      expect(type.name, 'Performance');
      expect(type.severityLevel, 'medium');
      expect(type.children.length, 2);
      expect(type.isCategory, true);
      expect(type.isLeaf, false);
    });

    test('fromJson parses leaf type', () {
      final json = {
        'id': 5,
        'name': 'Tidak Lengkap',
        'severity_level': 'low',
        'children': null,
      };

      final type = ViolationType.fromJson(json);

      expect(type.id, 5);
      expect(type.name, 'Tidak Lengkap');
      expect(type.children, isEmpty);
      expect(type.isLeaf, true);
      expect(type.isCategory, false);
    });

    test('fromJson handles missing severity_level with default', () {
      final json = {
        'id': 1,
        'name': 'Test',
      };

      final type = ViolationType.fromJson(json);

      expect(type.severityLevel, 'medium');
    });

    test('equality works correctly', () {
      final type1 = ViolationType(id: 1, name: 'Test', severityLevel: 'low');
      final type2 = ViolationType(id: 1, name: 'Test', severityLevel: 'low');
      final type3 = ViolationType(id: 2, name: 'Different', severityLevel: 'low');

      expect(type1, equals(type2));
      expect(type1 == type3, false);
    });

    test('props returns correct values', () {
      final type = ViolationType(id: 1, name: 'Test', severityLevel: 'low');

      expect(type.props, [1, 'Test', 'low', []]);
    });
  });

  group('ViolationProject', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 1,
        'name': 'Project A',
        'client_name': 'Client ABC',
        'address': 'Jl. Sudirman',
        'lat': -6.1754,
        'lng': 106.8650,
        'radius_meters': 150,
      };

      final project = ViolationProject.fromJson(json);

      expect(project.id, 1);
      expect(project.name, 'Project A');
      expect(project.clientName, 'Client ABC');
      expect(project.address, 'Jl. Sudirman');
      expect(project.lat, -6.1754);
      expect(project.lng, 106.8650);
      expect(project.radiusMeters, 150);
    });

    test('fromJson handles null fields', () {
      final json = {
        'id': 1,
        'name': 'Project A',
      };

      final project = ViolationProject.fromJson(json);

      expect(project.clientName, isNull);
      expect(project.address, isNull);
      expect(project.lat, isNull);
      expect(project.lng, isNull);
      expect(project.radiusMeters, isNull);
    });

    test('fromJson converts num to double', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'lat': -6.1754,
        'lng': 106.8650,
      };

      final project = ViolationProject.fromJson(json);

      expect(project.lat, isA<double>());
      expect(project.lng, isA<double>());
    });

    test('equality works correctly', () {
      final p1 = ViolationProject(id: 1, name: 'Project A');
      final p2 = ViolationProject(id: 1, name: 'Project A');
      final p3 = ViolationProject(id: 2, name: 'Project B');

      expect(p1, equals(p2));
      expect(p1 == p3, false);
    });
  });

  group('ViolationEmployee', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 1,
        'name': 'John Doe',
        'code': 'EMP001',
      };

      final employee = ViolationEmployee.fromJson(json);

      expect(employee.id, 1);
      expect(employee.name, 'John Doe');
      expect(employee.code, 'EMP001');
    });

    test('equality works correctly', () {
      final e1 = ViolationEmployee(id: 1, name: 'John', code: 'EMP001');
      final e2 = ViolationEmployee(id: 1, name: 'John', code: 'EMP001');
      final e3 = ViolationEmployee(id: 2, name: 'Jane', code: 'EMP002');

      expect(e1, equals(e2));
      expect(e1 == e3, false);
    });
  });

  group('ViolationReportResult', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 1,
        'project_id': 10,
        'violation_type_id': 5,
        'captured_at': '2024-01-01T10:00:00Z',
        'status': 'pending',
        'photo_count': 2,
      };

      final result = ViolationReportResult.fromJson(json);

      expect(result.id, 1);
      expect(result.projectId, 10);
      expect(result.violationTypeId, 5);
      expect(result.capturedAt, '2024-01-01T10:00:00Z');
      expect(result.status, 'pending');
      expect(result.photoCount, 2);
    });

    test('fromJson handles missing photo_count', () {
      final json = {
        'id': 1,
        'project_id': 1,
        'violation_type_id': 1,
        'captured_at': '2024-01-01',
        'status': 'pending',
      };

      final result = ViolationReportResult.fromJson(json);

      expect(result.photoCount, 0);
    });

    test('equality works correctly', () {
      final r1 = ViolationReportResult(
        id: 1,
        projectId: 1,
        violationTypeId: 1,
        capturedAt: '2024-01-01',
        status: 'pending',
        photoCount: 0,
      );
      final r2 = ViolationReportResult(
        id: 1,
        projectId: 1,
        violationTypeId: 1,
        capturedAt: '2024-01-01',
        status: 'pending',
        photoCount: 0,
      );

      expect(r1, equals(r2));
    });
  });
}

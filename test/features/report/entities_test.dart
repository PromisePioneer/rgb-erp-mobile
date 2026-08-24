import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_86/features/report/domain/domain.dart';

void main() {
  group('Report', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '1',
        'date': '2024-01-15',
        'time': '10:30',
        'location': 'Area A, Lobby',
        'description': 'Security check completed',
        'image': 'https://example.com/image.jpg',
        'employee_id': 5,
        'employee_name': 'John Doe',
      };

      final report = Report.fromJson(json);

      expect(report.id, '1');
      expect(report.date, '2024-01-15');
      expect(report.time, '10:30');
      expect(report.location, 'Area A, Lobby');
      expect(report.description, 'Security check completed');
      expect(report.image, 'https://example.com/image.jpg');
      expect(report.employeeId, 5);
      expect(report.employeeName, 'John Doe');
    });

    test('fromJson handles null fields', () {
      final json = {
        'id': '2',
        'date': '2024-01-15',
        'time': '10:30',
        'location': 'Area B',
        'description': 'Another report',
      };

      final report = Report.fromJson(json);

      expect(report.image, isNull);
      expect(report.employeeId, 0);
      expect(report.employeeName, isNull);
    });

    test('fromJson handles numeric id', () {
      final json = {
        'id': 123,
        'date': '2024-01-15',
        'time': '10:30',
        'location': 'Area C',
        'description': 'Report with numeric id',
      };

      final report = Report.fromJson(json);

      expect(report.id, '123');
    });

    test('fromJson handles numeric employee_id', () {
      final json = {
        'id': '1',
        'date': '2024-01-15',
        'time': '10:30',
        'location': 'Area D',
        'description': 'Report',
        'employee_id': 42.0, // JSON numbers can be double
      };

      final report = Report.fromJson(json);

      expect(report.employeeId, 42);
    });

    test('fromJson handles missing required fields with defaults', () {
      final json = <String, dynamic>{};

      final report = Report.fromJson(json);

      expect(report.id, '');
      expect(report.date, '');
      expect(report.time, '');
      expect(report.location, '');
      expect(report.description, '');
    });

    test('equality works correctly', () {
      final r1 = Report(
        id: '1',
        date: '2024-01-15',
        time: '10:30',
        location: 'Area A',
        description: 'Test report',
      );
      final r2 = Report(
        id: '1',
        date: '2024-01-15',
        time: '10:30',
        location: 'Area A',
        description: 'Test report',
      );
      final r3 = Report(
        id: '2',
        date: '2024-01-16',
        time: '11:00',
        location: 'Area B',
        description: 'Different report',
      );

      expect(r1, equals(r2));
      expect(r1 == r3, false);
    });

    test('props returns correct values', () {
      final report = Report(
        id: '1',
        date: '2024-01-15',
        time: '10:30',
        location: 'Area A',
        description: 'Test report',
        image: 'https://example.com/image.jpg',
        employeeId: 5,
        employeeName: 'John Doe',
      );

      expect(report.props, [
        '1',
        '2024-01-15',
        '10:30',
        'Area A',
        'Test report',
        'https://example.com/image.jpg',
        5,
        'John Doe',
      ]);
    });
  });

  group('ReportArea', () {
    test('fromJson parses all fields', () {
      final json = {
        'area_name': 'PT ABC Mall',
        'count': 3,
        'reports': [
          {
            'id': '1',
            'date': '2024-01-15',
            'time': '10:30',
            'location': 'Lobby',
            'description': 'Report 1',
          },
          {
            'id': '2',
            'date': '2024-01-15',
            'time': '11:00',
            'location': 'Parkiran',
            'description': 'Report 2',
          },
          {
            'id': '3',
            'date': '2024-01-15',
            'time': '12:00',
            'location': 'Rooftop',
            'description': 'Report 3',
          },
        ],
      };

      final area = ReportArea.fromJson(json);

      expect(area.areaName, 'PT ABC Mall');
      expect(area.count, 3);
      expect(area.reports.length, 3);
      expect(area.reports[0].id, '1');
      expect(area.reports[1].id, '2');
      expect(area.reports[2].id, '3');
    });

    test('fromJson handles empty reports', () {
      final json = {
        'area_name': 'Empty Area',
        'count': 0,
        'reports': [],
      };

      final area = ReportArea.fromJson(json);

      expect(area.areaName, 'Empty Area');
      expect(area.count, 0);
      expect(area.reports, isEmpty);
    });

    test('fromJson handles null reports', () {
      final json = {
        'area_name': 'Area with null reports',
        'count': 0,
        'reports': null,
      };

      final area = ReportArea.fromJson(json);

      expect(area.areaName, 'Area with null reports');
      expect(area.reports, isEmpty);
    });

    test('fromJson handles missing reports field', () {
      final json = {
        'area_name': 'Area without reports field',
        'count': 0,
      };

      final area = ReportArea.fromJson(json);

      expect(area.areaName, 'Area without reports field');
      expect(area.reports, isEmpty);
    });

    test('fromJson handles numeric count', () {
      final json = {
        'area_name': 'Area',
        'count': 5.0, // JSON numbers can be double
        'reports': [],
      };

      final area = ReportArea.fromJson(json);

      expect(area.count, 5);
    });

    test('equality works correctly', () {
      final a1 = ReportArea(
        areaName: 'Area A',
        count: 3,
        reports: [
          Report(
            id: '1',
            date: '2024-01-15',
            time: '10:30',
            location: 'Lobby',
            description: 'Report 1',
          ),
        ],
      );
      final a2 = ReportArea(
        areaName: 'Area A',
        count: 3,
        reports: [
          Report(
            id: '1',
            date: '2024-01-15',
            time: '10:30',
            location: 'Lobby',
            description: 'Report 1',
          ),
        ],
      );
      final a3 = ReportArea(
        areaName: 'Area B',
        count: 5,
        reports: [],
      );

      expect(a1, equals(a2));
      expect(a1 == a3, false);
    });

    test('props returns correct values', () {
      final area = ReportArea(
        areaName: 'Test Area',
        count: 2,
        reports: [
          Report(
            id: '1',
            date: '2024-01-15',
            time: '10:30',
            location: 'A',
            description: 'R1',
          ),
        ],
      );

      expect(area.props.length, 3);
      expect(area.props[0], 'Test Area');
      expect(area.props[1], 2);
      expect(area.props[2], isA<List<Report>>());
    });
  });
}

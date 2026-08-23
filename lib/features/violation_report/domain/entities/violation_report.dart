import 'package:equatable/equatable.dart';

/// Project entity for violation report
class ViolationProject extends Equatable {
  final int id;
  final String name;
  final String? clientName;
  final String? address;
  final double? lat;
  final double? lng;
  final int? radiusMeters;

  const ViolationProject({
    required this.id,
    required this.name,
    this.clientName,
    this.address,
    this.lat,
    this.lng,
    this.radiusMeters,
  });

  factory ViolationProject.fromJson(Map<String, dynamic> json) {
    return ViolationProject(
      id: json['id'] as int,
      name: json['name'] as String,
      clientName: json['client_name'] as String?,
      address: json['address'] as String?,
      // Handle both String and num types for lat/lng
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      radiusMeters: _parseInt(json['radius_meters']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.isNotEmpty) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props =>
      [id, name, clientName, address, lat, lng, radiusMeters];
}

/// Employee entity for violation report
class ViolationEmployee extends Equatable {
  final int id;
  final String name;
  final String code;

  const ViolationEmployee({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ViolationEmployee.fromJson(Map<String, dynamic> json) {
    return ViolationEmployee(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name, code];
}

/// Violation photo
class ViolationPhoto extends Equatable {
  final int id;
  final String? url;

  const ViolationPhoto({
    required this.id,
    this.url,
  });

  factory ViolationPhoto.fromJson(Map<String, dynamic> json) {
    return ViolationPhoto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, url];
}

/// Violation report submission result
class ViolationReportResult extends Equatable {
  final int id;
  final int projectId;
  final String? projectName;
  final int employeeId;
  final String? employeeName;
  final int violationTypeId;
  final String? violationTypeName;
  final String capturedAt;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? action;
  final int photoCount;
  final List<ViolationPhoto> photos;

  const ViolationReportResult({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.employeeId,
    this.employeeName,
    required this.violationTypeId,
    this.violationTypeName,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.notes,
    this.action,
    required this.photoCount,
    this.photos = const [],
  });

  factory ViolationReportResult.fromJson(Map<String, dynamic> json) {
    final photosList = (json['photos'] as List<dynamic>?)
        ?.map((p) => ViolationPhoto.fromJson(p as Map<String, dynamic>))
        .toList() ?? [];

    return ViolationReportResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      projectName: json['project_name']?.toString(),
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name']?.toString(),
      violationTypeId: (json['violation_type_id'] as num?)?.toInt() ?? 0,
      violationTypeName: json['violation_type_name']?.toString(),
      capturedAt: json['captured_at']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
      action: json['action']?.toString(),
      photoCount: (json['photo_count'] as num?)?.toInt() ?? photosList.length,
      photos: photosList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        projectName,
        employeeId,
        employeeName,
        violationTypeId,
        violationTypeName,
        capturedAt,
        latitude,
        longitude,
        notes,
        action,
        photoCount,
        photos,
      ];
}

import 'package:equatable/equatable.dart';

// ====================
// Shared Parsing Helpers
// ====================

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String && value.isNotEmpty) return int.tryParse(value) ?? 0;
  return 0;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String && value.isNotEmpty) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value);
  return null;
}

String _parseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

Map<String, dynamic>? _safeToMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

// ====================
// Entities
// ====================

/// Area entity for violation report
class ViolationArea extends Equatable {
  final int id;
  final String name;
  final String? clientName;
  final String? address;
  final double? lat;
  final double? lng;
  final int? radiusMeters;

  const ViolationArea({
    required this.id,
    required this.name,
    this.clientName,
    this.address,
    this.lat,
    this.lng,
    this.radiusMeters,
  });

  factory ViolationArea.fromJson(Map<String, dynamic> json) {
    return ViolationArea(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      clientName: json['client_name']?.toString(),
      address: json['address']?.toString(),
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      radiusMeters: _parseIntNullable(json['radius_meters']),
    );
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
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
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
      id: _parseInt(json['id']),
      url: json['url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, url];
}

/// Violation report submission result
class ViolationReportResult extends Equatable {
  final int id;
  final int areaId;
  final String? areaName;
  final String? clientName;
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
    required this.areaId,
    this.areaName,
    this.clientName,
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
        ?.map((p) => ViolationPhoto.fromJson(_safeToMap(p) ?? {}))
        .toList() ?? [];

    return ViolationReportResult(
      id: _parseInt(json['id']),
      areaId: _parseInt(json['area_id']),
      areaName: json['area_name']?.toString(),
      clientName: json['client_name']?.toString(),
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      violationTypeId: _parseInt(json['violation_type_id']),
      violationTypeName: json['violation_type_name']?.toString(),
      capturedAt: json['captured_at']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      notes: json['notes']?.toString(),
      action: json['action']?.toString(),
      photoCount: _parseInt(json['photo_count']),
      photos: photosList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        areaId,
        areaName,
        clientName,
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

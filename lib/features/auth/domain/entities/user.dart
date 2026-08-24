import 'package:equatable/equatable.dart';

/// User entity from API
class User extends Equatable {
  final int id;
  final String code;
  final String name;
  final String? email;
  final String? username;
  final String? nik;
  final String? department;
  final String? position;
  final String? photo;
  final String? division; // RGB (Satpam) or RBM (Cleaning)
  final String? siteId;
  final String? siteName;
  final String? areaId;
  final String? areaName;
  final List<String> privileges;
  final bool hasFaceEnrollment;

  const User({
    required this.id,
    required this.code,
    required this.name,
    this.email,
    this.username,
    this.nik,
    this.department,
    this.position,
    this.photo,
    this.division,
    this.siteId,
    this.siteName,
    this.areaId,
    this.areaName,
    this.privileges = const [],
    this.hasFaceEnrollment = false,
  });

  /// Check if user is RGB (Satpam/Security)
  bool get isRgb => division?.toLowerCase() == 'rgb' || department?.toLowerCase() == 'satpam';

  /// Check if user is RBM (Non-Satpam/Cleaning)
  bool get isRbm => division?.toLowerCase() == 'rbm' || department?.toLowerCase() == 'cleaning';

  /// Check if user is Super Admin
  bool get isSuperAdmin => position?.toLowerCase() == 'super admin';

  /// Check if user has a specific privilege
  bool hasPrivilege(String key) => privileges.contains(key);

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      nik: json['nik'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      photo: json['photo'] as String?,
      division: json['division'] as String?,
      siteId: json['site_id'] as String?,
      siteName: json['site_name'] as String?,
      areaId: json['area_id'] as String?,
      areaName: json['area_name'] as String?,
      privileges: (json['privileges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hasFaceEnrollment: json['has_face_enrollment'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'email': email,
      'username': username,
      'nik': nik,
      'department': department,
      'position': position,
      'photo': photo,
      'division': division,
      'site_id': siteId,
      'site_name': siteName,
      'area_id': areaId,
      'area_name': areaName,
      'privileges': privileges,
      'has_face_enrollment': hasFaceEnrollment,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        email,
        username,
        nik,
        department,
        position,
        photo,
        division,
        siteId,
        siteName,
        areaId,
        areaName,
        privileges,
        hasFaceEnrollment,
      ];
}

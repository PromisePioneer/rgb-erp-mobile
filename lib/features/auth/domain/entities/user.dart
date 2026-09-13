import 'package:equatable/equatable.dart';

/// User entity from API
class User extends Equatable {
  final int id;
  final String? code; // nullable - clients don't have code
  final String name;
  final String? email;
  final String? username;
  final String? nik;
  final String? department;
  final String? role;
  final String? photo;
  final String? division; // RGB (Satpam) or RBM (Crew)
  final String? siteId;
  final String? siteName;
  final String? areaId;
  final String? areaName;
  final List<String> privileges;
  final bool hasFaceEnrollment;
  final bool forcePasswordChange; // Must change password on first login

  const User({
    required this.id,
    this.code, // nullable - only employees have code
    required this.name,
    this.email,
    this.username,
    this.nik,
    this.department,
    this.role,
    this.photo,
    this.division,
    this.siteId,
    this.siteName,
    this.areaId,
    this.areaName,
    this.privileges = const [],
    this.hasFaceEnrollment = false,
    this.forcePasswordChange = false,
  });

  /// Check if user is RGB (Satpam/Security)
  bool get isRgb => division?.toLowerCase() == 'rgb' || department?.toLowerCase() == 'satpam';

  /// Check if user is RBM (Non-Satpam/Crew)
  bool get isRbm => division?.toLowerCase() == 'rbm' || department?.toLowerCase() == 'crew';

  /// Check if user is Super Admin
  bool get isSuperAdmin => role?.toLowerCase() == 'super admin';

  /// Check if user is Team Leader (can assign tasks)
  bool get isTeamLeader => role?.toLowerCase() == 'team leader';

  /// Check if user has a specific privilege
  bool hasPrivilege(String key) => privileges.contains(key);

  /// Copy with method for immutable updates
  User copyWith({
    int? id,
    String? code,
    String? name,
    String? email,
    String? username,
    String? nik,
    String? department,
    String? role,
    String? photo,
    String? division,
    String? siteId,
    String? siteName,
    String? areaId,
    String? areaName,
    List<String>? privileges,
    bool? hasFaceEnrollment,
    bool? forcePasswordChange,
  }) {
    return User(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      nik: nik ?? this.nik,
      department: department ?? this.department,
      role: role ?? this.role,
      photo: photo ?? this.photo,
      division: division ?? this.division,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      privileges: privileges ?? this.privileges,
      hasFaceEnrollment: hasFaceEnrollment ?? this.hasFaceEnrollment,
      forcePasswordChange: forcePasswordChange ?? this.forcePasswordChange,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      code: json['code'] as String?, // nullable - only employees have code
      name: json['name'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      nik: json['nik'] as String?,
      department: json['department'] as String?,
      role: json['role'] as String?,
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
      forcePasswordChange: json['force_password_change'] == true,
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
      'role': role,
      'photo': photo,
      'division': division,
      'site_id': siteId,
      'site_name': siteName,
      'area_id': areaId,
      'area_name': areaName,
      'privileges': privileges,
      'has_face_enrollment': hasFaceEnrollment,
      'force_password_change': forcePasswordChange,
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
        role,
        photo,
        division,
        siteId,
        siteName,
        areaId,
        areaName,
        privileges,
        hasFaceEnrollment,
        forcePasswordChange,
      ];
}

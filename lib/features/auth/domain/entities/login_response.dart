import 'package:equatable/equatable.dart';
import 'user.dart';

/// Login response from API
class LoginResponse extends Equatable {
  final String userType; // 'employee' or 'client'
  final User? user; // For employee
  final String accessToken;
  final String tokenType;

  const LoginResponse({
    required this.userType,
    this.user,
    required this.accessToken,
    this.tokenType = 'Bearer',
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userType = json['user_type'] as String? ?? 'user';
    final accessToken = json['access_token'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Invalid login response: missing access token');
    }

    // Handle employee/user login (API returns "user" type for employees)
    if ((userType == 'employee' || userType == 'user') && json['employee'] != null) {
      // Merge employee data with user data to get privileges
      final userData = json['user'] as Map<String, dynamic>?;
      final employeeData = json['employee'] as Map<String, dynamic>;

      // Create merged user data with privileges from user field
      final mergedUserData = <String, dynamic>{
        ...employeeData,
        if (userData != null) ...userData,
        // Ensure privileges come from user field, not employee
        'privileges': userData?['privileges'] ?? [],
      };

      return LoginResponse(
        userType: 'employee',
        user: User.fromJson(mergedUserData),
        accessToken: accessToken,
        tokenType: json['token_type'] as String? ?? 'Bearer',
      );
    }

    // Also handle case where user data is in "user" field directly (no employee)
    if ((userType == 'employee' || userType == 'user') && json['user'] != null && json['employee'] == null) {
      return LoginResponse(
        userType: 'employee',
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: accessToken,
        tokenType: json['token_type'] as String? ?? 'Bearer',
      );
    }

    // Handle client login
    if (userType == 'client' && json['client'] != null) {
      final clientData = json['client'] as Map<String, dynamic>;
      // Create a pseudo-user for client with limited info
      return LoginResponse(
        userType: 'client',
        user: User.fromJson({
          'id': clientData['id'] ?? 0,
          'code': null,
          'name': clientData['name'] ?? '',
          'email': clientData['email'] ?? '',
          'username': null,
          'nik': null,
          'department': null,
          'role': 'Client',
          'photo': null,
          'division': null,
          'siteId': null,
          'siteName': null,
          'areaId': null,
          'areaName': null,
          'privileges': <String>[],
          'hasFaceEnrollment': false,
        }),
        accessToken: accessToken,
        tokenType: json['token_type'] as String? ?? 'Bearer',
      );
    }

    // Fallback
    throw Exception('Invalid login response: missing user data');
  }

  bool get isClient => userType == 'client';
  bool get isEmployee => userType == 'employee';

  @override
  List<Object?> get props => [userType, user, accessToken, tokenType];
}

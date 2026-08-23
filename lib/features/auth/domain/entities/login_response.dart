import 'package:equatable/equatable.dart';
import 'user.dart';

/// Login response from API
class LoginResponse extends Equatable {
  final User user;
  final String accessToken;
  final String tokenType;

  const LoginResponse({
    required this.user,
    required this.accessToken,
    this.tokenType = 'Bearer',
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['employee'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  @override
  List<Object?> get props => [user, accessToken, tokenType];
}

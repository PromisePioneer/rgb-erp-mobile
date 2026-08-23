import 'package:equatable/equatable.dart';

/// Login credentials input
class LoginCredentials extends Equatable {
  final String code;
  final String password;
  final String? fcmToken;

  const LoginCredentials({
    required this.code,
    required this.password,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'password': password,
      if (fcmToken != null) 'fcm_token': fcmToken,
    };
  }

  @override
  List<Object?> get props => [code, password, fcmToken];
}

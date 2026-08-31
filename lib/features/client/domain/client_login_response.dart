import 'client_user.dart';

/// Login response for client authentication
class ClientLoginResponse {
  final String userType;
  final ClientUser? client;
  final String accessToken;
  final String tokenType;

  const ClientLoginResponse({
    required this.userType,
    this.client,
    required this.accessToken,
    required this.tokenType,
  });

  factory ClientLoginResponse.fromJson(Map<String, dynamic> json) {
    final clientData = json['client'] as Map<String, dynamic>?;
    return ClientLoginResponse(
      userType: json['user_type'] as String? ?? 'unknown',
      client: clientData != null ? ClientUser.fromJson(clientData) : null,
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  bool get isClient => userType == 'client';
}

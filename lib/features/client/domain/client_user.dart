/// Client user entity for mobile app
class ClientUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? companyName;
  final bool canLoginMobile;
  final String? token;

  const ClientUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.companyName,
    this.canLoginMobile = true,
    this.token,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) {
    return ClientUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      companyName: json['company_name'] as String?,
      canLoginMobile: json['can_login_mobile'] as bool? ?? true,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company_name': companyName,
      'can_login_mobile': canLoginMobile,
      if (token != null) 'token': token,
    };
  }

  ClientUser copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? companyName,
    bool? canLoginMobile,
    String? token,
  }) {
    return ClientUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      canLoginMobile: canLoginMobile ?? this.canLoginMobile,
      token: token ?? this.token,
    );
  }
}

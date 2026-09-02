import 'package:equatable/equatable.dart';

/// Response from GET /patrol/otp
class PatrolOtpResponse extends Equatable {
  final String? otpCode;
  final DateTime? otpExpiresAt;
  final bool hasOtp;

  const PatrolOtpResponse({
    this.otpCode,
    this.otpExpiresAt,
    this.hasOtp = false,
  });

  factory PatrolOtpResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PatrolOtpResponse(
      otpCode: json['otp_code']?.toString(),
      otpExpiresAt: parseDateTime(json['otp_expires_at']),
      hasOtp: json['has_otp'] == true || json['has_otp'] == 'true',
    );
  }

  /// Get seconds until OTP expires (negative if expired)
  int get secondsUntilExpiry {
    if (otpExpiresAt == null) return 0;
    return otpExpiresAt!.difference(DateTime.now()).inSeconds;
  }

  /// Check if OTP is expired
  bool get isExpired {
    if (otpExpiresAt == null) return true;
    return DateTime.now().isAfter(otpExpiresAt!);
  }

  @override
  List<Object?> get props => [otpCode, otpExpiresAt, hasOtp];
}

import 'package:equatable/equatable.dart';

/// Response from GET /patrol/otp - checkpoint TOTP info
class PatrolOtpResponse extends Equatable {
  /// Whether this checkpoint requires TOTP
  final bool hasTotp;

  /// Checkpoint name (from QR scan)
  final String? checkpointName;

  /// Checkpoint code (from QR scan)
  final String? checkpointCode;

  /// Has schedule for today
  final bool hasSchedule;

  /// Area name
  final String? areaName;

  /// Error message if any
  final String? message;

  const PatrolOtpResponse({
    this.hasTotp = false,
    this.checkpointName,
    this.checkpointCode,
    this.hasSchedule = false,
    this.areaName,
    this.message,
  });

  factory PatrolOtpResponse.fromJson(Map<String, dynamic> json) {
    return PatrolOtpResponse(
      hasTotp: json['has_totp'] == true || json['has_totp'] == 'true',
      checkpointName: json['checkpoint_name']?.toString(),
      checkpointCode: json['checkpoint_code']?.toString(),
      hasSchedule: json['has_schedule'] == true || json['has_schedule'] == 'true',
      areaName: json['area_name']?.toString(),
      message: json['message']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        hasTotp,
        checkpointName,
        checkpointCode,
        hasSchedule,
        areaName,
        message,
      ];
}

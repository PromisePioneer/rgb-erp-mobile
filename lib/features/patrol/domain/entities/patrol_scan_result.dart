import 'package:equatable/equatable.dart';

/// Patrol scan result from POST /patrol/scan
class PatrolScanResult extends Equatable {
  final bool success;
  final bool valid;
  final int? scanId;
  final CheckpointInfo? checkpoint;
  final ProgressInfo? progress;
  final ValidationInfo? validation;
  final int? minGapSeconds;
  final DateTime? nextScanAllowedAt;
  final String? roundStatus;
  final int? processingTimeMs;
  final String? errorCode;
  final String? errorMessage;
  final int? minGapRemainingSeconds;

  const PatrolScanResult({
    required this.success,
    this.valid = false,
    this.scanId,
    this.checkpoint,
    this.progress,
    this.validation,
    this.minGapSeconds,
    this.nextScanAllowedAt,
    this.roundStatus,
    this.processingTimeMs,
    this.errorCode,
    this.errorMessage,
    this.minGapRemainingSeconds,
  });

  bool get isValidWarning => success && !valid;
  bool get isRoundCompleted => roundStatus == 'completed';

  factory PatrolScanResult.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PatrolScanResult(
      success: json['success'] as bool? ?? false,
      valid: json['valid'] as bool? ?? false,
      scanId: json['scan_id'] is int ? json['scan_id'] : int.tryParse(json['scan_id']?.toString() ?? ''),
      checkpoint: json['checkpoint'] != null
          ? CheckpointInfo.fromJson(json['checkpoint'] as Map<String, dynamic>)
          : null,
      progress: json['progress'] != null
          ? ProgressInfo.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      validation: json['validation'] != null
          ? ValidationInfo.fromJson(json['validation'] as Map<String, dynamic>)
          : null,
      minGapSeconds: json['min_gap_seconds'] is int
          ? json['min_gap_seconds']
          : int.tryParse(json['min_gap_seconds']?.toString() ?? ''),
      nextScanAllowedAt: parseDateTime(json['next_scan_allowed_at']),
      roundStatus: json['round_status']?.toString(),
      processingTimeMs: json['processing_time_ms'] is int
          ? json['processing_time_ms']
          : int.tryParse(json['processing_time_ms']?.toString() ?? ''),
      errorCode: json['code']?.toString(),
      errorMessage: json['message']?.toString(),
      minGapRemainingSeconds: json['min_gap_remaining_seconds'] is int
          ? json['min_gap_remaining_seconds']
          : int.tryParse(json['min_gap_remaining_seconds']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [
        success,
        valid,
        scanId,
        checkpoint,
        progress,
        validation,
        minGapSeconds,
        nextScanAllowedAt,
        roundStatus,
        processingTimeMs,
        errorCode,
        errorMessage,
        minGapRemainingSeconds,
      ];
}

class CheckpointInfo extends Equatable {
  final int id;
  final String name;
  final int sequenceOrder;

  const CheckpointInfo({
    required this.id,
    required this.name,
    required this.sequenceOrder,
  });

  factory CheckpointInfo.fromJson(Map<String, dynamic> json) {
    return CheckpointInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sequenceOrder: json['sequence_order'] is int
          ? json['sequence_order']
          : int.tryParse(json['sequence_order']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, sequenceOrder];
}

class ProgressInfo extends Equatable {
  final int current;
  final int total;
  final String label;

  const ProgressInfo({
    required this.current,
    required this.total,
    required this.label,
  });

  factory ProgressInfo.fromJson(Map<String, dynamic> json) {
    return ProgressInfo(
      current: json['current'] is int ? json['current'] : int.tryParse(json['current']?.toString() ?? '0') ?? 0,
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      label: json['label']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [current, total, label];
}

class ValidationInfo extends Equatable {
  final bool locationValid;
  final String? locationMessage;
  final double? distanceMeters;

  const ValidationInfo({
    required this.locationValid,
    this.locationMessage,
    this.distanceMeters,
  });

  factory ValidationInfo.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ValidationInfo(
      locationValid: json['location_valid'] as bool? ?? false,
      locationMessage: json['location_message']?.toString(),
      distanceMeters: parseDouble(json['distance_meters']),
    );
  }

  @override
  List<Object?> get props => [locationValid, locationMessage, distanceMeters];
}

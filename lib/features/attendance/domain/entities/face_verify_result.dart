import 'package:equatable/equatable.dart';

/// Face verification result from POST /attendance/face-verify
class FaceVerifyResult extends Equatable {
  final bool success;
  final bool match;
  final double? score;
  final String? jobId;
  final String? status; // 'queued' | 'already_processed'
  final String message;
  final int? attendanceId;

  const FaceVerifyResult({
    required this.success,
    required this.match,
    this.score,
    this.jobId,
    this.status,
    required this.message,
    this.attendanceId,
  });

  bool get isQueued => status == 'queued';
  bool get isAlreadyProcessed => status == 'already_processed';

  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) {
    return FaceVerifyResult(
      success: json['success'] as bool? ?? false,
      match: json['match'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble(),
      jobId: json['job_id'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String? ?? '',
      attendanceId: json['attendance_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        success,
        match,
        score,
        jobId,
        status,
        message,
        attendanceId,
      ];
}

/// Attendance job status from GET /attendance/status/{jobUuid}
enum AttendanceJobStatus {
  processing,
  completed,
  failed;

  static AttendanceJobStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return AttendanceJobStatus.completed;
      case 'failed':
        return AttendanceJobStatus.failed;
      default:
        return AttendanceJobStatus.processing;
    }
  }
}

class AttendanceJobStatusResult extends Equatable {
  final AttendanceJobStatus status;
  final int? attendanceId;
  final String? type;
  final DateTime? recordedAt;
  final String message;

  const AttendanceJobStatusResult({
    required this.status,
    this.attendanceId,
    this.type,
    this.recordedAt,
    required this.message,
  });

  bool get isCompleted => status == AttendanceJobStatus.completed;
  bool get isFailed => status == AttendanceJobStatus.failed;
  bool get isProcessing => status == AttendanceJobStatus.processing;

  factory AttendanceJobStatusResult.fromJson(Map<String, dynamic> json) {
    
    final statusStr = json['status'] as String? ?? 'processing';
    
    final status = AttendanceJobStatus.fromString(statusStr);
    
    return AttendanceJobStatusResult(
      status: status,
      attendanceId: json['attendance_id'] as int?,
      type: json['type'] as String?,
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : null,
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        status,
        attendanceId,
        type,
        recordedAt,
        message,
      ];
}

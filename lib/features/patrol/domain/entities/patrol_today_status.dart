import 'package:equatable/equatable.dart';

/// Patrol today's status from GET /patrol/today-status
class PatrolTodayStatus extends Equatable {
  final bool hasSchedule;
  final ScheduleInfo? schedule;
  final StatsInfo? stats;
  final CurrentProgressInfo? currentProgress;
  final List<PatrolSession> sessions;

  const PatrolTodayStatus({
    required this.hasSchedule,
    this.schedule,
    this.stats,
    this.currentProgress,
    this.sessions = const [],
  });

  factory PatrolTodayStatus.fromJson(Map<String, dynamic> json) {
    return PatrolTodayStatus(
      hasSchedule: json['has_schedule'] as bool? ?? false,
      schedule: json['schedule'] != null
          ? ScheduleInfo.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? StatsInfo.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      currentProgress: json['current_progress'] != null
          ? CurrentProgressInfo.fromJson(json['current_progress'] as Map<String, dynamic>)
          : null,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => PatrolSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get totalCheckpoints => stats?.totalCheckpoints ?? 0;
  int get completedRounds => stats?.completedRounds ?? 0;
  int get inProgressRounds => stats?.inProgressRounds ?? 0;
  int get nextExpectedSequence => currentProgress?.nextExpectedSequence ?? 1;

  @override
  List<Object?> get props => [
        hasSchedule,
        schedule,
        stats,
        currentProgress,
        sessions,
      ];
}

class ScheduleInfo extends Equatable {
  final int projectId;
  final String projectName;
  final int shiftId;
  final String shiftName;
  final String shiftStartTime;
  final String shiftEndTime;

  const ScheduleInfo({
    required this.projectId,
    required this.projectName,
    required this.shiftId,
    required this.shiftName,
    required this.shiftStartTime,
    required this.shiftEndTime,
  });

  factory ScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleInfo(
      projectId: json['project_id'] is int
          ? json['project_id']
          : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      projectName: json['project_name']?.toString() ?? '',
      shiftId: json['shift_id'] is int
          ? json['shift_id']
          : int.tryParse(json['shift_id']?.toString() ?? '0') ?? 0,
      shiftName: json['shift_name']?.toString() ?? '',
      shiftStartTime: json['shift_start_time']?.toString() ?? '',
      shiftEndTime: json['shift_end_time']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        projectId,
        projectName,
        shiftId,
        shiftName,
        shiftStartTime,
        shiftEndTime,
      ];
}

class StatsInfo extends Equatable {
  final int totalCheckpoints;
  final int completedRounds;
  final int inProgressRounds;

  const StatsInfo({
    required this.totalCheckpoints,
    required this.completedRounds,
    required this.inProgressRounds,
  });

  factory StatsInfo.fromJson(Map<String, dynamic> json) {
    return StatsInfo(
      totalCheckpoints: json['total_checkpoints'] is int
          ? json['total_checkpoints']
          : int.tryParse(json['total_checkpoints']?.toString() ?? '0') ?? 0,
      completedRounds: json['completed_rounds'] is int
          ? json['completed_rounds']
          : int.tryParse(json['completed_rounds']?.toString() ?? '0') ?? 0,
      inProgressRounds: json['in_progress_rounds'] is int
          ? json['in_progress_rounds']
          : int.tryParse(json['in_progress_rounds']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalCheckpoints, completedRounds, inProgressRounds];
}

class CurrentProgressInfo extends Equatable {
  final int nextExpectedSequence;
  final int? inProgressSessionId;
  final int intervalMinutes;
  final DateTime? currentRoundDueAt;
  final bool currentRoundIsOverdue;

  const CurrentProgressInfo({
    required this.nextExpectedSequence,
    this.inProgressSessionId,
    this.intervalMinutes = 60,
    this.currentRoundDueAt,
    this.currentRoundIsOverdue = false,
  });

  factory CurrentProgressInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CurrentProgressInfo(
      nextExpectedSequence: json['next_expected_sequence'] is int
          ? json['next_expected_sequence']
          : int.tryParse(json['next_expected_sequence']?.toString() ?? '0') ?? 0,
      inProgressSessionId: json['in_progress_session_id'] is int
          ? json['in_progress_session_id']
          : int.tryParse(json['in_progress_session_id']?.toString() ?? ''),
      intervalMinutes: json['interval_minutes'] is int
          ? json['interval_minutes']
          : int.tryParse(json['interval_minutes']?.toString() ?? '60') ?? 60,
      currentRoundDueAt: parseDateTime(json['current_round_due_at']),
      currentRoundIsOverdue: json['current_round_is_overdue'] == true ||
          json['current_round_is_overdue'] == 'true',
    );
  }

  /// Get time remaining until next round in minutes (negative if overdue)
  int get minutesUntilDue {
    if (currentRoundDueAt == null) return intervalMinutes;
    final diff = currentRoundDueAt!.difference(DateTime.now());
    return diff.inMinutes;
  }

  /// Get human-readable countdown text
  String get countdownText {
    if (currentRoundIsOverdue) {
      return 'Ronde terlambat!';
    }
    if (currentRoundDueAt == null) {
      return 'Ronde berikutnya: $intervalMinutes menit lagi';
    }
    final minutes = minutesUntilDue;
    if (minutes <= 0) {
      return 'Ronde akan dimulai';
    } else if (minutes < 60) {
      return 'Ronde berikutnya: $minutes menit lagi';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return 'Ronde berikutnya: $hours jam $mins menit lagi';
      }
      return 'Ronde berikutnya: $hours jam lagi';
    }
  }

  @override
  List<Object?> get props => [
        nextExpectedSequence,
        inProgressSessionId,
        intervalMinutes,
        currentRoundDueAt,
        currentRoundIsOverdue,
      ];
}

class PatrolSession extends Equatable {
  final int id;
  final int roundNumber;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int scansCount;

  const PatrolSession({
    required this.id,
    required this.roundNumber,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.scansCount,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  factory PatrolSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PatrolSession(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      roundNumber: json['round_number'] is int
          ? json['round_number']
          : int.tryParse(json['round_number']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      startedAt: parseDateTime(json['started_at']),
      completedAt: parseDateTime(json['completed_at']),
      scansCount: json['scans_count'] is int
          ? json['scans_count']
          : int.tryParse(json['scans_count']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, roundNumber, status, startedAt, completedAt, scansCount];
}

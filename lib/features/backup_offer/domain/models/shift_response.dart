/// Pending shift response model
class PendingShiftResponse {
  final String id;
  final String date;
  final String? areaName;
  final String? posName;
  final String? shiftName;
  final String shiftStartTime;

  PendingShiftResponse({
    required this.id,
    required this.date,
    this.areaName,
    this.posName,
    this.shiftName,
    required this.shiftStartTime,
  });

  factory PendingShiftResponse.fromJson(Map<String, dynamic> json) {
    return PendingShiftResponse(
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      areaName: json['areaName'],
      posName: json['posName'],
      shiftName: json['shiftName'],
      shiftStartTime: json['shiftStartTime'] ?? '08:00',
    );
  }
}

/// Pending shifts list response
class PendingShiftResponseList {
  final List<PendingShiftResponse> pending;
  final int count;

  PendingShiftResponseList({
    required this.pending,
    required this.count,
  });

  factory PendingShiftResponseList.fromJson(Map<String, dynamic> json) {
    return PendingShiftResponseList(
      pending: (json['pending'] as List<dynamic>?)
              ?.map((e) => PendingShiftResponse.fromJson(e))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

/// Shift respond response
class ShiftRespondResponse {
  final bool success;
  final String message;
  final ShiftResponseData? response;
  final BackupInfo? backup;

  ShiftRespondResponse({
    required this.success,
    required this.message,
    this.response,
    this.backup,
  });

  factory ShiftRespondResponse.fromJson(Map<String, dynamic> json) {
    return ShiftRespondResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      response: json['response'] != null
          ? ShiftResponseData.fromJson(json['response'])
          : null,
      backup: json['backup'] != null ? BackupInfo.fromJson(json['backup']) : null,
    );
  }
}

/// Shift response data
class ShiftResponseData {
  final String id;
  final String status;
  final String statusLabel;

  ShiftResponseData({
    required this.id,
    required this.status,
    required this.statusLabel,
  });

  factory ShiftResponseData.fromJson(Map<String, dynamic> json) {
    return ShiftResponseData(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      statusLabel: json['statusLabel'] ?? '',
    );
  }
}

/// Backup info in respond response
class BackupInfo {
  final bool searching;
  final String? offerId;
  final String message;
  final bool escalated;

  BackupInfo({
    required this.searching,
    this.offerId,
    required this.message,
    this.escalated = false,
  });

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      searching: json['searching'] ?? false,
      offerId: json['offerId']?.toString(),
      message: json['message'] ?? '',
      escalated: json['escalated'] ?? false,
    );
  }
}

/// Backup offer model
class BackupOffer {
  final String id;
  final String scheduleId;
  final String? areaId;
  final String? areaName;
  final String? posName;
  final String date;
  final String? shiftName;
  final String status;
  final String statusLabel;
  final DateTime? offeredAt;
  final DateTime? expiresAt;
  final int remainingSeconds;

  BackupOffer({
    required this.id,
    required this.scheduleId,
    this.areaId,
    this.areaName,
    this.posName,
    required this.date,
    this.shiftName,
    required this.status,
    required this.statusLabel,
    this.offeredAt,
    this.expiresAt,
    required this.remainingSeconds,
  });

  factory BackupOffer.fromJson(Map<String, dynamic> json) {
    return BackupOffer(
      id: json['id']?.toString() ?? '',
      scheduleId: json['scheduleId']?.toString() ?? '',
      areaId: json['areaId']?.toString(),
      areaName: json['areaName'],
      posName: json['posName'],
      date: json['date'] ?? '',
      shiftName: json['shiftName'],
      status: json['status'] ?? 'pending',
      statusLabel: json['statusLabel'] ?? 'Menunggu',
      offeredAt: json['offeredAt'] != null
          ? DateTime.tryParse(json['offeredAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      remainingSeconds: json['remainingSeconds'] ?? 0,
    );
  }

  bool get isPending => status == 'pending';
  bool get isExpired => remainingSeconds <= 0;
}

/// Backup offer list response
class BackupOfferListResponse {
  final List<BackupOffer> offers;
  final int count;

  BackupOfferListResponse({
    required this.offers,
    required this.count,
  });

  factory BackupOfferListResponse.fromJson(Map<String, dynamic> json) {
    return BackupOfferListResponse(
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => BackupOffer.fromJson(e))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

/// Accept backup offer response
class AcceptBackupOfferResponse {
  final bool success;
  final String message;
  final BackupSchedule? schedule;

  AcceptBackupOfferResponse({
    required this.success,
    required this.message,
    this.schedule,
  });

  factory AcceptBackupOfferResponse.fromJson(Map<String, dynamic> json) {
    return AcceptBackupOfferResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      schedule: json['schedule'] != null
          ? BackupSchedule.fromJson(json['schedule'])
          : null,
    );
  }
}

/// Backup schedule info
class BackupSchedule {
  final String id;
  final String date;
  final String? areaName;
  final String? posName;
  final String? shiftName;
  final String type;
  final String typeLabel;

  BackupSchedule({
    required this.id,
    required this.date,
    this.areaName,
    this.posName,
    this.shiftName,
    required this.type,
    required this.typeLabel,
  });

  factory BackupSchedule.fromJson(Map<String, dynamic> json) {
    return BackupSchedule(
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      areaName: json['areaName'],
      posName: json['posName'],
      shiftName: json['shiftName'],
      type: json['type'] ?? 'backup',
      typeLabel: json['typeLabel'] ?? 'Pengganti',
    );
  }
}

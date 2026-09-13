import 'package:equatable/equatable.dart';

/// Korwil Visit entity for mobile app
class KorwilVisitEntity extends Equatable {
  final int id;
  final int companyId;
  final int clientId;
  final String? clientName;
  final String? clientAddress;
  final String? clientPhone;
  final DateTime? inTime;
  final DateTime? outTime;
  final String areaName;
  final String? position;
  final String? clientNote;
  final String? fieldFindings;
  final String? fieldAction;
  final String? solution;
  final double? latitude;
  final double? longitude;
  final int status;
  final int submissionStatus; // 0=draft, 1=submitted
  final String submissionStatusLabel;
  final bool canEdit;
  final DateTime? submittedAt;
  final int createdBy;
  final String? createdByName;
  final int? updatedBy;
  final String? updatedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<KorwilVisitPhotoEntity> photos;
  final List<KorwilVisitVideoEntity> videos;
  final int photoCount;
  final int videoCount;

  const KorwilVisitEntity({
    required this.id,
    this.companyId = 0,
    this.clientId = 0,
    this.clientName,
    this.clientAddress,
    this.clientPhone,
    this.inTime,
    this.outTime,
    this.areaName = '',
    this.position,
    this.clientNote,
    this.fieldFindings,
    this.fieldAction,
    this.solution,
    this.latitude,
    this.longitude,
    this.status = 1,
    this.submissionStatus = 0,
    this.submissionStatusLabel = 'Draft',
    this.canEdit = true,
    this.submittedAt,
    this.createdBy = 0,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
    this.createdAt,
    this.updatedAt,
    this.photos = const [],
    this.videos = const [],
    this.photoCount = 0,
    this.videoCount = 0,
  });

  bool get isDraft => submissionStatus == 0;
  bool get isSubmitted => submissionStatus == 1;

  factory KorwilVisitEntity.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    return KorwilVisitEntity(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      clientName: client?['name'] ?? json['client_name'],
      clientAddress: client?['address'],
      clientPhone: client?['phone'],
      inTime: json['in_time'] != null ? DateTime.parse(json['in_time']) : null,
      outTime: json['out_time'] != null ? DateTime.parse(json['out_time']) : null,
      areaName: json['area_name'] ?? '',
      position: json['position'],
      clientNote: json['client_note'],
      fieldFindings: json['field_findings'],
      fieldAction: json['field_action'],
      solution: json['solution'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      status: json['status'] ?? 1,
      submissionStatus: json['submission_status'] ?? 0,
      submissionStatusLabel: json['submission_status_label'] ?? 'Draft',
      canEdit: json['can_edit'] ?? true,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      createdBy: json['created_by'] ?? 0,
      createdByName: json['created_by_name'],
      updatedBy: json['updated_by'],
      updatedByName: json['updated_by_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((p) => KorwilVisitPhotoEntity.fromJson(p))
          .toList() ?? [],
      videos: (json['videos'] as List<dynamic>?)
          ?.map((v) => KorwilVisitVideoEntity.fromJson(v))
          .toList() ?? [],
      photoCount: json['photo_count'] ?? 0,
      videoCount: json['video_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'client_id': clientId,
      'in_time': inTime?.toIso8601String(),
      'out_time': outTime?.toIso8601String(),
      'area_name': areaName,
      'position': position,
      'client_note': clientNote,
      'field_findings': fieldFindings,
      'field_action': fieldAction,
      'solution': solution,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  KorwilVisitEntity copyWith({
    int? id,
    int? companyId,
    int? clientId,
    String? clientName,
    String? clientAddress,
    String? clientPhone,
    DateTime? inTime,
    DateTime? outTime,
    String? areaName,
    String? position,
    String? clientNote,
    String? fieldFindings,
    String? fieldAction,
    String? solution,
    double? latitude,
    double? longitude,
    int? status,
    int? submissionStatus,
    String? submissionStatusLabel,
    bool? canEdit,
    DateTime? submittedAt,
    int? createdBy,
    String? createdByName,
    int? updatedBy,
    String? updatedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<KorwilVisitPhotoEntity>? photos,
    List<KorwilVisitVideoEntity>? videos,
    int? photoCount,
    int? videoCount,
  }) {
    return KorwilVisitEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
      areaName: areaName ?? this.areaName,
      position: position ?? this.position,
      clientNote: clientNote ?? this.clientNote,
      fieldFindings: fieldFindings ?? this.fieldFindings,
      fieldAction: fieldAction ?? this.fieldAction,
      solution: solution ?? this.solution,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionStatusLabel: submissionStatusLabel ?? this.submissionStatusLabel,
      canEdit: canEdit ?? this.canEdit,
      submittedAt: submittedAt ?? this.submittedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      photoCount: photoCount ?? this.photoCount,
      videoCount: videoCount ?? this.videoCount,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Korwil Visit Photo entity
class KorwilVisitPhotoEntity extends Equatable {
  final int id;
  final String photo;
  final String photoUrl;
  final String? description;

  const KorwilVisitPhotoEntity({
    required this.id,
    this.photo = '',
    this.photoUrl = '',
    this.description,
  });

  factory KorwilVisitPhotoEntity.fromJson(Map<String, dynamic> json) {
    return KorwilVisitPhotoEntity(
      id: json['id'] ?? 0,
      photo: json['photo'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      description: json['description'],
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Korwil Visit Video entity
class KorwilVisitVideoEntity extends Equatable {
  final int id;
  final String video;
  final String videoUrl;
  final String? thumbnail;
  final String? thumbnailUrl;
  final int? duration;

  const KorwilVisitVideoEntity({
    required this.id,
    this.video = '',
    this.videoUrl = '',
    this.thumbnail,
    this.thumbnailUrl,
    this.duration,
  });

  factory KorwilVisitVideoEntity.fromJson(Map<String, dynamic> json) {
    return KorwilVisitVideoEntity(
      id: json['id'] ?? 0,
      video: json['video'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnail: json['thumbnail'],
      thumbnailUrl: json['thumbnail_url'],
      duration: json['duration'],
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Client option for dropdown
class ClientOption extends Equatable {
  final int id;
  final String name;
  final String? address;

  const ClientOption({
    required this.id,
    required this.name,
    this.address,
  });

  factory ClientOption.fromJson(Map<String, dynamic> json) {
    return ClientOption(
      id: json['id'],
      name: json['name'],
      address: json['address'],
    );
  }

  @override
  List<Object?> get props => [id];
}

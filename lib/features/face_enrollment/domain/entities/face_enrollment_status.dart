import 'package:equatable/equatable.dart';

/// Face enrollment status from GET /face-enrollment/status
class FaceEnrollmentStatus extends Equatable {
  final bool enrolled;
  final FaceInfo? face;

  const FaceEnrollmentStatus({
    required this.enrolled,
    this.face,
  });

  factory FaceEnrollmentStatus.notEnrolled() =>
      const FaceEnrollmentStatus(enrolled: false);

  factory FaceEnrollmentStatus.fromJson(Map<String, dynamic> json) {
    return FaceEnrollmentStatus(
      enrolled: json['enrolled'] as bool? ?? false,
      face: json['face'] != null
          ? FaceInfo.fromJson(json['face'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [enrolled, face];
}

/// Face info details
class FaceInfo extends Equatable {
  final int id;
  final int userId;
  final String? provider;
  final DateTime createdAt;
  final DateTime? enrolledAt;
  final bool isActive;
  final int photoCount;
  final String? embeddingId;

  const FaceInfo({
    required this.id,
    required this.userId,
    this.provider,
    required this.createdAt,
    this.enrolledAt,
    required this.isActive,
    required this.photoCount,
    this.embeddingId,
  });

  factory FaceInfo.fromJson(Map<String, dynamic> json) {
    return FaceInfo(
      id: json['id'] as int,
      userId: json['userId'] as int,
      provider: json['provider'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      photoCount: json['photoCount'] as int? ?? 0,
      embeddingId: json['embeddingId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        provider,
        createdAt,
        enrolledAt,
        isActive,
        photoCount,
        embeddingId,
      ];
}

/// Face enrollment result from POST /face-enrollment
class FaceEnrollmentResult extends Equatable {
  final bool success;
  final bool enrolled;
  final String message;
  final int photoCount;
  final String? embeddingId;
  final int? biznetCode;

  const FaceEnrollmentResult({
    required this.success,
    required this.enrolled,
    required this.message,
    required this.photoCount,
    this.embeddingId,
    this.biznetCode,
  });

  factory FaceEnrollmentResult.fromJson(Map<String, dynamic> json) {
    return FaceEnrollmentResult(
      success: json['success'] as bool? ?? false,
      enrolled: json['enrolled'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      photoCount: json['photoCount'] as int? ?? 0,
      embeddingId: json['embeddingId'] as String?,
      biznetCode: json['biznet_code'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        success,
        enrolled,
        message,
        photoCount,
        embeddingId,
        biznetCode,
      ];
}

/// Liveness check result from POST /liveness
class LivenessResult extends Equatable {
  final bool success;
  final bool isLive;
  final double? freqRatio;
  final double? textureScore;
  final String message;

  const LivenessResult({
    required this.success,
    required this.isLive,
    this.freqRatio,
    this.textureScore,
    required this.message,
  });

  factory LivenessResult.fromJson(Map<String, dynamic> json) {
    return LivenessResult(
      success: json['success'] as bool? ?? false,
      isLive: json['is_live'] as bool? ?? false,
      freqRatio: (json['freq_ratio'] as num?)?.toDouble(),
      textureScore: (json['texture_score'] as num?)?.toDouble(),
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        isLive,
        freqRatio,
        textureScore,
        message,
      ];
}

/// Face photo for enrollment
class FacePhoto extends Equatable {
  final int id;
  final String? url;
  final double quality;
  final bool faceDetected;
  final int faceCount;
  final DateTime? capturedAt;

  const FacePhoto({
    required this.id,
    this.url,
    required this.quality,
    required this.faceDetected,
    required this.faceCount,
    this.capturedAt,
  });

  factory FacePhoto.fromJson(Map<String, dynamic> json) {
    return FacePhoto(
      id: json['id'] as int,
      url: json['url'] as String?,
      quality: (json['quality'] as num?)?.toDouble() ?? 0.0,
      faceDetected: json['faceDetected'] as bool? ?? false,
      faceCount: json['faceCount'] as int? ?? 0,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, url, quality, faceDetected, faceCount, capturedAt];
}

/// Face enrollment detail from GET /face-enrollment
class FaceEnrollmentDetail extends Equatable {
  final int id;
  final int employeeId;
  final String? provider;
  final String? embeddingId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? enrolledAt;
  final List<FacePhoto> photos;
  final int photoCount;

  const FaceEnrollmentDetail({
    required this.id,
    required this.employeeId,
    this.provider,
    this.embeddingId,
    required this.isActive,
    required this.createdAt,
    this.enrolledAt,
    required this.photos,
    required this.photoCount,
  });

  factory FaceEnrollmentDetail.fromJson(Map<String, dynamic> json) {
    final photosList = (json['photos'] as List?) ?? [];
    return FaceEnrollmentDetail(
      id: json['id'] as int,
      employeeId: json['employeeId'] as int,
      provider: json['provider'] as String?,
      embeddingId: json['embeddingId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'] as String)
          : null,
      photos: photosList
          .map((p) => FacePhoto.fromJson(p as Map<String, dynamic>))
          .toList(),
      photoCount: json['photoCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        provider,
        embeddingId,
        isActive,
        createdAt,
        enrolledAt,
        photos,
        photoCount,
      ];
}

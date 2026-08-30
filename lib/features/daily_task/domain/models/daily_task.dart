// Daily Task entities
class DailyTask {
  final int id;
  final String itemName;
  final String? itemDescription;
  final String? areaName;
  final String status;
  final int? targetMinutes;
  final String? targetNote;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<DailyTaskPhoto> photos;
  final List<DailyTaskTool>? tools;
  final List<DailyTaskChemical>? chemicals;
  final List<DailyTaskPpe>? ppes;
  final List<DailyTaskReview>? reviews;
  final int? durationMinutes;
  final String? notes;
  final String? assignedBy;

  DailyTask({
    required this.id,
    required this.itemName,
    this.itemDescription,
    this.areaName,
    required this.status,
    this.targetMinutes,
    this.targetNote,
    this.startAt,
    this.endAt,
    this.photos = const [],
    this.tools,
    this.chemicals,
    this.ppes,
    this.reviews,
    this.durationMinutes,
    this.notes,
    this.assignedBy,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      itemName: json['item_name'] as String? ?? '',
      itemDescription: json['item_description'] as String?,
      areaName: json['area_name'] as String?,
      status: json['status'] as String? ?? 'assigned',
      targetMinutes: json['target_minutes'] as int?,
      targetNote: json['target_note'] as String?,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'] as String)
          : null,
      endAt: json['end_at'] != null
          ? DateTime.tryParse(json['end_at'] as String)
          : null,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((p) => DailyTaskPhoto.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => DailyTaskTool.fromJson(t as Map<String, dynamic>))
          .toList(),
      chemicals: (json['chemicals'] as List<dynamic>?)
          ?.map((c) => DailyTaskChemical.fromJson(c as Map<String, dynamic>))
          .toList(),
      ppes: (json['ppes'] as List<dynamic>?)
          ?.map((p) => DailyTaskPpe.fromJson(p as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((r) => DailyTaskReview.fromJson(r as Map<String, dynamic>))
          .toList(),
      durationMinutes: json['duration_minutes'] as int?,
      notes: json['notes'] as String?,
      assignedBy: json['assigned_by'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'assigned':
        return 'Ditugaskan';
      case 'in_progress':
        return 'Sedang Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'reviewed':
        return 'Direview';
      default:
        return status;
    }
  }

  bool get canStart => status == 'assigned';
  bool get canFinish => status == 'in_progress';
}

class DailyTaskPhoto {
  final int id;
  final String type;
  final String url;

  DailyTaskPhoto({
    required this.id,
    required this.type,
    required this.url,
  });

  factory DailyTaskPhoto.fromJson(Map<String, dynamic> json) {
    return DailyTaskPhoto(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type'] as String? ?? 'before',
      url: json['url'] as String? ?? '',
    );
  }
}

class DailyTaskTool {
  final int id;
  final String name;

  DailyTaskTool({required this.id, required this.name});

  factory DailyTaskTool.fromJson(Map<String, dynamic> json) {
    return DailyTaskTool(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class DailyTaskChemical {
  final int id;
  final String name;

  DailyTaskChemical({required this.id, required this.name});

  factory DailyTaskChemical.fromJson(Map<String, dynamic> json) {
    return DailyTaskChemical(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class DailyTaskPpe {
  final int id;
  final String name;

  DailyTaskPpe({required this.id, required this.name});

  factory DailyTaskPpe.fromJson(Map<String, dynamic> json) {
    return DailyTaskPpe(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class DailyTaskReview {
  final int id;
  final String? reviewerName;
  final String? notes;
  final DateTime? reviewedAt;
  final List<DailyTaskReviewScore> scores;

  DailyTaskReview({
    required this.id,
    this.reviewerName,
    this.notes,
    this.reviewedAt,
    this.scores = const [],
  });

  factory DailyTaskReview.fromJson(Map<String, dynamic> json) {
    return DailyTaskReview(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      reviewerName: json['reviewer_name'] as String?,
      notes: json['notes'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      scores: (json['scores'] as List<dynamic>?)
              ?.map((s) => DailyTaskReviewScore.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double? get averageScore {
    if (scores.isEmpty) return null;
    return scores.map((s) => s.score).reduce((a, b) => a + b) / scores.length;
  }
}

class DailyTaskReviewScore {
  final int criteriaId;
  final String? criteriaName;
  final int score;

  DailyTaskReviewScore({
    required this.criteriaId,
    this.criteriaName,
    required this.score,
  });

  factory DailyTaskReviewScore.fromJson(Map<String, dynamic> json) {
    return DailyTaskReviewScore(
      criteriaId: int.tryParse(json['criteria_id']?.toString() ?? '') ?? 0,
      criteriaName: json['criteria_name'] as String?,
      score: json['score'] as int? ?? 0,
    );
  }
}

class DailyTaskMasterItem {
  final int id;
  final String name;
  final String? description;

  DailyTaskMasterItem({
    required this.id,
    required this.name,
    this.description,
  });

  factory DailyTaskMasterItem.fromJson(Map<String, dynamic> json) {
    return DailyTaskMasterItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
